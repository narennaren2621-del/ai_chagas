import 'package:flutter/material.dart';
import '../models/ecg_record.dart';
import '../models/patient_record.dart';
import '../models/user_profile.dart';
import '../services/patient_service.dart';
import '../services/pdf_report_service.dart';

class DoctorPatientDetailPage extends StatefulWidget {
  final PatientRecordData record;
  final UserProfile doctorProfile;

  const DoctorPatientDetailPage({
    super.key,
    required this.record,
    required this.doctorProfile,
  });

  @override
  State<DoctorPatientDetailPage> createState() => _DoctorPatientDetailPageState();
}

class _DoctorPatientDetailPageState extends State<DoctorPatientDetailPage> {
  late String _status;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.record.doctorVerificationStatus;
    _notesController = TextEditingController(text: widget.record.doctorNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveDoctorReview() {
    setState(() => _isSaving = true);

    PatientService().updateDoctorReview(
      patientId: widget.record.id,
      notes: _notesController.text.trim(),
      status: _status,
    );

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Doctor clinical review and notes saved successfully!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF006B67),
      ),
    );
  }

  Color _getRiskColor(double risk) {
    if (risk < 0.30) return const Color(0xFF0D9488);
    if (risk < 0.60) return const Color(0xFFEAB308);
    if (risk < 0.80) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final patient = record.patientDetails;
    final riskColor = _getRiskColor(record.lstmRiskScore);
    final riskPercent = (record.lstmRiskScore * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          'Patient Record: ${patient.fullName}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Download Patient Medical Report PDF',
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF006B67)),
            onPressed: () {
              final dummyRecord = EcgPatientRecord(
                examId: record.id,
                age: patient.age.toDouble(),
                isMale: patient.gender.toLowerCase() == 'male',
                pWaveDurationMean: record.numericalBiomarkers['P_wave_duration'] ?? 64.0,
                pWaveDurationStd: 7.0,
                prIntervalMean: record.numericalBiomarkers['PR_interval'] ?? 185.0,
                prSegmentMean: 80.0,
                qrsDurationMean: record.numericalBiomarkers['QRS_duration'] ?? 108.0,
                qtIntervalMean: record.numericalBiomarkers['QT_interval'] ?? 405.0,
                stSegmentMean: 175.0,
                stSlopeMean: 0.0035,
                hrvMeanNN: 810.0,
                hrvSDNN: record.numericalBiomarkers['HRV_SDNN'] ?? 32.0,
                hrvRMSSD: record.numericalBiomarkers['HRV_RMSSD'] ?? 24.5,
                hrvCVNN: 0.045,
                hrvMedianNN: 805.0,
                hrvPNN50: 12.0,
                hrvPNN20: 24.0,
                allFeatures: record.numericalBiomarkers,
              );

              final dummyPrediction = PredictionResult(
                patientRecord: dummyRecord,
                riskScore: record.lstmRiskScore,
                riskCategory: record.riskCategory,
                confidence: record.modelConfidence,
                topBiomarkers: [],
                recommendations: record.clinicalRecommendations,
                extractedNormalizedVector: [],
              );

              PdfReportService().generateAndDownloadReport(
                patientDetails: patient,
                predictionResult: dummyPrediction,
                record: dummyRecord,
                doctorNotes: record.doctorNotes,
                doctorStatus: record.doctorVerificationStatus,
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF006B67).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.medical_services_rounded, size: 14, color: Color(0xFF006B67)),
                SizedBox(width: 6),
                Text(
                  'Doctor Access',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF006B67),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Info Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF006B67).withValues(alpha: 0.1),
                          child: Text(
                            patient.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF006B67),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    patient.fullName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      record.id,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${patient.gender} • ${patient.age} yrs • DOB: ${_formatDate(patient.dateOfBirth)}',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Gmail: ${patient.gmailId} • City: ${patient.city}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // LSTM Model Prediction Banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          riskColor.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: riskColor.withValues(alpha: 0.35), width: 2),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: record.lstmRiskScore,
                                strokeWidth: 10,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$riskPercent%',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: riskColor,
                                  ),
                                ),
                                const Text(
                                  'Risk',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: riskColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  record.riskCategory.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'LSTM Neural Model Confidence: ${(record.modelConfidence * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last Assessed: ${_formatTimestamp(record.lastAssessed)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Extracted Numerical Biomarkers Table
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.query_stats_rounded, color: Color(0xFF006B67), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Extracted ECG Numerical Biomarkers',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: record.numericalBiomarkers.entries.map((entry) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key.replaceAll('_', ' '),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${entry.value.toStringAsFixed(1)} ${entry.key.contains('HRV') || entry.key.contains('duration') || entry.key.contains('interval') ? 'ms' : ''}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Explainable AI & Clinical Recommendations
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology_outlined, color: Color(0xFF006B67), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'LSTM Biomarker Impact & Clinical Recommendations',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...record.topBiomarkerNotes.map((note) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Color(0xFF006B67), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Recommended Next Steps:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 6),
                        ...record.clinicalRecommendations.map((rec) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $rec',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Doctor Clinical Review & Verification Form
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF006B67).withValues(alpha: 0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF006B67).withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.rate_review_rounded, color: Color(0xFF006B67), size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Doctor Clinical Review & Verification',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Verification Status:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            'Pending Review',
                            'Action Required',
                            'Confirmed High Risk',
                            'Cleared',
                          ]
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _status = v);
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Doctor Clinical Notes & Instructions:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Enter clinical observations, prescribed tests, or patient follow-up notes...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveDoctorReview,
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: Text(_isSaving ? 'Saving...' : 'Save Doctor Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006B67),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _formatTimestamp(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
