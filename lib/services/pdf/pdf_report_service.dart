import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:chagas_predictor/models/care_plan_model.dart';
import 'package:chagas_predictor/models/ecg_record.dart';
import 'package:chagas_predictor/models/user_profile.dart';
import 'pdf_download_helper.dart';

class PdfReportService {
  static final PdfReportService _instance = PdfReportService._internal();
  factory PdfReportService() => _instance;
  PdfReportService._internal();

  /// Generates and triggers browser download / print for Chagas Risk Medical Report PDF
  Future<void> generateAndDownloadReport({
    required PatientDetails patientDetails,
    required PredictionResult predictionResult,
    required EcgPatientRecord record,
    String? doctorNotes,
    String? doctorStatus,
  }) async {
    final pdf = pw.Document();

    final riskColor = _getPdfRiskColor(predictionResult.riskScore);
    final riskPercent = (predictionResult.riskScore * 100).toStringAsFixed(1);
    final dateStr = _formatDate(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#006B67'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CHAGAS PREDICT MEDICAL REPORT',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'LSTM Recurrent Neural Network Assessment & Biomarker Analysis',
                          style: const pw.TextStyle(
                            color: PdfColors.grey200,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Date: $dateStr',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'ID: ${record.examId}',
                          style: const pw.TextStyle(
                            color: PdfColors.grey200,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Patient Information Table
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PATIENT DEMOGRAPHICS & CLINICAL DETAILS',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#111827'),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Full Name: ${patientDetails.fullName}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Age: ${patientDetails.age} yrs', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Gender: ${patientDetails.gender}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Gmail ID: ${patientDetails.gmailId}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('City: ${patientDetails.city}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('DOB: ${_formatDate(patientDetails.dateOfBirth)}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // LSTM Risk Assessment Result Box
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: riskColor.shade(0.9),
                  border: pw.Border.all(color: riskColor, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CHAGAS CARDIOMYOPATHY RISK SCORE',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#374151'),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '$riskPercent%',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: riskColor,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            predictionResult.riskCategory.toUpperCase(),
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Model Confidence: ${(predictionResult.confidence * 100).toStringAsFixed(0)}%',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Extracted Numerical Biomarkers Table
              pw.Text(
                'EXTRACTED ECG NUMERICAL BIOMARKERS',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#111827'),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F3F4F6')),
                    children: [
                      _tableHeaderCell('Biomarker Parameter'),
                      _tableHeaderCell('Extracted Value'),
                      _tableHeaderCell('Normal Reference Range'),
                      _tableHeaderCell('Status'),
                    ],
                  ),
                  _tableRow('P-Wave Duration', '${record.pWaveDurationMean.toStringAsFixed(1)} ms', '40.0 - 60.0 ms', record.pWaveDurationMean > 60 ? 'Elevated' : 'Normal'),
                  _tableRow('PR Interval', '${record.prIntervalMean.toStringAsFixed(1)} ms', '120.0 - 200.0 ms', record.prIntervalMean > 180 ? 'Prolonged' : 'Normal'),
                  _tableRow('QRS Duration', '${record.qrsDurationMean.toStringAsFixed(1)} ms', '80.0 - 100.0 ms', record.qrsDurationMean > 100 ? 'Widened (RBBB Risk)' : 'Normal'),
                  _tableRow('QT Interval', '${record.qtIntervalMean.toStringAsFixed(1)} ms', '350.0 - 440.0 ms', record.qtIntervalMean > 420 ? 'Borderline High' : 'Normal'),
                  _tableRow('HRV SDNN', '${record.hrvSDNN.toStringAsFixed(1)} ms', '50.0 - 100.0 ms', record.hrvSDNN < 40 ? 'Depressed Tone' : 'Normal'),
                  _tableRow('HRV RMSSD', '${record.hrvRMSSD.toStringAsFixed(1)} ms', '20.0 - 50.0 ms', record.hrvRMSSD < 25 ? 'Low Autonomic' : 'Normal'),
                ],
              ),

              pw.SizedBox(height: 16),

              // Healthcare Instructions & Patient Action Plan
              pw.Text(
                'HEALTHCARE INSTRUCTIONS & RECOMMENDED CLINICAL NEXT STEPS',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#111827'),
                ),
              ),
              pw.SizedBox(height: 6),
              ...predictionResult.recommendations.map(
                (rec) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#006B67'))),
                      pw.Expanded(
                        child: pw.Text(
                          rec,
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 12),

              // Doctor Verification Review Notes (if available)
              if (doctorNotes != null && doctorNotes.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F9FAFB'),
                    border: pw.Border.all(color: PdfColor.fromHex('#006B67')),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DOCTOR CLINICAL REVIEW & VERIFICATION (${doctorStatus ?? 'Reviewed'})',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#006B67'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        doctorNotes,
                        style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey900),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],

              pw.Spacer(),

              // Footer / Disclaimer
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Chagas Predict Informational Medical Report • Not a standalone diagnosis',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page 1 of 1',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save PDF and trigger download / preview
    final pdfBytes = await pdf.save();
    final filename = 'Chagas_Medical_Report_${patientDetails.fullName.replaceAll(' ', '_')}.pdf';

    if (kIsWeb) {
      await downloadPdfDirect(pdfBytes, filename);
    } else {
      try {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: filename,
        );
      } catch (e) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: filename,
        );
      }
    }
  }

  pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#374151')),
      ),
    );
  }

  pw.TableRow _tableRow(String p1, String p2, String p3, String p4) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p1, style: const pw.TextStyle(fontSize: 9))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p2, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p3, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p4, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#006B67')))),
      ],
    );
  }

  PdfColor _getPdfRiskColor(double risk) {
    if (risk < 0.30) return PdfColor.fromHex('#0D9488'); // Green
    if (risk < 0.60) return PdfColor.fromHex('#EAB308'); // Yellow
    if (risk < 0.80) return PdfColor.fromHex('#F97316'); // Orange
    return PdfColor.fromHex('#EF4444'); // Red
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  /// Generates and downloads 1-Month Care Plan PDF Report reflecting original user activity and adherence.
  Future<void> generateAndDownloadCarePlanReport({
    required MonthlyCarePlan monthlyPlan,
    PatientDetails? patientDetails,
    UserProfile? profile,
  }) async {
    final pdf = pw.Document();
    final dateStr = _formatDate(DateTime.now());

    final patientName = patientDetails?.fullName.trim().isNotEmpty == true
        ? patientDetails!.fullName
        : (profile?.name.trim().isNotEmpty == true ? profile!.name : 'Patient');
    final ageStr = patientDetails != null ? '${patientDetails.age} yrs' : 'N/A';
    final genderStr = patientDetails?.gender ?? 'N/A';
    final cityStr = patientDetails?.city ?? 'N/A';

    // Calculate real stats strictly from original user data (no demo values)
    int totalItemsAllDays = 0;
    int completedItemsAllDays = 0;
    for (var daily in monthlyPlan.dailyPlans.values) {
      totalItemsAllDays += daily.totalItems;
      completedItemsAllDays += daily.completedItems;
    }
    final missedOrPendingItems = totalItemsAllDays - completedItemsAllDays;
    final realAdherenceRate = totalItemsAllDays == 0
        ? 0.0
        : (completedItemsAllDays / totalItemsAllDays * 100);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#006B67'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PERSONALIZED CHAGAS CARE PLAN REPORT',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '1-Month Cardiac Health & Activity Management Plan • Original Records',
                        style: const pw.TextStyle(
                          color: PdfColors.grey200,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        monthlyPlan.monthName,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Date: $dateStr',
                        style: const pw.TextStyle(
                          color: PdfColors.grey200,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Patient Summary Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Patient: $patientName', style: const pw.TextStyle(fontSize: 9.5)),
                  pw.Text('Age: $ageStr', style: const pw.TextStyle(fontSize: 9.5)),
                  pw.Text('Gender: $genderStr', style: const pw.TextStyle(fontSize: 9.5)),
                  pw.Text('City: $cityStr', style: const pw.TextStyle(fontSize: 9.5)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Real Adherence Summary KPI Grid
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Total Activities', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('$totalItemsAllDays', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B'))),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Completed (User)', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('$completedItemsAllDays', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#006B67'))),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Missed / Pending', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('$missedOrPendingItems', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#D97706'))),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Real Adherence Rate', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('${realAdherenceRate.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#006B67'))),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Monthly Focus Goals
            pw.Text(
              'MONTHLY CARDIAC FOCUS GOALS',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#111827')),
            ),
            pw.SizedBox(height: 4),
            ...monthlyPlan.monthlyFocusGoals.map(
              (goal) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  children: [
                    pw.Text('•  ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#006B67'))),
                    pw.Expanded(child: pw.Text(goal, style: const pw.TextStyle(fontSize: 9))),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),

            // Day-by-Day Activity Adherence Table
            pw.Text(
              'ORIGINAL DAILY ACTIVITY & ADHERENCE LOG (${monthlyPlan.monthName})',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#111827')),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F3F4F6')),
                  children: [
                    _tableHeaderCell('Day'),
                    _tableHeaderCell('Scheduled'),
                    _tableHeaderCell('Completed'),
                    _tableHeaderCell('Missed / Pending'),
                    _tableHeaderCell('Status'),
                  ],
                ),
                ...monthlyPlan.dailyPlans.entries.map((entry) {
                  final dayNum = entry.key;
                  final plan = entry.value;
                  final total = plan.totalItems;
                  final done = plan.completedItems;
                  final missed = total - done;
                  final rate = (plan.completionRate * 100).toInt();

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Day $dayNum', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('$total', style: const pw.TextStyle(fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('$done', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#006B67'))),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('$missed', style: pw.TextStyle(fontSize: 8.5, color: missed > 0 ? PdfColors.red800 : PdfColors.grey700)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          done == total
                              ? '100% Done'
                              : (done > 0 ? '$rate% Partial' : 'Missed'),
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: done == total
                                ? PdfColor.fromHex('#006B67')
                                : (done > 0 ? PdfColor.fromHex('#D97706') : PdfColors.red700),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final filename = 'Chagas_Care_Plan_${monthlyPlan.year}_${monthlyPlan.month}.pdf';

    if (kIsWeb) {
      await downloadPdfDirect(pdfBytes, filename);
    } else {
      try {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: filename,
        );
      } catch (e) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: filename,
        );
      }
    }
  }
}
