import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:chagas_predictor/models/user_profile.dart';

class AuthResult {
  final bool success;
  final UserProfile? profile;
  final String? errorMessage;

  AuthResult.success(this.profile)
      : success = true,
        errorMessage = null;

  AuthResult.failure(this.errorMessage)
      : success = false,
        profile = null;
}

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();

  factory FirebaseAuthService() => _instance;

  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  String _getDocId(String email) {
    return email.trim().toLowerCase().replaceAll('.', '_').replaceAll('@', '_at_');
  }

  /// Register user in Cloud Firestore 'users' collection & Firebase Auth
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final docId = _getDocId(cleanEmail);

    try {
      // 1. Check if user already exists in Cloud Firestore Database
      final existingDoc = await _firestore.collection('users').doc(docId).get();
      if (existingDoc.exists) {
        return AuthResult.failure(
          'An account for "$cleanEmail" is already registered in the database. Please switch to Sign In.',
        );
      }

      // 2. Register with Firebase Auth SDK if enabled
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          await user.updateDisplayName(name);
        }
      } catch (e) {
        debugPrint('Firebase Auth Register notice (continuing to Firestore): $e');
      }

      // 3. Save new user record to Cloud Firestore Database
      await _firestore.collection('users').doc(docId).set({
        'uid': docId,
        'name': name,
        'email': cleanEmail,
        'password': password, // Preserved for database credential verification
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'provider': 'Cloud Firestore Database',
      });

      final profile = UserProfile(
        name: name,
        email: cleanEmail,
        provider: 'Cloud Firestore Database',
      );

      return AuthResult.success(profile);
    } catch (e) {
      debugPrint('Firestore Register error: $e');
      return AuthResult.failure('Database connection error during registration: $e');
    }
  }

  /// Sign in user with Email & Password - Checks if email exists in DB first
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final docId = _getDocId(cleanEmail);

    // Hardcoded Admin Account check
    if (cleanEmail == 'narenkvp302@gmail.com') {
      if (password != 'narenkaviya123') {
        return AuthResult.failure('Incorrect password for Admin account narenkvp302@gmail.com.');
      }

      try {
        await _firestore.collection('users').doc(docId).set({
          'uid': docId,
          'name': 'Naren (System Admin)',
          'email': 'narenkvp302@gmail.com',
          'password': 'narenkaviya123',
          'role': 'Admin',
          'provider': 'Cloud Firestore Database',
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}

      return AuthResult.success(const UserProfile(
        name: 'Naren (System Admin)',
        email: 'narenkvp302@gmail.com',
        provider: 'Cloud Firestore Database',
      ));
    }

    // Hardcoded Doctor Account check
    if (cleanEmail == 'sathyaa7755@gmail.com') {
      if (password != 'sathya7575') {
        return AuthResult.failure('Incorrect password for Doctor account sathyaa7755@gmail.com.');
      }

      try {
        await _firestore.collection('users').doc(docId).set({
          'uid': docId,
          'name': 'Dr. Sathya',
          'email': 'sathyaa7755@gmail.com',
          'password': 'sathya7575',
          'role': 'Doctor',
          'provider': 'Cloud Firestore Database',
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}

      return AuthResult.success(const UserProfile(
        name: 'Dr. Sathya',
        email: 'sathyaa7755@gmail.com',
        provider: 'Cloud Firestore Database',
      ));
    }

    try {
      // 1. First check if email exists in Cloud Firestore Database
      final userDoc = await _firestore.collection('users').doc(docId).get();
      DocumentSnapshot<Map<String, dynamic>>? activeDoc;

      if (userDoc.exists) {
        activeDoc = userDoc;
      } else {
        // Fallback query by email field in 'users' collection
        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          activeDoc = query.docs.first;
        }
      }

      // IF EMAIL DOES NOT EXIST IN DATABASE -> TELL USER TO SIGN UP FIRST!
      if (activeDoc == null || !activeDoc.exists) {
        return AuthResult.failure(
          'The email "$cleanEmail" is NOT registered in our database. Please Sign Up first before logging in.',
        );
      }

      final data = activeDoc.data()!;
      final dbPassword = data['password'] as String?;

      if (dbPassword != null && dbPassword != password) {
        return AuthResult.failure(
          'Incorrect password for "$cleanEmail". Please check your password and try again.',
        );
      }

      // 2. Try Firebase Auth sign-in for session token
      try {
        await _auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
      } catch (e) {
        debugPrint('Firebase Auth SignIn notice: $e');
      }

      // 3. Update last login in Cloud Firestore Database
      try {
        await _firestore.collection('users').doc(activeDoc.id).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      final dbName = (data['name'] as String?) ?? cleanEmail.split('@').first;

      final profile = UserProfile(
        name: dbName.isEmpty ? cleanEmail.split('@').first : dbName,
        email: cleanEmail,
        provider: 'Cloud Firestore Database',
      );

      return AuthResult.success(profile);
    } catch (e) {
      debugPrint('Firestore SignIn error: $e');
      return AuthResult.failure(
        'The email "$cleanEmail" is NOT registered in our database. Please Sign Up first before logging in.',
      );
    }
  }

  /// Google OAuth Sign In - Verifies if account exists in DB first
  Future<AuthResult> signInWithOAuth({
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final docId = _getDocId(cleanEmail);

    try {
      final doc = await _firestore.collection('users').doc(docId).get();

      if (!doc.exists) {
        return AuthResult.failure(
          'The Google account "$cleanEmail" is NOT registered in our database. You must Sign Up first before logging in.',
        );
      }

      final data = doc.data()!;
      final dbName = (data['name'] as String?) ?? name;
      try {
        await _firestore.collection('users').doc(docId).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'photoUrl': photoUrl,
        });
      } catch (_) {}

      final profile = UserProfile(
        name: dbName.isEmpty ? name : dbName,
        email: cleanEmail,
        photoUrl: photoUrl,
        provider: 'Google OAuth',
      );

      return AuthResult.success(profile);
    } catch (e) {
      debugPrint('Firestore OAuth SignIn error: $e');
      return AuthResult.failure(
        'The Google account "$cleanEmail" is NOT registered in our database. You must Sign Up first before logging in.',
      );
    }
  }

  /// Google OAuth Sign Up - Creates new user in DB if not already registered
  Future<AuthResult> registerWithOAuth({
    required String email,
    required String name,
    required String role,
    String? photoUrl,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final docId = _getDocId(cleanEmail);

    try {
      final doc = await _firestore.collection('users').doc(docId).get();

      if (doc.exists) {
        return AuthResult.failure(
          'The Google account "$cleanEmail" is already registered in our database. Please switch to Sign In.',
        );
      }

      await _firestore.collection('users').doc(docId).set({
        'uid': docId,
        'name': name,
        'email': cleanEmail,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'provider': 'Google OAuth',
        'photoUrl': photoUrl,
      });

      final profile = UserProfile(
        name: name,
        email: cleanEmail,
        photoUrl: photoUrl,
        provider: 'Google OAuth',
      );

      return AuthResult.success(profile);
    } catch (e) {
      debugPrint('Firestore OAuth Register error: $e');
      return AuthResult.failure('Database connection error during OAuth registration: $e');
    }
  }

  /// Save Patient Details to dedicated Firestore 'patients' collection
  Future<void> savePatientDetailsToFirestore({
    required String userEmail,
    required Map<String, dynamic> detailsMap,
  }) async {
    final cleanEmail = userEmail.trim().toLowerCase();
    final docId = _getDocId(cleanEmail);

    try {
      // 1. Create document in dedicated 'patients' collection
      await _firestore.collection('patients').doc(docId).set({
        'patientId': docId,
        'userEmail': cleanEmail,
        'fullName': detailsMap['fullName'],
        'gender': detailsMap['gender'],
        'age': detailsMap['age'],
        'dateOfBirth': detailsMap['dateOfBirth'],
        'city': detailsMap['city'],
        'gmailId': detailsMap['gmailId'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Mark completed patient details in 'users' collection document
      await _firestore.collection('users').doc(docId).set({
        'hasCompletedPatientDetails': true,
        'patientDocId': docId,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore Patient Details notice: $e');
    }
  }

  /// Get patient document directly from dedicated 'patients' collection
  Future<Map<String, dynamic>?> getPatientDetailsFromFirestore(String userEmail) async {
    final cleanEmail = userEmail.trim().toLowerCase();
    final docId = _getDocId(cleanEmail);

    try {
      final doc = await _firestore.collection('patients').doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }

      final query = await _firestore
          .collection('patients')
          .where('userEmail', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }

      final gmailQuery = await _firestore
          .collection('patients')
          .where('gmailId', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (gmailQuery.docs.isNotEmpty) {
        return gmailQuery.docs.first.data();
      }
    } catch (e) {
      debugPrint('Firestore getPatientDetails error: $e');
    }
    return null;
  }

  /// Save Doctor Details to dedicated Firestore 'doctors' collection
  Future<void> saveDoctorDetailsToFirestore({
    required String doctorEmail,
    required Map<String, dynamic> doctorMap,
  }) async {
    final cleanEmail = doctorEmail.trim().toLowerCase();
    final docId = _getDocId(cleanEmail);

    try {
      // 1. Create document in dedicated 'doctors' collection
      await _firestore.collection('doctors').doc(docId).set({
        'doctorId': docId,
        'doctorEmail': cleanEmail,
        'doctorName': doctorMap['doctorName'] ?? 'Dr. Sathya',
        'doctorTitle': doctorMap['doctorTitle'] ?? 'Chief Clinical Cardiologist & Electrophysiologist',
        'hospital': doctorMap['hospital'] ?? 'National Chagas Medical & Heart Research Center',
        'medicalLicense': doctorMap['medicalLicense'] ?? 'CRM-DOC 775592',
        'doctorPhone': doctorMap['doctorPhone'] ?? '+1 (555) 757-5841',
        'specialization': doctorMap['specialization'] ?? 'Chagasic Cardiomyopathy, ECG Analysis & Electrophysiology',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Sync doctor metadata to 'users' collection document
      await _firestore.collection('users').doc(docId).set({
        'name': doctorMap['doctorName'] ?? 'Dr. Sathya',
        'role': 'Doctor',
        'doctorDocId': docId,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore Doctor Details notice: $e');
    }
  }

  /// Get doctor document directly from dedicated 'doctors' collection
  Future<Map<String, dynamic>?> getDoctorDetailsFromFirestore(String doctorEmail) async {
    final cleanEmail = doctorEmail.trim().toLowerCase();
    final docId = _getDocId(cleanEmail);

    try {
      final doc = await _firestore.collection('doctors').doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }

      final query = await _firestore
          .collection('doctors')
          .where('doctorEmail', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
    } catch (e) {
      debugPrint('Firestore getDoctorDetails error: $e');
    }
    return null;
  }

  /// Save ECG Assessment Prediction Result to Firestore 'assessments' collection
  Future<void> saveAssessmentToFirestore({
    required String userEmail,
    required Map<String, dynamic> assessmentMap,
  }) async {
    try {
      await _firestore.collection('assessments').add({
        ...assessmentMap,
        'userEmail': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore Assessment notice: $e');
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Firebase SignOut notice: $e');
    }
  }
}
