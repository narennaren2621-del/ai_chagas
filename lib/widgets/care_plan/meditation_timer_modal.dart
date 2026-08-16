import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chagas_predictor/models/care_plan_model.dart';

class MeditationTimerModal extends StatefulWidget {
  final CarePlanItem item;
  final VoidCallback onCompleted;

  const MeditationTimerModal({
    super.key,
    required this.item,
    required this.onCompleted,
  });

  @override
  State<MeditationTimerModal> createState() => _MeditationTimerModalState();
}

class _MeditationTimerModalState extends State<MeditationTimerModal>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  late int _initialSeconds;
  bool _isRunning = false;
  Timer? _timer;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  String _ambientSound = 'Soft Ocean Waves';
  bool _soundEnabled = true;

  final List<String> _soundOptions = [
    'Soft Ocean Waves',
    'Deep Vagus Frequency (432Hz)',
    'Rainfall & Gentle Wind',
    'Forest Birds & Stream',
  ];

  @override
  void initState() {
    super.initState();
    final mins = widget.item.durationMinutes > 0 ? widget.item.durationMinutes : 10;
    _initialSeconds = mins * 60;
    _remainingSeconds = _initialSeconds;

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
          _completeSession();
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _initialSeconds;
    });
  }

  void _completeSession() {
    widget.onCompleted();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Namaste! Meditation session completed & recorded.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF7C3AED),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _breathingPhaseText {
    if (!_isRunning) return 'Press Play to Begin';
    final val = _breathingController.value;
    if (val < 0.4) return 'Inhale Deeply (4s)';
    if (val < 0.6) return 'Hold Breath (4s)';
    return 'Exhale Slowly (4s)';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _initialSeconds == 0
        ? 1.0
        : (1.0 - (_remainingSeconds / _initialSeconds));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E1065), Color(0xFF5B21B6), Color(0xFF4C1D95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.self_improvement_rounded,
                            color: Color(0xFFC4B5FD), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Cardiac Mindfulness',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title & Description
              Text(
                widget.item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.item.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFDDD6FE),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Animated Breathing Ring & Timer display
              ScaleTransition(
                scale: _breathingAnimation,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA78BFA).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 185,
                        height: 185,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFA78BFA),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTime(_remainingSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _breathingPhaseText,
                            style: TextStyle(
                              color: _isRunning
                                  ? const Color(0xFFC4B5FD)
                                  : Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                    tooltip: 'Reset Timer',
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _toggleTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4C1D95),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isRunning ? 'PAUSE' : 'START',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() {
                        _soundEnabled = !_soundEnabled;
                      });
                    },
                    icon: Icon(
                      _soundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                    tooltip: _soundEnabled ? 'Mute Sound' : 'Enable Sound',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Ambient Sound Selector
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.music_note_rounded,
                        color: Color(0xFFC4B5FD), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _ambientSound,
                          dropdownColor: const Color(0xFF3B0764),
                          icon: const Icon(Icons.arrow_drop_down_rounded,
                              color: Colors.white70),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _ambientSound = val);
                            }
                          },
                          items: _soundOptions.map((sound) {
                            return DropdownMenuItem<String>(
                              value: sound,
                              child: Text(sound),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Mark Complete Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _completeSession,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('MARK SESSION AS COMPLETED'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC4B5FD),
                    side: const BorderSide(color: Color(0xFFA78BFA), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
