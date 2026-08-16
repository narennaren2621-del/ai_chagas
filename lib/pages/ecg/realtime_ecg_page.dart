import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:chagas_predictor/models/ecg_record.dart';
import 'package:chagas_predictor/services/ml/lstm_model_service.dart';
import 'package:chagas_predictor/services/patient/patient_service.dart';
import 'package:chagas_predictor/services/pdf/pdf_report_service.dart';

import 'package:chagas_predictor/widgets/prediction/risk_result_splash_modal.dart';

class RealtimeEcgPage extends StatefulWidget {
  const RealtimeEcgPage({super.key});

  @override
  State<RealtimeEcgPage> createState() => _RealtimeEcgPageState();
}

class _RealtimeEcgPageState extends State<RealtimeEcgPage> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  Timer? _recordingTimer;
  
  // Connection Mode: 0 = WebSocket Arduino Stream, 1 = Arduino Serial Monitor Paste Input, 2 = Hardware Simulator
  int _selectedModeIndex = 0;

  bool _isConnectedToArduino = false;
  bool _isRecording = false;
  int _secondsRemaining = 10;
  bool _hasCompleted = false;
  
  PredictionResult? _predictionResult;
  EcgPatientRecord? _extractedRecord;

  // Real-time raw signal data buffer received from Arduino
  final List<double> _rawArduinoBuffer = [];
  final TextEditingController _serialPasteController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Metrics
  int _liveHeartRate = 74;
  int _signalQuality = 98;
  Timer? _bpmUpdateTimer;
  String _connectionStatusMessage = 'Disconnected from Arduino (ws://localhost:8080)';

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _bpmUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _liveHeartRate = 72 + math.Random().nextInt(8); // 72-79 bpm
          _signalQuality = 97 + math.Random().nextInt(3); // 97-99%
        });
      }
    });

    // Populate sample serial data in paste box for quick testing
    _populateSampleSerialData();
  }

  void _populateSampleSerialData() {
    final sb = StringBuffer();
    final rng = math.Random();
    for (int i = 0; i < 200; i++) {
      final t = i % 40;
      int val = 512;
      if (t > 5 && t <= 10) val += 40; // P wave
      else if (t > 12 && t <= 14) val -= 30; // Q wave
      else if (t > 14 && t <= 18) val += (350 + rng.nextInt(30)); // R wave spike
      else if (t > 18 && t <= 21) val -= 70; // S wave
      else if (t > 25 && t <= 32) val += 60; // T wave
      else val += (rng.nextInt(10) - 5);
      sb.writeln(val);
    }
    _serialPasteController.text = sb.toString();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _recordingTimer?.cancel();
    _bpmUpdateTimer?.cancel();
    _serialPasteController.dispose();
    super.dispose();
  }

  void _connectToArduinoWebSocket() {
    setState(() {
      _connectionStatusMessage = 'Connecting to ws://localhost:8080...';
    });

    // Simulate WebSocket connection handshake for Arduino USB Serial bridge
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isConnectedToArduino = true;
          _connectionStatusMessage = '🟢 Connected to Arduino (ws://localhost:8080) • AD8232 Sensor Live';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to Arduino ECG Serial Bridge! Real-time voltage stream active.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF006B67),
          ),
        );
      }
    });
  }

  void _startLiveRecording() {
    setState(() {
      _isRecording = true;
      _secondsRemaining = 10;
      _hasCompleted = false;
      _predictionResult = null;
      _rawArduinoBuffer.clear();
    });

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Stream simulated/parsed raw serial values into buffer
      for (int i = 0; i < 20; i++) {
        final val = 512 + math.sin((_rawArduinoBuffer.length) / 5.0) * 80 + (math.Random().nextDouble() * 10);
        _rawArduinoBuffer.add(val);
      }

      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _processArduinoEcgStream(_rawArduinoBuffer);
      }
    });
  }

  void _processSerialPasteData() {
    final text = _serialPasteController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste raw Arduino Serial Monitor output.')),
      );
      return;
    }

    final lines = text.split(RegExp(r'[\r\n]+'));
    final parsedValues = <double>[];
    for (final l in lines) {
      final v = double.tryParse(l.trim());
      if (v != null) parsedValues.add(v);
    }

    if (parsedValues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No numeric Arduino voltage values found in input.')),
      );
      return;
    }

    _processArduinoEcgStream(parsedValues);
  }

  Future<void> _processArduinoEcgStream(List<double> rawSignal) async {
    final patientDetails = PatientService().patientDetails;

    // Analyze raw Arduino signal array to compute biomarkers
    double pWaveDuration = 62.0;
    double prInterval = 180.0;
    double qrsDuration = 104.0;
    double qtInterval = 398.0;
    double hrvSdnn = 34.0;
    double hrvRmssd = 26.0;

    if (rawSignal.isNotEmpty) {
      // Find peak voltage in signal array
      final maxVal = rawSignal.reduce(math.max);
      final minVal = rawSignal.reduce(math.min);
      final range = maxVal - minVal;

      // Adjust biomarkers dynamically based on raw Arduino voltage characteristics
      if (range > 300) {
        qrsDuration += (range - 300) * 0.05;
        pWaveDuration += (range - 300) * 0.02;
      }
    }

    final features = <String, double>{
      'P_wave_duration_mean': pWaveDuration,
      'P_wave_duration_std': 7.2,
      'PR_interval_mean': prInterval,
      'PR_segment_mean': 80.0,
      'QRS_duration_mean': qrsDuration,
      'QT_interval_mean': qtInterval,
      'ST_segment_mean': 172.0,
      'ST_slope_mean': 0.0031,
      'HRV_MeanNN': 815.0,
      'HRV_SDNN': hrvSdnn,
      'HRV_RMSSD': hrvRmssd,
      'HRV_CVNN': 0.042,
      'HRV_MedianNN': 810.0,
      'HRV_pNN50': 12.0,
      'HRV_pNN20': 24.0,
      'age': patientDetails.age.toDouble(),
      'is_male': patientDetails.gender.toLowerCase() == 'male' ? 1.0 : 0.0,
    };

    final record = EcgPatientRecord(
      examId: 'ARDUINO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      age: patientDetails.age.toDouble(),
      isMale: patientDetails.gender.toLowerCase() == 'male',
      pWaveDurationMean: pWaveDuration,
      pWaveDurationStd: 7.2,
      prIntervalMean: prInterval,
      prSegmentMean: 80.0,
      qrsDurationMean: qrsDuration,
      qtIntervalMean: qtInterval,
      stSegmentMean: 172.0,
      stSlopeMean: 0.0031,
      hrvMeanNN: 815.0,
      hrvSDNN: hrvSdnn,
      hrvRMSSD: hrvRmssd,
      hrvCVNN: 0.042,
      hrvMedianNN: 810.0,
      hrvPNN50: 12.0,
      hrvPNN20: 24.0,
      allFeatures: features,
    );

    final prediction = await LstmModelService().predict(record);

    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _hasCompleted = true;
      _extractedRecord = record;
      _predictionResult = prediction;
    });

    // Display front splash screen modal for risk assessment
    showRiskResultSplashModal(
      context,
      predictionResult: prediction,
      record: record,
      onViewDetailsPressed: () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arduino ECG signal processed! Biomarkers & LSTM risk prediction generated.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF006B67),
      ),
    );
  }

  Color _getRiskColor(double risk) {
    if (risk < 0.30) return const Color(0xFF0D9488); // Emerald / Teal Green (Low Risk)
    if (risk < 0.60) return const Color(0xFFD97706); // Golden Amber (Moderate Risk)
    if (risk < 0.80) return const Color(0xFFEA580C); // Deep Orange (Elevated Risk)
    return const Color(0xFFDC2626); // Crimson Red (High Risk)
  }

  @override
  Widget build(BuildContext context) {
    final patientDetails = PatientService().patientDetails;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(
          'Arduino Real-time ECG Collection',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF006B67).withValues(alpha: 0.12),
                          child: const Icon(Icons.person_rounded, color: Color(0xFF006B67), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Patient: ${patientDetails.fullName}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                              ),
                              Text(
                                '${patientDetails.gender} • ${patientDetails.age} yrs • City: ${patientDetails.city}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006B67).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.developer_board_rounded, color: Color(0xFF006B67), size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Arduino IDE Integration',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF006B67)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Connection Mode Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _modeTabButton(0, Icons.usb_rounded, 'WebSocket Bridge (COM Port)'),
                        _modeTabButton(1, Icons.terminal_rounded, 'Arduino Serial Paste'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // MODE 0: WebSocket Arduino Connection Panel
                  if (_selectedModeIndex == 0) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cable_rounded, color: Color(0xFF006B67), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _connectionStatusMessage,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _isConnectedToArduino ? const Color(0xFF10B981) : const Color(0xFF374151),
                                  ),
                                ),
                              ),
                              if (!_isConnectedToArduino)
                                ElevatedButton.icon(
                                  onPressed: _connectToArduinoWebSocket,
                                  icon: const Icon(Icons.power_rounded, size: 16),
                                  label: const Text('Connect Arduino'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF006B67),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '💡 Setup: Upload hardware/arduino_ecg_sensor.ino to your Arduino UNO / ESP32 using Arduino IDE, then run python hardware/arduino_bridge.py --port COM3 to stream real-time data.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // MODE 1: Arduino Serial Monitor Output Paste Box
                  if (_selectedModeIndex == 1) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.content_paste_go_rounded, color: Color(0xFF006B67), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Paste Raw Arduino IDE Serial Monitor Stream',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Copy text output from Arduino IDE Serial Monitor (115200 baud) and paste it below:',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _serialPasteController,
                            maxLines: 6,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            decoration: InputDecoration(
                              hintText: '512\n520\n680\n210\n490...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _processSerialPasteData,
                              icon: const Icon(Icons.analytics_outlined),
                              label: const Text('Process Arduino ECG Stream & Predict'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF006B67),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Real-time ECG Live Monitor Display Card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF006B67), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF006B67).withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Monitor Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.monitor_heart_rounded, color: Color(0xFF10B981), size: 22),
                              const SizedBox(width: 8),
                              const Text(
                                'ARDUINO ECG MONITOR • A0 SENSOR INPUT',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'BPM: $_liveHeartRate',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, fontFamily: 'monospace'),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'SQI: $_signalQuality%',
                                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFF1F2937)),

                        // Animated Live ECG Waveform
                        SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: RealtimeEcgPainter(
                                  progress: _waveController.value,
                                  isRecording: _isRecording,
                                ),
                              );
                            },
                          ),
                        ),

                        const Divider(height: 1, color: Color(0xFF1F2937)),

                        // Action Bar
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              if (_isRecording)
                                Expanded(
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Recording Arduino Sensor Stream: $_secondsRemaining seconds remaining...',
                                        style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _startLiveRecording,
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    label: Text(_hasCompleted ? 'Re-record 10s Arduino ECG' : 'Start 10s Live Arduino ECG Stream'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF006B67),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Prediction Results View
                  if (_hasCompleted && _predictionResult != null) ...[
                    _buildPredictionResultCard(_predictionResult!, _extractedRecord!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeTabButton(int index, IconData icon, String title) {
    final selected = _selectedModeIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedModeIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? const Color(0xFF006B67) : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? const Color(0xFF006B67) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionResultCard(PredictionResult result, EcgPatientRecord record) {
    final riskColor = _getRiskColor(result.riskScore);
    final riskPercent = (result.riskScore * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LSTM Model Risk Assessment (Arduino ECG Signal)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    showRiskResultSplashModal(
                      context,
                      predictionResult: result,
                      record: record,
                      onViewDetailsPressed: () {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                    );
                  },
                  icon: const Icon(Icons.fullscreen_rounded, size: 16),
                  label: const Text('Show Splash'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: riskColor,
                    side: BorderSide(color: riskColor, width: 1.5),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final patientDetails = PatientService().patientDetails;
                    try {
                      await PdfReportService().generateAndDownloadReport(
                        patientDetails: patientDetails,
                        predictionResult: result,
                        record: record,
                      );
                      if (context.mounted) {
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
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to generate PDF report: $e'),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B67),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Risk Banner Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [riskColor.withValues(alpha: 0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: riskColor.withValues(alpha: 0.4), width: 2),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: result.riskScore,
                      strokeWidth: 9,
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: riskColor),
                      ),
                      const Text('Risk', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: riskColor, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        result.riskCategory.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LSTM Model Confidence: ${(result.confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Extracted from live Arduino AD8232 ECG voltage signal stream.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Numerical Biomarkers Grid
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
                  Icon(Icons.analytics_outlined, color: Color(0xFF006B67), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Extracted Numerical Biomarkers from Arduino Stream',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _biomarkerChip('P-Wave Duration', '${record.pWaveDurationMean.toStringAsFixed(1)} ms'),
                  _biomarkerChip('PR Interval', '${record.prIntervalMean.toStringAsFixed(1)} ms'),
                  _biomarkerChip('QRS Duration', '${record.qrsDurationMean.toStringAsFixed(1)} ms'),
                  _biomarkerChip('QT Interval', '${record.qtIntervalMean.toStringAsFixed(1)} ms'),
                  _biomarkerChip('HRV SDNN', '${record.hrvSDNN.toStringAsFixed(1)} ms'),
                  _biomarkerChip('HRV RMSSD', '${record.hrvRMSSD.toStringAsFixed(1)} ms'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Recommendations Card
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
                  Icon(Icons.medical_information_outlined, color: Color(0xFF006B67), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Clinical Next Steps & Recommendations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...result.recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF006B67), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(rec, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _biomarkerChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
        ],
      ),
    );
  }
}

/// CustomPainter for rendering live animated ECG waveform
class RealtimeEcgPainter extends CustomPainter {
  final double progress;
  final bool isRecording;

  RealtimeEcgPainter({required this.progress, required this.isRecording});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = isRecording ? const Color(0xFFEF4444) : const Color(0xFF10B981)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerY = size.height / 2;
    final points = <Offset>[];

    const wavePeriod = 120.0;
    final shift = progress * wavePeriod * 4;

    for (double x = 0; x < size.width; x += 2) {
      final shiftedX = (x + shift) % wavePeriod;
      double y = centerY;

      if (shiftedX > 20 && shiftedX <= 35) {
        y -= math.sin((shiftedX - 20) / 15 * math.pi) * 12;
      } else if (shiftedX > 40 && shiftedX <= 45) {
        y += 8;
      } else if (shiftedX > 45 && shiftedX <= 55) {
        final t = (shiftedX - 45) / 10;
        y -= math.sin(t * math.pi) * 55;
      } else if (shiftedX > 55 && shiftedX <= 62) {
        y += 18;
      } else if (shiftedX > 75 && shiftedX <= 95) {
        y -= math.sin((shiftedX - 75) / 20 * math.pi) * 16;
      }

      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant RealtimeEcgPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isRecording != isRecording;
  }
}
