import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ecg_record.dart';
import '../services/csv_file_picker.dart';
import '../services/csv_preprocessing_service.dart';
import '../services/ecg_image_digitizer_service.dart';
import '../services/lstm_model_service.dart';
import '../services/patient_service.dart';
import '../services/pdf_report_service.dart';
import '../widgets/ecg_digitizer_view.dart';
import '../widgets/risk_result_splash_modal.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  int _currentStep = 0; // 0: Input/Upload, 1: Preprocessing & Digitization, 2: LSTM Risk Prediction

  // Input Selection: 0 = Upload ECG Image (Image to Numeric ML), 1 = Upload CSV File
  int _inputMode = 0;

  // Patient metadata for image digitization
  late double _patientAge;
  late bool _patientIsMale;

  // Step 1: Upload state
  bool _isUploading = false;
  String? _uploadError;
  PreprocessingResult? _preprocessingResult;
  DigitizedEcgResult? _digitizedEcgResult;
  int _selectedRecordIndex = 0;

  // Step 2: Preprocessing state
  bool _isPreprocessingRunning = false;
  final List<String> _liveLogs = [];

  // Step 3: Prediction state
  bool _isPredicting = false;
  PredictionResult? _predictionResult;

  @override
  void initState() {
    super.initState();
    final patient = PatientService().patientDetails;
    _patientAge = patient.age.toDouble();
    _patientIsMale = patient.gender.trim().toLowerCase() == 'male';
  }

  // --- Step 1 Actions: ECG Image & CSV Handlers ---

  Future<void> _pickAndUploadEcgImage({ImageSource source = ImageSource.gallery}) async {
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final XFile? file = await EcgImageDigitizerService().pickEcgImage(source: source);
      if (file == null) {
        setState(() => _isUploading = false);
        return;
      }

      await _processEcgImage(xFile: file);
    } catch (e) {
      setState(() {
        _uploadError = 'Failed to load ECG image: ${e.toString()}';
        _isUploading = false;
      });
    }
  }

  Future<void> _processEcgImage({XFile? xFile, EcgImagePreset? preset}) async {
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      Uint8List? bytes;
      String imageName = preset != null ? preset.title : 'Uploaded ECG Image';

      if (xFile != null) {
        bytes = await xFile.readAsBytes();
        imageName = xFile.name;
      }

      final digitized = await EcgImageDigitizerService().processEcgImage(
        imageBytes: bytes,
        imageName: imageName,
        userAge: _patientAge,
        userIsMale: _patientIsMale,
        preset: preset,
      );

      final preResult = PreprocessingResult(
        fileName: imageName,
        totalRows: 1,
        headers: digitized.numericBiomarkers.keys.toList(),
        records: [digitized.patientRecord],
        processingLogs: digitized.digitizationLogs,
        processingTime: const Duration(milliseconds: 380),
      );

      setState(() {
        _inputMode = 0;
        _digitizedEcgResult = digitized;
        _preprocessingResult = preResult;
        _selectedRecordIndex = 0;
        _isUploading = false;
        _uploadError = null;
      });

      _startPreprocessingPipeline();
    } catch (e) {
      setState(() {
        _uploadError = 'Error processing ECG image: ${e.toString()}';
        _isUploading = false;
      });
    }
  }

  Future<void> _pickAndUploadCsv() async {
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final pickedData = await pickCsvFile();

      if (pickedData == null) {
        setState(() => _isUploading = false);
        return;
      }

      final preResult = await CsvPreprocessingService.processCsvString(
        csvContent: pickedData.content,
        fileName: pickedData.fileName,
      );

      if (preResult.records.isEmpty) {
        throw const FormatException('No valid ECG records found in the uploaded CSV.');
      }

      setState(() {
        _inputMode = 1;
        _digitizedEcgResult = null;
        _preprocessingResult = preResult;
        _selectedRecordIndex = 0;
        _isUploading = false;
        _uploadError = null;
      });

      _startPreprocessingPipeline();
    } catch (e) {
      setState(() {
        _uploadError = 'Error reading CSV file: ${e.toString()}';
        _isUploading = false;
      });
    }
  }

  // --- Step 2 Actions: Preprocessing Pipeline ---

  Future<void> _startPreprocessingPipeline() async {
    setState(() {
      _currentStep = 1;
      _isPreprocessingRunning = true;
      _liveLogs.clear();
    });

    final stages = _inputMode == 0
        ? [
            '1. Decoding ECG image pixels & calibrating background lead grid baseline...',
            '2. Extracting trace contours & digitizing waveform pixels to numeric voltage time-series...',
            '3. Performing peak detection algorithm & calculating 48 morphological biomarkers...',
            '4. Normalizing parameters & constructing LSTM sequence tensors [1, 10, 48]...',
          ]
        : [
            '1. Parsing CSV rows & validating schema headers...',
            '2. Inspecting missing values, outliers & signal bounds...',
            '3. Extracting 48 Morphological, Waveform & HRV biomarkers...',
            '4. Normalizing parameters & constructing LSTM sequence tensors [1, 10, 48]...',
          ];

    for (int i = 0; i < stages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _liveLogs.add(stages[i]);
      });
    }

    if (!mounted) return;
    setState(() {
      _isPreprocessingRunning = false;
      _liveLogs.add(_inputMode == 0
          ? '✓ ECG Image digitized successfully into numeric values & biomarker tensors.'
          : '✓ Preprocessing completed for ${_preprocessingResult!.records.length} CSV records.');
    });
  }

  // --- Step 3 Actions: LSTM Prediction ---

  Future<void> _runLstmPrediction() async {
    if (_preprocessingResult == null || _preprocessingResult!.records.isEmpty) return;

    setState(() {
      _isPredicting = true;
    });

    await Future.delayed(const Duration(milliseconds: 450));
    final record = _preprocessingResult!.records[_selectedRecordIndex];
    final prediction = await LstmModelService().predict(record);

    if (!mounted) return;
    setState(() {
      _predictionResult = prediction;
      _isPredicting = false;
      _currentStep = 2;
    });

    // Display the Risk Result Splash Screen modal directly in front of the screen
    showRiskResultSplashModal(
      context,
      predictionResult: prediction,
      record: record,
      onViewDetailsPressed: () {
        setState(() {
          _currentStep = 2;
        });
      },
    );
  }

  void _resetAssessment() {
    setState(() {
      _currentStep = 0;
      _preprocessingResult = null;
      _digitizedEcgResult = null;
      _predictionResult = null;
      _selectedRecordIndex = 0;
      _liveLogs.clear();
    });
  }

  // --- Color and styling helpers ---

  Color _getRiskColor(double risk) {
    if (risk < 0.30) return const Color(0xFF0D9488); // Teal / Emerald Green (Low Risk)
    if (risk < 0.60) return const Color(0xFFD97706); // Golden Amber (Moderate Risk)
    if (risk < 0.80) return const Color(0xFFEA580C); // Deep Orange (Elevated Risk)
    return const Color(0xFFDC2626); // Crimson Red (High Risk)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(
          'Chagas Risk Assessment',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: _resetAssessment,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('New Assessment'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF006B67),
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
                  _buildStepHeader(),
                  const SizedBox(height: 24),
                  if (_currentStep == 0) _buildStep1InputSelection(),
                  if (_currentStep == 1) _buildStep2Preprocessing(),
                  if (_currentStep == 2) _buildStep3PredictionResult(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Step Indicator Header ---

  Widget _buildStepHeader() {
    final steps = [
      {'title': '1. Upload Data', 'icon': Icons.upload_file_rounded},
      {'title': '2. Image & Signal Digitizer', 'icon': Icons.auto_graph_rounded},
      {'title': '3. LSTM Risk Prediction', 'icon': Icons.psychology_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: List.generate(steps.length, (index) {
          final isActive = _currentStep == index;
          final isCompleted = _currentStep > index;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: isCompleted
                        ? () => setState(() => _currentStep = index)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFF006B67)
                                  : isActive
                                      ? const Color(0xFF006B67)
                                      : const Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 18)
                                  : Icon(
                                      steps[index]['icon'] as IconData,
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFF9CA3AF),
                                      size: 16,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              steps[index]['title'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive || isCompleted
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isActive
                                    ? const Color(0xFF006B67)
                                    : isCompleted
                                        ? const Color(0xFF1F2937)
                                        : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 20,
                    height: 2,
                    color: isCompleted
                        ? const Color(0xFF006B67)
                        : const Color(0xFFE5E7EB),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- STEP 1: INPUT SELECTION (ECG Image Digitizer OR CSV File) ---

  Widget _buildStep1InputSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Select Assessment Option',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose your preferred input method to evaluate Chagas disease risk using our LSTM Deep Learning Model.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.4),
        ),
        const SizedBox(height: 20),

        // Mode Switcher Tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _inputMode = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _inputMode == 0 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _inputMode == 0
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_search_rounded,
                          size: 18,
                          color: _inputMode == 0
                              ? const Color(0xFF006B67)
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Upload ECG Image',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _inputMode == 0
                                ? const Color(0xFF006B67)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006B67).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF006B67),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _inputMode = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _inputMode == 1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _inputMode == 1
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_chart_outlined,
                          size: 18,
                          color: _inputMode == 1
                              ? const Color(0xFF006B67)
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Upload CSV Dataset',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _inputMode == 1
                                ? const Color(0xFF006B67)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        if (_inputMode == 0) _buildEcgImageOption(),
        if (_inputMode == 1) _buildCsvDatasetOption(),

        if (_uploadError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _uploadError!,
                    style: const TextStyle(
                        color: Color(0xFF991B1B), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- OPTION 1: ECG IMAGE UPLOAD & DIGITIZATION ---

  Widget _buildEcgImageOption() {
    final patient = PatientService().patientDetails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patient metadata config box from active patient details
        Container(
          padding: const EdgeInsets.all(16),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006B67).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        color: Color(0xFF006B67), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF111827)),
                        ),
                        Text(
                          'Gmail: ${patient.gmailId} • City: ${patient.city}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Age:',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563))),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 60,
                    height: 36,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                          text: _patientAge.toInt().toString()),
                      onChanged: (v) {
                        final d = double.tryParse(v);
                        if (d != null && d > 0) _patientAge = d;
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text('Gender:',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563))),
                  const SizedBox(width: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Male')),
                      ButtonSegment(value: false, label: Text('Female')),
                    ],
                    selected: {_patientIsMale},
                    onSelectionChanged: (set) {
                      setState(() => _patientIsMale = set.first);
                    },
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      selectedBackgroundColor:
                          const Color(0xFF006B67).withValues(alpha: 0.15),
                      selectedForegroundColor: const Color(0xFF006B67),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Main Image Upload Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF006B67).withValues(alpha: 0.35),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF006B67).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
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
                child: const Center(
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    size: 36,
                    color: Color(0xFF006B67),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload ECG Paper Scan / Image Trace',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The Image Digitizer AI extracts numerical voltage signals and 48 biomarkers from ECG photos to feed into the LSTM model.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              if (_isUploading)
                const Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF006B67)),
                    SizedBox(height: 10),
                    Text(
                      'Digitizing image pixels & calculating numeric values...',
                      style: TextStyle(fontSize: 13, color: Color(0xFF006B67), fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickAndUploadEcgImage(source: ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text('Browse ECG Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006B67),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pickAndUploadEcgImage(source: ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Take Photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF006B67),
                        side: const BorderSide(color: Color(0xFF006B67)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --- OPTION 2: CSV DATASET UPLOAD ---

  Widget _buildCsvDatasetOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag & Drop / File selector card
        InkWell(
          onTap: _isUploading ? null : _pickAndUploadCsv,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF006B67).withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF006B67).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
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
                  child: const Center(
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 36,
                      color: Color(0xFF006B67),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Click to Browse or Select CSV File',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Supports .csv format with signals_features columns',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 20),
                if (_isUploading)
                  const CircularProgressIndicator(color: Color(0xFF006B67))
                else
                  ElevatedButton.icon(
                    onPressed: _pickAndUploadCsv,
                    icon: const Icon(Icons.file_open_rounded, size: 18),
                    label: const Text('Select CSV File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006B67),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: PREPROCESSING & DIGITIZATION ---

  Widget _buildStep2Preprocessing() {
    final result = _preprocessingResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _inputMode == 0 ? 'Step 2: ECG Image Digitizer & Feature Extraction' : 'Step 2: Preprocessing & Feature Extraction',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _inputMode == 0
                      ? 'Digitizing image trace lines into numerical values for LSTM ML Model.'
                      : 'Converting raw signals into normalized feature vectors for LSTM Model.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Live Pipeline Execution Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111827), // Dark terminal style
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _isPreprocessingRunning
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPreprocessingRunning
                            ? 'PIPELINE RUNNING...'
                            : 'PIPELINE READY',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _inputMode == 0 ? 'ECG Image Digitizer AI' : 'File: ${result.fileName}',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF374151), height: 1),
              const SizedBox(height: 16),

              // Live Logs output
              ..._liveLogs.map((log) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    log,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      color: Color(0xFFE5E7EB),
                      height: 1.3,
                    ),
                  ),
                );
              }),

              if (_isPreprocessingRunning)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(
                    color: Color(0xFF006B67),
                    backgroundColor: Color(0xFF374151),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (_digitizedEcgResult != null)
          EcgDigitizerView(
            result: _digitizedEcgResult!,
            onReupload: () => setState(() => _currentStep = 0),
          ),

        const SizedBox(height: 24),

        // Action button to trigger LSTM Prediction
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isPreprocessingRunning || _isPredicting
                ? null
                : _runLstmPrediction,
            icon: _isPredicting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.psychology_rounded, size: 22),
            label: Text(
              _isPredicting
                  ? 'Analyzing in LSTM Model...'
                  : 'Analyze Numeric Values in LSTM Model',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006B67),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 3: PREDICTION RESULTS ---

  Widget _buildStep3PredictionResult() {
    final pred = _predictionResult!;
    final riskColor = _getRiskColor(pred.riskScore);
    final riskPercent = (pred.riskScore * 100).toStringAsFixed(1);
    final confidencePercent = (pred.confidence * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Step 3: LSTM Model Chagas Risk Prediction',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    showRiskResultSplashModal(
                      context,
                      predictionResult: pred,
                      record: pred.patientRecord,
                      onViewDetailsPressed: () {
                        setState(() {
                          _currentStep = 2;
                        });
                      },
                    );
                  },
                  icon: const Icon(Icons.fullscreen_rounded, size: 18),
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
                        predictionResult: pred,
                        record: pred.patientRecord,
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
                OutlinedButton.icon(
                  onPressed: _resetAssessment,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Restart'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF006B67),
                    side: const BorderSide(color: Color(0xFF006B67)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Main Risk Gauge Card - PLACED PROMINENTLY AT THE TOP FRONT OF THE PAGE
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                riskColor.withValues(alpha: 0.12),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: riskColor.withValues(alpha: 0.4),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: riskColor.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.psychology_rounded, size: 14, color: riskColor),
                        const SizedBox(width: 6),
                        Text(
                          'LSTM Recurrent Neural Network',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Exam #${pred.patientRecord.examId}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: pred.riskScore,
                      strokeWidth: 12,
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
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: riskColor,
                        ),
                      ),
                      const Text(
                        'Risk Probability',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pred.riskCategory.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Model Confidence: $confidencePercent% • Sequence Tensors: 10 Time Steps',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // If ECG Image mode, display the Digitized ECG summary banner
        if (_digitizedEcgResult != null) ...[
          EcgDigitizerView(result: _digitizedEcgResult!),
          const SizedBox(height: 24),
        ],

        // Explainable AI: Contributing Biomarkers
        const Text(
          'Biomarker Impact Analysis (Explainable AI)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Detailed physiological factors derived from the numerical ECG parameters that influenced the LSTM prediction.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 14),

        ...pred.topBiomarkers.map((bio) {
          final isHighRisk = bio.riskImpact > 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isHighRisk
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          color: isHighRisk
                              ? const Color(0xFFF97316)
                              : const Color(0xFF10B981),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          bio.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${bio.rawValue.toStringAsFixed(1)} ${bio.unit}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  bio.statusDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),

        // Clinical Recommendations
        Container(
          padding: const EdgeInsets.all(22),
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
                  Icon(Icons.medical_services_outlined,
                      color: Color(0xFF006B67), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Recommended Clinical Next Steps',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...pred.recommendations.map((rec) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF006B67),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          rec,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF374151),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Action Buttons: Assess Next Record / Upload New File
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetAssessment,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Start New Assessment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF006B67),
                  side: const BorderSide(color: Color(0xFF006B67)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
