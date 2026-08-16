import 'package:flutter/material.dart';
import 'package:chagas_predictor/models/ecg_record.dart';
import 'package:chagas_predictor/services/patient/patient_service.dart';
import 'package:chagas_predictor/services/pdf/pdf_report_service.dart';

/// Helper function to display the Risk Result Splash Screen Dialog in front of the user
Future<void> showRiskResultSplashModal(
  BuildContext context, {
  required PredictionResult predictionResult,
  required EcgPatientRecord record,
  VoidCallback? onViewDetailsPressed,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return RiskResultSplashModal(
        predictionResult: predictionResult,
        record: record,
        onViewDetailsPressed: onViewDetailsPressed,
      );
    },
  );
}

class RiskResultSplashModal extends StatefulWidget {
  final PredictionResult predictionResult;
  final EcgPatientRecord record;
  final VoidCallback? onViewDetailsPressed;

  const RiskResultSplashModal({
    super.key,
    required this.predictionResult,
    required this.record,
    this.onViewDetailsPressed,
  });

  @override
  State<RiskResultSplashModal> createState() => _RiskResultSplashModalState();
}

class _RiskResultSplashModalState extends State<RiskResultSplashModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.predictionResult.riskScore,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Suitable risk color mapping
  Color _getRiskColor(double risk) {
    if (risk < 0.30) return const Color(0xFF0D9488); // Emerald / Teal Green (Low Risk)
    if (risk < 0.60) return const Color(0xFFD97706); // Golden Amber / Yellow (Moderate Risk)
    if (risk < 0.80) return const Color(0xFFEA580C); // Deep Orange (Elevated Risk)
    return const Color(0xFFDC2626); // Crimson Red (High Risk)
  }

  bool _isGeneratingPdf = false;

  Future<void> _downloadPdfReport() async {
    if (_isGeneratingPdf) return;
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final patient = PatientService().patientDetails;
      await PdfReportService().generateAndDownloadReport(
        patientDetails: patient,
        predictionResult: widget.predictionResult,
        record: widget.record,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Medical PDF Report generated & download started!'),
              ],
            ),
            backgroundColor: const Color(0xFF006B67),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF report: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  IconData _getRiskIcon(double risk) {
    if (risk < 0.30) return Icons.check_circle_rounded;
    if (risk < 0.60) return Icons.info_rounded;
    if (risk < 0.80) return Icons.warning_amber_rounded;
    return Icons.report_problem_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final pred = widget.predictionResult;
    final riskColor = _getRiskColor(pred.riskScore);
    final riskPercent = (pred.riskScore * 100).toStringAsFixed(1);
    final confidencePercent = (pred.confidence * 100).toStringAsFixed(0);
    final riskIcon = _getRiskIcon(pred.riskScore);
    final patient = PatientService().patientDetails;

    final screenHeight = MediaQuery.of(context).size.height;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 16,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: screenHeight * 0.88,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: riskColor.withValues(alpha: 0.4), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: riskColor.withValues(alpha: 0.25),
                blurRadius: 36,
                spreadRadius: 4,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Header Row with Close Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006B67).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.psychology_rounded, size: 16, color: Color(0xFF006B67)),
                        SizedBox(width: 6),
                        Text(
                          'LSTM AI Risk Result',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF006B67),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _isGeneratingPdf ? null : _downloadPdfReport,
                        icon: _isGeneratingPdf
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF006B67),
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF006B67)),
                        tooltip: 'Download PDF Report',
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                        tooltip: 'Close Splash',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Header
              Text(
                '${patient.fullName}\'s Risk Splash',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Exam #${widget.record.examId} • Chagas Biomarker Analysis',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),

              // Front Splash Radial Gauge
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient Outer Radial Glow
                      Container(
                        width: 165,
                        height: 165,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: riskColor.withValues(alpha: 0.06),
                        ),
                      ),
                      SizedBox(
                        width: 145,
                        height: 145,
                        child: CircularProgressIndicator(
                          value: _progressAnimation.value,
                          strokeWidth: 13,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(riskIcon, color: riskColor, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            '$riskPercent%',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: riskColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            'Chagas Risk Score',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Suitable Dynamic Color Risk Badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: riskColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(riskIcon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      pred.riskCategory.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Patient Result & Clinical Recommendation Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PATIENT RESULT SCREENING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF374151),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Confidence: $confidencePercent%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF006B67),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, thickness: 1, color: Color(0xFFE5E7EB)),
                    Row(
                      children: [
                        const Icon(Icons.medical_information_rounded, size: 16, color: Color(0xFF4B5563)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            pred.riskScore >= 0.60
                                ? 'Status: Further clinical evaluation recommended.'
                                : pred.riskScore >= 0.30
                                    ? 'Status: Periodic cardiac monitoring suggested.'
                                    : 'Status: Low risk profile detected.',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFD97706)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Screening Note: This AI model provides risk assessment & progression screening. Clinical confirmation by a cardiologist is required.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Biomarker Preview Chips
              if (pred.topBiomarkers.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Primary Contributing Biomarkers:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: pred.topBiomarkers.take(3).map((bio) {
                          final isHigh = bio.riskImpact > 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isHigh
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isHigh
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFF6EE7B7),
                              ),
                            ),
                            child: Text(
                              '${bio.name}: ${bio.rawValue.toStringAsFixed(1)} ${bio.unit}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isHigh
                                    ? const Color(0xFF991B1B)
                                    : const Color(0xFF065F46),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingPdf ? null : _downloadPdfReport,
                      icon: _isGeneratingPdf
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: Text(_isGeneratingPdf ? 'Generating...' : 'Download PDF Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006B67),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (widget.onViewDetailsPressed != null) {
                          widget.onViewDetailsPressed!();
                        }
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('See Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF006B67),
                        side: const BorderSide(color: Color(0xFF006B67)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
