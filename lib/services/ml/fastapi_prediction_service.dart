import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:chagas_predictor/models/ecg_record.dart';
import 'package:chagas_predictor/services/ml/lstm_model_service.dart';
import 'package:chagas_predictor/services/ml/ecg_image_digitizer_service.dart';
import 'package:chagas_predictor/services/ml/csv_preprocessing_service.dart';

class FastApiPredictionService {
  static const String baseUrl = 'http://localhost:8000';

  /// Check if the FastAPI backend server is online & reachable
  static Future<bool> isServerOnline() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Send patient record to FastAPI server for AI inference (with local LSTM fallback)
  static Future<PredictionResult> predictRecord(EcgPatientRecord record) async {
    try {
      final vec49 = CsvPreprocessingService.extract49FeatureVector(record);
      final names = CsvPreprocessingService.expectedFeatures;
      final payload = <String, dynamic>{};
      for (int i = 0; i < names.length && i < vec49.length; i++) {
        payload[names[i]] = vec49[i];
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final score = (data['risk_score_percentage'] as num).toDouble() / 100.0;
        final category = data['risk_category'] as String;

        final localRes = await LstmModelService().predict(record);
        return PredictionResult(
          patientRecord: record,
          riskScore: score,
          riskCategory: category,
          confidence: (data['confidence'] as num).toDouble(),
          topBiomarkers: localRes.topBiomarkers,
          recommendations: localRes.recommendations,
          extractedNormalizedVector: localRes.extractedNormalizedVector,
        );
      } else {
        return LstmModelService().predict(record);
      }
    } catch (e) {
      print('HTTP error calling FastAPI backend ($e). Falling back to local model engine.');
      return LstmModelService().predict(record);
    }
  }

  /// Upload raw CSV file bytes to FastAPI /api/predict endpoint
  static Future<PredictionResult> predictCsvBytes({
    required List<int> bytes,
    required String fileName,
    required EcgPatientRecord fallbackRecord,
  }) async {
    final online = await isServerOnline();
    if (!online) {
      return LstmModelService().predict(fallbackRecord);
    }

    try {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/predict'));
      req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

      final streamedRes = await req.send();
      final response = await http.Response.fromStream(streamedRes);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final score = (data['risk_score_percentage'] as num).toDouble() / 100.0;
        final category = data['risk_category'] as String;

        final localRes = await LstmModelService().predict(fallbackRecord);
        return PredictionResult(
          patientRecord: fallbackRecord,
          riskScore: score,
          riskCategory: category,
          confidence: (data['confidence'] as num).toDouble(),
          topBiomarkers: localRes.topBiomarkers,
          recommendations: localRes.recommendations,
          extractedNormalizedVector: localRes.extractedNormalizedVector,
        );
      } else {
        return LstmModelService().predict(fallbackRecord);
      }
    } catch (e) {
      print('Error uploading CSV to FastAPI: $e');
      return LstmModelService().predict(fallbackRecord);
    }
  }
}
