import 'ecg_record.dart';
import 'user_profile.dart';

class AssessmentHistoryRecord {
  final String id;
  final DateTime timestamp;
  final PatientDetails patientDetails;
  final String inputMode; // e.g. 'ECG Image Scan' or 'CSV Dataset'
  final String sourceName; // e.g. 'uploaded_ecg.jpg' or 'dataset.csv'
  final PredictionResult predictionResult;
  final EcgPatientRecord record;

  const AssessmentHistoryRecord({
    required this.id,
    required this.timestamp,
    required this.patientDetails,
    required this.inputMode,
    required this.sourceName,
    required this.predictionResult,
    required this.record,
  });
}
