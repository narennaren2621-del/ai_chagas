import 'package:flutter/foundation.dart';
import 'package:chagas_predictor/models/user_profile.dart';
import 'package:chagas_predictor/services/auth/firebase_auth_service.dart';

class PatientService {
  static final PatientService _instance = PatientService._internal();

  factory PatientService() {
    return _instance;
  }

  PatientService._internal();

  // Storage for patient details
  final Map<String, PatientDetails> _patientDatabaseByEmail = {};
  final Map<String, UserProfile> _userProfilesByEmail = {};

  PatientDetails? _patientDetails;
  UserProfile? _userProfile;

  // Getters
  PatientDetails get patientDetails =>
      _patientDetails ??
      PatientDetails(
        fullName: _userProfile?.name ?? 'Patient User',
        gender: 'Not Specified',
        dateOfBirth: DateTime(1980, 1, 1),
        age: 44,
        city: 'Not Specified',
        gmailId: _userProfile?.email ?? '',
      );

  UserProfile get userProfile =>
      _userProfile ??
      const UserProfile(
        name: 'Patient User',
        email: 'patient@chagas.org',
        provider: 'Firebase Auth',
      );

  /// Clear memory session for a newly registered email to force fresh onboarding form
  void clearSessionForNewSignup(String email) {
    final key = email.trim().toLowerCase();
    _patientDatabaseByEmail.remove(key);
    _patientDetails = null;
    _userProfile = null;
  }

  /// Fetch existing patient details from dedicated Cloud Firestore 'patients' collection
  Future<PatientDetails?> fetchPatientDetailsFromFirestore(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    try {
      final data = await FirebaseAuthService().getPatientDetailsFromFirestore(cleanEmail);

      if (data != null) {
        final details = PatientDetails(
          fullName: (data['fullName'] as String?) ?? cleanEmail.split('@').first,
          gender: (data['gender'] as String?) ?? 'Not Specified',
          dateOfBirth: data['dateOfBirth'] != null
              ? DateTime.tryParse(data['dateOfBirth'] as String) ?? DateTime(1975, 1, 1)
              : DateTime(1975, 1, 1),
          age: (data['age'] as num?)?.toInt() ?? 45,
          city: (data['city'] as String?) ?? 'Not Specified',
          gmailId: (data['gmailId'] as String?) ?? cleanEmail,
        );

        _patientDatabaseByEmail[cleanEmail] = details;
        _patientDatabaseByEmail[details.gmailId.trim().toLowerCase()] = details;
        _patientDetails = details;
        return details;
      }
    } catch (e) {
      debugPrint('Firestore fetchPatientDetails notice: $e');
    }
    return _patientDatabaseByEmail[cleanEmail];
  }

  /// Check if patient details have already been submitted one-time for a specific email/gmail
  bool hasPatientDetails(String email) {
    final key = email.trim().toLowerCase();
    return _patientDatabaseByEmail.containsKey(key);
  }

  /// Retrieve saved patient details for an email
  PatientDetails? getPatientDetails(String email) {
    final key = email.trim().toLowerCase();
    return _patientDatabaseByEmail[key];
  }

  /// Save patient details to Cloud Firestore Database and initialize active session
  Future<void> saveAndInitializePatientDetails(UserProfile profile, PatientDetails details) async {
    _userProfile = profile;
    _patientDetails = details;

    final key = profile.email.trim().toLowerCase();
    _patientDatabaseByEmail[key] = details;
    _patientDatabaseByEmail[details.gmailId.trim().toLowerCase()] = details;
    _userProfilesByEmail[key] = profile;

    // Save to Cloud Firestore Database
    await FirebaseAuthService().savePatientDetailsToFirestore(
      userEmail: profile.email,
      detailsMap: {
        'fullName': details.fullName,
        'gender': details.gender,
        'age': details.age,
        'dateOfBirth': details.dateOfBirth.toIso8601String(),
        'city': details.city,
        'gmailId': details.gmailId,
      },
    );

    if (details.gmailId.trim().toLowerCase() != key && details.gmailId.isNotEmpty) {
      await FirebaseAuthService().savePatientDetailsToFirestore(
        userEmail: details.gmailId,
        detailsMap: {
          'fullName': details.fullName,
          'gender': details.gender,
          'age': details.age,
          'dateOfBirth': details.dateOfBirth.toIso8601String(),
          'city': details.city,
          'gmailId': details.gmailId,
        },
      );
    }
  }

  /// Initialize and activate session data for user profile & patient details
  void initialize(UserProfile profile, PatientDetails details) {
    _userProfile = profile;
    _patientDetails = details;

    final key = profile.email.trim().toLowerCase();
    _patientDatabaseByEmail[key] = details;
    _userProfilesByEmail[key] = profile;

    if (details.gmailId.isNotEmpty) {
      _patientDatabaseByEmail[details.gmailId.trim().toLowerCase()] = details;
    }

    // Sync to Cloud Firestore Database
    FirebaseAuthService().savePatientDetailsToFirestore(
      userEmail: profile.email,
      detailsMap: {
        'fullName': details.fullName,
        'gender': details.gender,
        'age': details.age,
        'dateOfBirth': details.dateOfBirth.toIso8601String(),
        'city': details.city,
        'gmailId': details.gmailId,
      },
    );
  }

  /// Update active patient details
  void updatePatientDetails({
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
    int? age,
    String? city,
    String? gmailId,
  }) {
    final current = patientDetails;
    final updated = PatientDetails(
      fullName: fullName ?? current.fullName,
      gender: gender ?? current.gender,
      dateOfBirth: dateOfBirth ?? current.dateOfBirth,
      age: age ?? current.age,
      city: city ?? current.city,
      gmailId: gmailId ?? current.gmailId,
    );

    _patientDetails = updated;
    final key = userProfile.email.trim().toLowerCase();
    _patientDatabaseByEmail[key] = updated;
  }

  /// Update active user profile
  void updateUserProfile({
    String? name,
    String? email,
    String? provider,
    String? photoUrl,
  }) {
    final current = userProfile;
    _userProfile = UserProfile(
      name: name ?? current.name,
      email: email ?? current.email,
      provider: provider ?? current.provider,
      photoUrl: photoUrl ?? current.photoUrl,
    );

    final key = userProfile.email.trim().toLowerCase();
    _userProfilesByEmail[key] = userProfile;
  }
}
