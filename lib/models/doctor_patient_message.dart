import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorPatientMessage {
  final String id;
  final String patientEmail;
  final String doctorEmail;
  final String senderEmail;
  final String senderName;
  final String senderRole; // 'Patient' or 'Doctor'
  final String content;
  final DateTime timestamp;
  final bool isRead;

  DoctorPatientMessage({
    required this.id,
    required this.patientEmail,
    required this.doctorEmail,
    required this.senderEmail,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory DoctorPatientMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DoctorPatientMessage(
      id: doc.id,
      patientEmail: (data['patientEmail'] as String?) ?? '',
      doctorEmail: (data['doctorEmail'] as String?) ?? 'sathyaa7755@gmail.com',
      senderEmail: (data['senderEmail'] as String?) ?? '',
      senderName: (data['senderName'] as String?) ?? 'User',
      senderRole: (data['senderRole'] as String?) ?? 'Patient',
      content: (data['content'] as String?) ?? '',
      timestamp: data['timestamp'] != null && data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: (data['isRead'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientEmail': patientEmail,
      'doctorEmail': doctorEmail,
      'senderEmail': senderEmail,
      'senderName': senderName,
      'senderRole': senderRole,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}
