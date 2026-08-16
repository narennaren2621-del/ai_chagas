import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:chagas_predictor/models/doctor_patient_record.dart';
import 'package:chagas_predictor/models/user_profile.dart';
import 'package:chagas_predictor/services/patient/assessment_history_service.dart';

class DoctorNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'alert', 'info', 'warning'
  bool isRead;

  DoctorNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

class DoctorPortalService {
  static final DoctorPortalService _instance = DoctorPortalService._internal();

  factory DoctorPortalService() => _instance;

  DoctorPortalService._internal();

  final List<DoctorPatientRecord> _patientRecords = [];
  final List<DoctorNotification> _notifications = [];

  // Real Doctor Profile Info (Dr. Sathya)
  String doctorName = 'Dr. Sathya';
  String doctorTitle = 'Chief Clinical Cardiologist & Electrophysiologist';
  String hospital = 'National Chagas Medical & Heart Research Center';
  String medicalLicense = 'CRM-DOC 775592';
  String doctorEmail = 'sathyaa7755@gmail.com';
  String doctorPhone = '+1 (555) 757-5841';
  String specialization = 'Chagasic Cardiomyopathy, ECG Analysis & Electrophysiology';

  // System Settings
  double highRiskThreshold = 0.75;
  bool enableEmailAlerts = true;
  bool enablePushNotifications = true;
  String defaultExportFormat = 'PDF Report';

  /// Fetch real doctor profile from dedicated Cloud Firestore 'doctors' collection
  Future<void> fetchDoctorProfileFromFirestore(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final docId = cleanEmail.replaceAll('.', '_').replaceAll('@', '_at_');

    try {
      final doc = await FirebaseFirestore.instance.collection('doctors').doc(docId).get();
      Map<String, dynamic>? data;

      if (doc.exists && doc.data() != null) {
        data = doc.data()!;
      } else {
        final query = await FirebaseFirestore.instance
            .collection('doctors')
            .where('doctorEmail', isEqualTo: cleanEmail)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          data = query.docs.first.data();
        }
      }

      if (data != null) {
        doctorName = (data['doctorName'] as String?) ?? (data['name'] as String?) ?? 'Dr. Sathya';
        doctorEmail = cleanEmail;
        if (data['doctorTitle'] != null) doctorTitle = data['doctorTitle'] as String;
        if (data['hospital'] != null) hospital = data['hospital'] as String;
        if (data['medicalLicense'] != null) medicalLicense = data['medicalLicense'] as String;
        if (data['doctorPhone'] != null) doctorPhone = data['doctorPhone'] as String;
        if (data['specialization'] != null) specialization = data['specialization'] as String;
      }
    } catch (e) {
      debugPrint('Firestore fetchDoctorProfile notice: $e');
    }
  }

  /// Save updated doctor profile to dedicated Cloud Firestore 'doctors' collection
  Future<void> saveDoctorProfileToFirestore(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final docId = cleanEmail.replaceAll('.', '_').replaceAll('@', '_at_');

    try {
      await FirebaseFirestore.instance.collection('doctors').doc(docId).set({
        'doctorId': docId,
        'doctorEmail': cleanEmail,
        'doctorName': doctorName,
        'doctorTitle': doctorTitle,
        'hospital': hospital,
        'medicalLicense': medicalLicense,
        'doctorPhone': doctorPhone,
        'specialization': specialization,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(docId).set({
        'name': doctorName,
        'role': 'Doctor',
        'doctorDocId': docId,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveDoctorProfile notice: $e');
    }
  }

  /// Stream live Doctor Profile data from Cloud Firestore 'doctors' collection
  Stream<Map<String, dynamic>> streamDoctorProfile(String email) {
    final cleanEmail = email.trim().toLowerCase();
    final docId = cleanEmail.replaceAll('.', '_').replaceAll('@', '_at_');
    return FirebaseFirestore.instance
        .collection('doctors')
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (data['doctorName'] != null) {
          doctorName = data['doctorName'] as String;
        }
        if (data['doctorTitle'] != null) {
          doctorTitle = data['doctorTitle'] as String;
        }
        if (data['hospital'] != null) {
          hospital = data['hospital'] as String;
        }
        if (data['medicalLicense'] != null) {
          medicalLicense = data['medicalLicense'] as String;
        }
        return data;
      }
      return {
        'doctorName': doctorName,
        'doctorTitle': doctorTitle,
        'hospital': hospital,
        'medicalLicense': medicalLicense,
      };
    });
  }

  /// Fetch all patient records live from Cloud Firestore 'patients' collection
  Future<List<DoctorPatientRecord>> fetchPatientsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('patients').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final email = (data['gmailId'] as String?) ?? (data['userEmail'] as String?) ?? '';
        final cleanEmail = email.trim().toLowerCase();

        final patientDetails = PatientDetails(
          fullName: (data['fullName'] as String?) ?? 'Registered Patient',
          gender: (data['gender'] as String?) ?? 'Not Specified',
          dateOfBirth: data['dateOfBirth'] != null
              ? DateTime.tryParse(data['dateOfBirth'] as String) ?? DateTime(1975, 1, 1)
              : DateTime(1975, 1, 1),
          age: (data['age'] as num?)?.toInt() ?? 45,
          city: (data['city'] as String?) ?? 'Not Specified',
          gmailId: email.isEmpty ? 'patient@chagas.org' : email,
        );

        final docId = doc.id;
        final existingIndex = _patientRecords.indexWhere((p) {
          final pEmail = p.patientDetails.gmailId.trim().toLowerCase();
          return (cleanEmail.isNotEmpty && pEmail == cleanEmail) || p.id == docId;
        });

        final record = DoctorPatientRecord(
          id: docId,
          profile: UserProfile(
            name: patientDetails.fullName,
            email: patientDetails.gmailId,
            provider: 'Cloud Firestore Database',
          ),
          patientDetails: patientDetails,
          lstmRiskScore: 0.25,
          riskCategory: 'Low Risk',
          modelConfidence: 0.92,
          lastAssessed: data['updatedAt'] != null && data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
          numericalBiomarkers: {
            'Heart_Rate': 72.0,
            'QRS_duration': 88.0,
            'PR_interval': 160.0,
            'QT_interval': 400.0,
          },
          clinicalRecommendations: [
            'Regular annual ECG monitoring recommended.',
            'Maintain healthy cardiovascular habits.',
          ],
          topBiomarkerNotes: [
            'Sinus Rhythm Normal',
            'QRS Conduction Intact',
          ],
          doctorVerificationStatus: 'Registered Patient',
        );

        if (existingIndex == -1) {
          _patientRecords.add(record);
        } else {
          if (_patientRecords[existingIndex].doctorVerificationStatus == 'Registered Patient') {
            _patientRecords[existingIndex] = record;
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore fetchPatients error: $e');
    }

    _syncRealAssessmentHistory();
    return patientRecords;
  }

  /// Get deduplicated, updated list of patient records (syncing with real user assessment history)
  List<DoctorPatientRecord> get patientRecords {
    _syncRealAssessmentHistory();
    return List.unmodifiable(_patientRecords);
  }

  /// Get list of notifications
  List<DoctorNotification> get notifications {
    return List.unmodifiable(_notifications);
  }

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  /// Add a new notification to Doctor notifications list
  void addNotification(DoctorNotification notification) {
    _notifications.insert(0, notification);
  }

  /// Sync live assessment records from AssessmentHistoryService into deduplicated DoctorPatientRecords
  void _syncRealAssessmentHistory() {
    final liveHistory = AssessmentHistoryService().historyRecords;

    for (final history in liveHistory) {
      final emailKey = history.patientDetails.gmailId.trim().toLowerCase();
      
      // Check if patient already exists in records
      final existingIndex = _patientRecords.indexWhere((p) {
        final pEmail = p.patientDetails.gmailId.trim().toLowerCase();
        return (emailKey.isNotEmpty && pEmail == emailKey) || p.id == history.id;
      });

      final convertedRecord = DoctorPatientRecord(
        id: history.id,
        profile: UserProfile(
          name: history.patientDetails.fullName,
          email: history.patientDetails.gmailId.isEmpty
              ? 'patient@chagas.org'
              : history.patientDetails.gmailId,
          provider: 'Patient Portal',
        ),
        patientDetails: history.patientDetails,
        lstmRiskScore: history.predictionResult.riskScore,
        riskCategory: history.predictionResult.riskCategory,
        modelConfidence: history.predictionResult.confidence,
        lastAssessed: history.timestamp,
        numericalBiomarkers: {
          'P_wave_duration': history.record.pWaveDurationMean,
          'PR_interval': history.record.prIntervalMean,
          'QRS_duration': history.record.qrsDurationMean,
          'QT_interval': history.record.qtIntervalMean,
          'HRV_SDNN': history.record.hrvSDNN,
          'HRV_RMSSD': history.record.hrvRMSSD,
          'Heart_Rate': history.record.allFeatures['heart_rate'] ?? 75.0,
        },
        clinicalRecommendations: history.predictionResult.recommendations,
        topBiomarkerNotes: history.predictionResult.topBiomarkers
            .map((b) => '${b.name}: ${b.statusDescription}')
            .toList(),
        doctorVerificationStatus: history.predictionResult.riskScore >= 0.75
            ? 'Action Required'
            : 'Pending Review',
      );

      if (existingIndex == -1) {
        _patientRecords.insert(0, convertedRecord);
        
        // Push notification for new real patient assessment
        if (history.predictionResult.riskScore >= 0.75) {
          _notifications.insert(
            0,
            DoctorNotification(
              id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
              title: 'High Risk Alert: ${history.patientDetails.fullName}',
              message:
                  'New assessment detected high Chagas risk (${(history.predictionResult.riskScore * 100).toStringAsFixed(1)}%). Urgent clinical review suggested.',
              timestamp: DateTime.now(),
              type: 'alert',
            ),
          );
        }
      } else {
        // Update existing patient with newer assessment metrics
        if (history.timestamp.isAfter(_patientRecords[existingIndex].lastAssessed)) {
          _patientRecords[existingIndex] = convertedRecord;
        }
      }
    }
  }

  /// Update doctor notes and verification status
  void updatePatientReview({
    required String patientId,
    required String notes,
    required String status,
  }) {
    final index = _patientRecords.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      _patientRecords[index].doctorNotes = notes;
      _patientRecords[index].doctorVerificationStatus = status;
      _patientRecords[index].doctorReviewedAt = DateTime.now();
    }
  }

  /// Mark notification as read
  void markNotificationAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
    }
  }

  /// Mark all notifications as read
  void markAllNotificationsAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
  }

  /// Clear all notifications
  void clearNotifications() {
    _notifications.clear();
  }


}
