import 'package:flutter/material.dart';
import '../services/ecg_image_digitizer_service.dart';

class EcgDigitizerView extends StatelessWidget {
  final DigitizedEcgResult result;
  final VoidCallback? onReupload;

  const EcgDigitizerView({
    super.key,
    required this.result,
    this.onReupload,
  });

  @override
  Widget build(BuildContext context) {
    final record = result.patientRecord;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFDCFCE7)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.center_focus_strong_rounded,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ECG Image Digitized into Numeric Values',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF14532D),
                        ),
                      ),
                      Text(
                        'Image: ${result.imageName} • Exam ID: ${record.examId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onReupload != null)
                  OutlinedButton.icon(
                    onPressed: onReupload,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Change Image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF15803D),
                      side: const BorderSide(color: Color(0xFF86EFAC)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upper row: ECG Image Thumbnail & Digitized Waveform Canvas
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 580;
                    return isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 220,
                                child: _buildImageThumbnail(context),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildWaveformGraph(),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildImageThumbnail(context),
                              const SizedBox(height: 16),
                              _buildWaveformGraph(),
                            ],
                          );
                  },
                ),

                const SizedBox(height: 20),

                // Extracted Numeric Biomarkers Section Title
                const Row(
                  children: [
                    Icon(Icons.numbers_rounded,
                        color: Color(0xFF006B67), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Extracted Numeric Signal Parameters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Grid of numeric parameter chips
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildParamChip(
                      label: 'P-Wave Duration',
                      value: '${record.pWaveDurationMean.toStringAsFixed(1)} ms',
                      icon: Icons.graphic_eq_rounded,
                      statusColor: record.pWaveDurationMean > 60
                          ? const Color(0xFFF97316)
                          : const Color(0xFF10B981),
                    ),
                    _buildParamChip(
                      label: 'PR Interval',
                      value: '${record.prIntervalMean.toStringAsFixed(1)} ms',
                      icon: Icons.timer_outlined,
                      statusColor: record.prIntervalMean > 180
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                    ),
                    _buildParamChip(
                      label: 'QRS Duration',
                      value: '${record.qrsDurationMean.toStringAsFixed(1)} ms',
                      icon: Icons.stacked_line_chart_rounded,
                      statusColor: record.qrsDurationMean > 100
                          ? const Color(0xFFF97316)
                          : const Color(0xFF10B981),
                    ),
                    _buildParamChip(
                      label: 'QT Interval',
                      value: '${record.qtIntervalMean.toStringAsFixed(1)} ms',
                      icon: Icons.speed_rounded,
                      statusColor: const Color(0xFF006B67),
                    ),
                    _buildParamChip(
                      label: 'HRV SDNN',
                      value: '${record.hrvSDNN.toStringAsFixed(1)} ms',
                      icon: Icons.favorite_border_rounded,
                      statusColor: record.hrvSDNN < 40
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                    ),
                    _buildParamChip(
                      label: 'HRV RMSSD',
                      value: '${record.hrvRMSSD.toStringAsFixed(1)} ms',
                      icon: Icons.monitor_heart_outlined,
                      statusColor: const Color(0xFF006B67),
                    ),
                    _buildParamChip(
                      label: 'Patient Demographics',
                      value: '${record.age.toInt()} yrs • ${record.isMale ? 'Male' : 'Female'}',
                      icon: Icons.person_outline_rounded,
                      statusColor: const Color(0xFF6B7280),
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

  Widget _buildImageThumbnail(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Source ECG Image',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF006B67).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Scanned',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF006B67),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: result.imageBytes != null
                  ? Image.memory(
                      result.imageBytes!,
                      fit: BoxFit.cover,
                    )
                  : CustomPaint(
                      painter: _MockEcgPaperPainter(),
                      child: Container(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ECG Trace Preset Image',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformGraph() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark ECG grid canvas background
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Digitized Signal (Numerical Voltage / Time)',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Lead II • 25mm/s',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: _DigitizedWaveformPainter(signal: result.extractedSignal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamChip({
    required String label,
    required String value,
    required IconData icon,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
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
}

class _MockEcgPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFFFCDD2)
      ..strokeWidth = 0.5;

    const step = 10.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final wavePaint = Paint()
      ..color = const Color(0xFFB71C1C)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);
    for (double x = 0; x < size.width; x += 15) {
      final y = size.height / 2 + (x % 30 == 0 ? -25 : (x % 45 == 0 ? 15 : 0));
      path.lineTo(x, y);
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DigitizedWaveformPainter extends CustomPainter {
  final List<double> signal;

  _DigitizedWaveformPainter({required this.signal});

  @override
  void paint(Canvas canvas, Size size) {
    // Background Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (signal.isEmpty) return;

    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8) // Bright Cyan Neon trace
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height / 2;
    final dx = size.width / (signal.length - 1);

    for (int i = 0; i < signal.length; i++) {
      final x = i * dx;
      final y = midY - (signal[i] * 32); // Scale voltage height
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _DigitizedWaveformPainter oldDelegate) {
    return oldDelegate.signal != signal;
  }
}
