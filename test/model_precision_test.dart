import 'package:flutter_test/flutter_test.dart';
import 'package:chagas_predictor/models/ecg_record.dart';
import 'package:chagas_predictor/services/ml/lstm_model_service.dart';

void main() {
  test('LSTM Model evaluates distinct risk scores for healthy vs severe Chagas patients', () async {
    final healthyRecord = EcgPatientRecord(
      examId: 'TEST-HEALTHY',
      age: 28,
      isMale: true,
      pWaveDurationMean: 42.0,
      pWaveDurationStd: 5.0,
      prIntervalMean: 110.0,
      prSegmentMean: 50.0,
      qrsDurationMean: 50.0,
      qtIntervalMean: 310.0,
      stSegmentMean: 190.0,
      stSlopeMean: 0.002,
      hrvMeanNN: 850.0,
      hrvSDNN: 65.0,
      hrvRMSSD: 55.0,
      hrvCVNN: 0.07,
      hrvMedianNN: 845.0,
      hrvPNN50: 25.0,
      hrvPNN20: 35.0,
      allFeatures: const {},
    );

    final severeRecord = EcgPatientRecord(
      examId: 'TEST-SEVERE',
      age: 72,
      isMale: false,
      pWaveDurationMean: 75.0,
      pWaveDurationStd: 12.0,
      prIntervalMean: 195.0,
      prSegmentMean: 95.0,
      qrsDurationMean: 115.0,
      qtIntervalMean: 390.0,
      stSegmentMean: 240.0,
      stSlopeMean: 0.008,
      hrvMeanNN: 920.0,
      hrvSDNN: 14.0,
      hrvRMSSD: 12.0,
      hrvCVNN: 0.015,
      hrvMedianNN: 915.0,
      hrvPNN50: 2.0,
      hrvPNN20: 5.0,
      allFeatures: const {},
    );

    final healthyPred = await LstmModelService().predict(healthyRecord);
    final severePred = await LstmModelService().predict(severeRecord);

    print('Healthy Risk Score: ${(healthyPred.riskScore * 100).toStringAsFixed(1)}% (${healthyPred.riskCategory})');
    print('Severe Risk Score: ${(severePred.riskScore * 100).toStringAsFixed(1)}% (${severePred.riskCategory})');

    expect(healthyPred.riskScore, lessThan(0.30));
    expect(severePred.riskScore, greaterThan(0.65));
  });
}
