import 'package:chagas_predictor/models/assessment_history_record.dart';
import 'package:chagas_predictor/models/ecg_record.dart';
import 'package:chagas_predictor/models/user_profile.dart';
import 'package:chagas_predictor/services/auth/firebase_auth_service.dart';

class AssessmentHistoryService {
  static final AssessmentHistoryService _instance =
      AssessmentHistoryService._internal();

  factory AssessmentHistoryService() => _instance;

  AssessmentHistoryService._internal();

  final List<AssessmentHistoryRecord> _records = [];

  /// Get all history records sorted newest first
  List<AssessmentHistoryRecord> get historyRecords {
    final list = List<AssessmentHistoryRecord>.from(_records);
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(list);
  }

  /// Save a real user assessment to history (only for user input)
  void saveAssessmentRecord({
    required PatientDetails patientDetails,
    required String inputMode,
    required String sourceName,
    required PredictionResult predictionResult,
    required EcgPatientRecord record,
  }) {
    final historyEntry = AssessmentHistoryRecord(
      id: 'HIST-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      patientDetails: patientDetails,
      inputMode: inputMode,
      sourceName: sourceName,
      predictionResult: predictionResult,
      record: record,
    );

    _records.insert(0, historyEntry);

    // Sync assessment to Cloud Firestore Database
    FirebaseAuthService().saveAssessmentToFirestore(
      userEmail: patientDetails.gmailId.isNotEmpty ? patientDetails.gmailId : 'patient@chagas.org',
      assessmentMap: {
        'id': historyEntry.id,
        'patientName': patientDetails.fullName,
        'patientAge': patientDetails.age,
        'patientGender': patientDetails.gender,
        'inputMode': inputMode,
        'sourceName': sourceName,
        'riskScore': predictionResult.riskScore,
        'riskCategory': predictionResult.riskCategory,
        'confidence': predictionResult.confidence,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Delete a single history record by ID
  bool deleteRecord(String id) {
    final initialLen = _records.length;
    _records.removeWhere((r) => r.id == id);
    return _records.length < initialLen;
  }

  /// Clear all saved history entries
  void clearHistory() {
    _records.clear();
  }

  /// Filter history entries by query search or risk category
  List<AssessmentHistoryRecord> filterHistory({
    String query = '',
    String riskCategory = 'All',
  }) {
    final q = query.trim().toLowerCase();
    final cat = riskCategory.trim().toLowerCase();

    return historyRecords.where((item) {
      final matchesQuery = q.isEmpty ||
          item.patientDetails.fullName.toLowerCase().contains(q) ||
          item.sourceName.toLowerCase().contains(q) ||
          item.inputMode.toLowerCase().contains(q) ||
          item.id.toLowerCase().contains(q);

      final matchesCategory = cat == 'all' ||
          item.predictionResult.riskCategory.toLowerCase() == cat;

      return matchesQuery && matchesCategory;
    }).toList();
  }
}
