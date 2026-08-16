import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:chagas_predictor/models/doctor_patient_message.dart';
import 'package:chagas_predictor/services/patient/doctor_portal_service.dart';

class DoctorPatientMessagingService {
  static final DoctorPatientMessagingService _instance = DoctorPatientMessagingService._internal();
  factory DoctorPatientMessagingService() => _instance;
  DoctorPatientMessagingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a message between Doctor and Patient
  Future<bool> sendMessage({
    required String patientEmail,
    required String doctorEmail,
    required String senderEmail,
    required String senderName,
    required String senderRole,
    required String content,
  }) async {
    if (content.trim().isEmpty) return false;

    final cleanPatientEmail = patientEmail.trim().toLowerCase();
    final cleanDoctorEmail = doctorEmail.trim().toLowerCase();
    final cleanSenderEmail = senderEmail.trim().toLowerCase();

    try {
      final msgData = {
        'patientEmail': cleanPatientEmail,
        'doctorEmail': cleanDoctorEmail,
        'senderEmail': cleanSenderEmail,
        'senderName': senderName,
        'senderRole': senderRole,
        'content': content.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      await _firestore.collection('messages').add(msgData);

      // Trigger receiver notification if sender is Patient
      if (senderRole == 'Patient') {
        DoctorPortalService().addNotification(
          DoctorNotification(
            id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
            title: 'New Patient Consultation Message from $senderName',
            message: content.trim(),
            timestamp: DateTime.now(),
            type: 'alert',
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Firestore sendMessage error: $e');
      return false;
    }
  }

  /// Real-time stream of messages between a specific patient and doctor
  Stream<List<DoctorPatientMessage>> getMessagesStream({
    required String patientEmail,
    required String doctorEmail,
  }) {
    final cleanPatientEmail = patientEmail.trim().toLowerCase();
    final cleanDoctorEmail = doctorEmail.trim().toLowerCase();

    return _firestore
        .collection('messages')
        .where('patientEmail', isEqualTo: cleanPatientEmail)
        .where('doctorEmail', isEqualTo: cleanDoctorEmail)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => DoctorPatientMessage.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    });
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String patientEmail,
    required String doctorEmail,
    required String currentRole,
  }) async {
    final cleanPatientEmail = patientEmail.trim().toLowerCase();
    final cleanDoctorEmail = doctorEmail.trim().toLowerCase();

    try {
      final query = await _firestore
          .collection('messages')
          .where('patientEmail', isEqualTo: cleanPatientEmail)
          .where('doctorEmail', isEqualTo: cleanDoctorEmail)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in query.docs) {
        final data = doc.data();
        if (data['senderRole'] != currentRole) {
          await doc.reference.update({'isRead': true});
        }
      }
    } catch (e) {
      debugPrint('Firestore markMessagesAsRead notice: $e');
    }
  }

  /// Stream ALL messages for Doctor across all patients
  Stream<List<DoctorPatientMessage>> getDoctorAllMessagesStream(String doctorEmail) {
    final cleanDoctorEmail = doctorEmail.trim().toLowerCase();
    return _firestore
        .collection('messages')
        .where('doctorEmail', isEqualTo: cleanDoctorEmail)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => DoctorPatientMessage.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  /// Stream unread message count for Patient from Doctor
  Stream<int> getPatientUnreadMessageCountStream(String patientEmail) {
    final cleanPatientEmail = patientEmail.trim().toLowerCase();
    return _firestore
        .collection('messages')
        .where('patientEmail', isEqualTo: cleanPatientEmail)
        .where('senderRole', isEqualTo: 'Doctor')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream unread message count for Doctor from Patients
  Stream<int> getDoctorUnreadMessageCountStream(String doctorEmail) {
    final cleanDoctorEmail = doctorEmail.trim().toLowerCase();
    return _firestore
        .collection('messages')
        .where('doctorEmail', isEqualTo: cleanDoctorEmail)
        .where('senderRole', isEqualTo: 'Patient')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
