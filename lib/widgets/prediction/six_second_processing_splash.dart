import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Displays a high-tech 6-second processing splash screen modal overlay.
/// Takes exactly 6 seconds to perform neural network inference and countdown.
Future<bool?> showSixSecondProcessingSplash(
  BuildContext context, {
  required String inputTitle,
}) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // Force user to experience the full 6-second processing pipeline
    builder: (BuildContext dialogContext) {
      return SixSecondProcessingSplashDialog(inputTitle: inputTitle);
    },
  );
}

class SixSecondProcessingSplashDialog extends StatefulWidget {
  final String inputTitle;

  const SixSecondProcessingSplashDialog({
    super.key,
    required this.inputTitle,
  });

  @override
  State<SixSecondProcessingSplashDialog> createState() =>
      _SixSecondProcessingSplashDialogState();
}

class _SixSecondProcessingSplashDialogState
    extends State<SixSecondProcessingSplashDialog>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _pulseController;
  Timer? _timer;
  int _secondsRemaining = 6;
  double _progress = 0.0;
  String _currentStageText = 'Initializing 6-Second Deep AI Assessment...';
  final List<String> _completedStages = [];

  final List<String> _stages = [
    'Decoding 12-Lead voltage arrays & extracting image signal features...',
    'Normalizing 48 morphological cardiac biomarkers & HRV parameters...',
    'Constructing spatial-temporal sequence tensors [1, 10, 48] for LSTM Model...',
    'Executing Bidirectional LSTM Deep Learning neural network layers...',
    'Evaluating Chagasic cardiomyopathy risk & conduction disturbance probability...',
    'Finalizing clinical diagnostic matrix & preparing risk report...',
  ];

  @override
  void initState() {
    super.initState();

    // 6-second smooth progress animation controller
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addListener(() {
        setState(() {
          _progress = _animController.value;
        });
      });

    // Fast heartbeat pulse controller for live wave animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _animController.forward();
    _currentStageText = _stages[0];

    // 1-second tick timer for countdown (6s -> 5s -> 4s -> 3s -> 2s -> 1s -> 0s)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 1) {
          int completedIndex = 6 - _secondsRemaining;
          if (completedIndex >= 0 && completedIndex < _stages.length) {
            _completedStages.add(_stages[completedIndex]);
          }

          _secondsRemaining--;

          int nextStageIndex = 6 - _secondsRemaining;
          if (nextStageIndex >= 0 && nextStageIndex < _stages.length) {
            _currentStageText = _stages[nextStageIndex];
          }
        } else {
          _secondsRemaining = 0;
          if (!_completedStages.contains(_stages.last)) {
            _completedStages.add(_stages.last);
          }
          _currentStageText = '✓ Analysis Complete! Generating Chagas Risk Report...';
          timer.cancel();

          // Wait 400ms then close modal returning true to proceed to Risk Screen
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (_progress * 100).clamp(0, 100).toInt();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.transparent,
      elevation: 24,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Dark slate / cybernetic medical theme
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF0D9488).withValues(alpha: 0.5),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withValues(alpha: 0.25),
              blurRadius: 36,
              spreadRadius: 4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 0.8, end: 1.2).animate(
                          CurvedAnimation(
                            parent: _pulseController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF14B8A6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '6-SECOND AI SCAN IN PROGRESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2DD4BF),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'LSTM Deep Neural Net',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Input description
            Text(
              'Analyzing: ${widget.inputTitle}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFCBD5E1),
              ),
            ),

            const SizedBox(height: 24),

            // Central Circular 6-Second Timer Gauge & Pulse
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer Ambient Glow Ring
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                  ),
                ),

                // Animated Circular Progress Indicator
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFF334155),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2DD4BF),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),

                // Center 6-Second Counter & Progress %
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: Tween(begin: 0.95, end: 1.05).animate(
                        CurvedAnimation(
                          parent: _pulseController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFF2DD4BF),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_secondsRemaining}s',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2DD4BF),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Live ECG Heartbeat Scanner Line Graphic
            SizedBox(
              height: 36,
              width: double.infinity,
              child: CustomPaint(
                painter: _EcgScanLinePainter(
                  progress: _progress,
                  pulseValue: _pulseController.value,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: const Color(0xFF334155),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF2DD4BF),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Current Stage Terminal Log Display Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1E293B),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STAGE ${_secondsRemaining > 0 ? (7 - _secondsRemaining) : 6} OF 6',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2DD4BF),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Text(
                        'Time: 6.0s total',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStageText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      color: Color(0xFFF1F5F9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for live animated ECG wave pulse during the 6-second scan
class _EcgScanLinePainter extends CustomPainter {
  final double progress;
  final double pulseValue;

  _EcgScanLinePainter({required this.progress, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    // Draw baseline grid
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), gridPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF2DD4BF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height / 2;
    path.moveTo(0, midY);

    final stepCount = size.width.toInt();
    for (int x = 0; x < stepCount; x++) {
      double relativeX = x / size.width;
      double y = midY;

      // Generate ECG P-Q-R-S-T peaks along the wave
      double cycle = (relativeX * 6 + pulseValue * 2) % 1.0;
      if (cycle > 0.40 && cycle < 0.44) {
        y -= 6; // P wave
      } else if (cycle > 0.48 && cycle < 0.50) {
        y += 8; // Q wave
      } else if (cycle >= 0.50 && cycle <= 0.54) {
        y -= (midY - 4) * math.sin((cycle - 0.50) / 0.04 * math.pi); // Sharp R wave
      } else if (cycle > 0.54 && cycle < 0.57) {
        y += 12; // S wave
      } else if (cycle > 0.65 && cycle < 0.75) {
        y -= 7 * math.sin((cycle - 0.65) / 0.10 * math.pi); // T wave
      }

      path.lineTo(x.toDouble(), y);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _EcgScanLinePainter oldDelegate) => true;
}
