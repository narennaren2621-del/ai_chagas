import 'package:flutter/material.dart';
import 'package:chagas_predictor/models/assessment_history_record.dart';
import 'package:chagas_predictor/services/patient/assessment_history_service.dart';
import 'package:chagas_predictor/services/pdf/pdf_report_service.dart';
import 'package:chagas_predictor/widgets/prediction/risk_result_splash_modal.dart';
import 'package:chagas_predictor/pages/prediction/prediction_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getRiskColor(double risk) {
    if (risk < 0.30) return const Color(0xFF0D9488); // Teal (Low Risk)
    if (risk < 0.60) return const Color(0xFFD97706); // Amber (Moderate Risk)
    if (risk < 0.80) return const Color(0xFFEA580C); // Deep Orange (Elevated)
    return const Color(0xFFDC2626); // Crimson Red (High Risk)
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year • $hour:$minute $period';
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Clear Assessment History?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all saved user assessment history records? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              AssessmentHistoryService().clearHistory();
              Navigator.of(ctx).pop();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All History'),
          ),
        ],
      ),
    );
  }

  void _deleteRecord(String id) {
    AssessmentHistoryService().deleteRecord(id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assessment record deleted.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allHistory = AssessmentHistoryService().historyRecords;
    final filteredHistory = AssessmentHistoryService().filterHistory(
      query: _searchController.text,
      riskCategory: _selectedCategory,
    );

    final totalCount = allHistory.length;
    final highRiskCount = allHistory
        .where((r) => r.predictionResult.riskScore >= 0.70)
        .length;
    final avgRisk = totalCount > 0
        ? (allHistory.fold<double>(0, (sum, r) => sum + r.predictionResult.riskScore) /
            totalCount *
            100)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(
          'Assessment History',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (allHistory.isNotEmpty)
            TextButton.icon(
              onPressed: _confirmClearHistory,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Clear History'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title & Subtitle
                  const Text(
                    'User Assessment History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Logs of all completed Chagas risk assessments performed from user inputs (ECG Photos & CSV Datasets).',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 20),

                  // Summary KPI Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 580;
                      final cards = [
                        _buildKpiCard(
                          label: 'Total Assessments',
                          value: '$totalCount',
                          icon: Icons.assignment_turned_in_rounded,
                          iconColor: const Color(0xFF006B67),
                          bgColor: const Color(0xFF006B67).withValues(alpha: 0.08),
                        ),
                        _buildKpiCard(
                          label: 'High Risk Cases',
                          value: '$highRiskCount',
                          icon: Icons.warning_amber_rounded,
                          iconColor: const Color(0xFFDC2626),
                          bgColor: const Color(0xFFDC2626).withValues(alpha: 0.08),
                        ),
                        _buildKpiCard(
                          label: 'Avg Chagas Risk Score',
                          value: '${avgRisk.toStringAsFixed(1)}%',
                          icon: Icons.analytics_outlined,
                          iconColor: const Color(0xFF0284C7),
                          bgColor: const Color(0xFF0284C7).withValues(alpha: 0.08),
                        ),
                      ];

                      return isWide
                          ? Row(
                              children: cards
                                  .map((c) => Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: c,
                                        ),
                                      ))
                                  .toList(),
                            )
                          : Column(
                              children: cards
                                  .map((c) => Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 10),
                                        child: c,
                                      ))
                                  .toList(),
                            );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Search & Category Filter Section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText:
                                'Search history by patient name, source file, or ID...',
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: Color(0xFF6B7280)),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Category Filter Buttons
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              'All',
                              'High Risk',
                              'Elevated Risk',
                              'Moderate Risk',
                              'Low Risk',
                            ].map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedCategory = cat);
                                    }
                                  },
                                  selectedColor: const Color(0xFF006B67),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF4B5563),
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 12.5,
                                  ),
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // History Records List / Empty State
                  if (filteredHistory.isEmpty)
                    _buildEmptyState(context, hasSearch: allHistory.isNotEmpty)
                  else
                    Column(
                      children: filteredHistory
                          .map((record) => _buildHistoryCard(context, record))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, AssessmentHistoryRecord item) {
    final pred = item.predictionResult;
    final rec = item.record;
    final riskColor = _getRiskColor(pred.riskScore);
    final riskPercent = (pred.riskScore * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFF3F4F6)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      item.inputMode.contains('ECG')
                          ? Icons.image_search_rounded
                          : Icons.table_chart_outlined,
                      size: 16,
                      color: const Color(0xFF006B67),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.inputMode} (${item.sourceName})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDate(item.timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Name & Risk Gauge Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.patientDetails.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Age: ${item.patientDetails.age} • Gender: ${item.patientDetails.gender} • City: ${item.patientDetails.city}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Risk Score Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: riskColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 16, color: riskColor),
                          const SizedBox(width: 6),
                          Text(
                            '${pred.riskCategory} ($riskPercent%)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: riskColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Extracted Biomarker Summary Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildMiniChip(
                        'P-Wave', '${rec.pWaveDurationMean.toStringAsFixed(0)} ms'),
                    _buildMiniChip(
                        'PR Int', '${rec.prIntervalMean.toStringAsFixed(0)} ms'),
                    _buildMiniChip(
                        'QRS', '${rec.qrsDurationMean.toStringAsFixed(0)} ms'),
                    _buildMiniChip(
                        'QT Int', '${rec.qtIntervalMean.toStringAsFixed(0)} ms'),
                    _buildMiniChip(
                        'HRV SDNN', '${rec.hrvSDNN.toStringAsFixed(0)} ms'),
                    _buildMiniChip(
                        'HRV RMSSD', '${rec.hrvRMSSD.toStringAsFixed(0)} ms'),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 12),

                // Action Buttons (View Details, PDF Report, Delete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            showRiskResultSplashModal(
                              context,
                              predictionResult: pred,
                              record: rec,
                              onViewDetailsPressed: () {},
                            );
                          },
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('View Result'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006B67),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await PdfReportService().generateAndDownloadReport(
                              patientDetails: item.patientDetails,
                              predictionResult: pred,
                              record: rec,
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                          label: const Text('PDF Report'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF006B67),
                            side: const BorderSide(color: Color(0xFF006B67)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Delete record',
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFF9CA3AF), size: 20),
                      onPressed: () => _deleteRecord(item.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool hasSearch}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF006B67).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 36,
              color: Color(0xFF006B67),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'No matching history records'
                : 'No User Assessment History Yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'Try adjusting your search filter criteria or clear the search bar.'
                : 'All completed Chagas risk assessments from actual user inputs (ECG Photos & CSV Datasets) will be saved here automatically.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          if (!hasSearch)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PredictionPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: const Text('Perform Risk Assessment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B67),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
