import 'user_profile.dart';

class PatientRecordData {
  final String id;
  final UserProfile profile;
  final PatientDetails patientDetails;
  final double lstmRiskScore; // 0.0 to 1.0
  final String riskCategory; // 'Critical High Risk', 'Elevated Risk', 'Moderate Risk', 'Low Risk'
  final double modelConfidence;
  final DateTime lastAssessed;
  final Map<String, double> numericalBiomarkers;
  final List<String> clinicalRecommendations;
  final List<String> topBiomarkerNotes;
  String doctorVerificationStatus; // 'Pending Review', 'Confirmed High Risk', 'Cleared', 'Action Required'
  String? doctorNotes;
  DateTime? doctorReviewedAt;

  PatientRecordData({
    required this.id,
    required this.profile,
    required this.patientDetails,
    required this.lstmRiskScore,
    required this.riskCategory,
    required this.modelConfidence,
    required this.lastAssessed,
    required this.numericalBiomarkers,
    required this.clinicalRecommendations,
    required this.topBiomarkerNotes,
    this.doctorVerificationStatus = 'Pending Review',
    this.doctorNotes,
    this.doctorReviewedAt,
  });
}
