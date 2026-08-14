class EcgPatientRecord {
  final String examId;
  final double age;
  final bool isMale;
  final double pWaveDurationMean;
  final double pWaveDurationStd;
  final double prIntervalMean;
  final double prSegmentMean;
  final double qrsDurationMean;
  final double qtIntervalMean;
  final double stSegmentMean;
  final double stSlopeMean;
  final double hrvMeanNN;
  final double hrvSDNN;
  final double hrvRMSSD;
  final double hrvCVNN;
  final double hrvMedianNN;
  final double hrvPNN50;
  final double hrvPNN20;
  final bool? actualLabel;
  final Map<String, double> allFeatures;

  const EcgPatientRecord({
    required this.examId,
    required this.age,
    required this.isMale,
    required this.pWaveDurationMean,
    required this.pWaveDurationStd,
    required this.prIntervalMean,
    required this.prSegmentMean,
    required this.qrsDurationMean,
    required this.qtIntervalMean,
    required this.stSegmentMean,
    required this.stSlopeMean,
    required this.hrvMeanNN,
    required this.hrvSDNN,
    required this.hrvRMSSD,
    required this.hrvCVNN,
    required this.hrvMedianNN,
    required this.hrvPNN50,
    required this.hrvPNN20,
    this.actualLabel,
    required this.allFeatures,
  });

  factory EcgPatientRecord.fromMap(Map<String, String> row, {int index = 0}) {
    double parseD(String key, [double fallback = 0.0]) {
      final v = row[key];
      if (v == null) return fallback;
      return double.tryParse(v.trim()) ?? fallback;
    }

    bool parseB(String key, [bool fallback = false]) {
      final v = row[key]?.trim().toLowerCase();
      if (v == null) return fallback;
      return v == 'true' || v == '1' || v == 'yes' || v == 'male';
    }

    final id = row['exam_id']?.trim() ??
        row['id']?.trim() ??
        row['patient_id']?.trim() ??
        'REC-${index + 1001}';

    final ageVal = parseD('age', parseD('Age', 45.0));
    final isMaleVal = parseB('is_male', parseB('gender', true));
    final pWaveMean = parseD('P_wave_duration_mean', parseD('p_wave', 50.0));
    final pWaveStd = parseD('P_wave_duration_std', 8.0);
    final prIntMean = parseD('PR_interval_mean', parseD('pr_interval', 140.0));
    final prSegMean = parseD('PR_segment_mean', 80.0);
    final qrsMean = parseD('QRS_duration_mean', parseD('qrs_duration', 88.0));
    final qtMean = parseD('QT_interval_mean', parseD('qt_interval', 340.0));
    final stMean = parseD('ST_segment_mean', parseD('st_segment', 180.0));
    final stSlope = parseD('ST_slope_mean', 0.0035);
    final hrvMean = parseD('HRV_MeanNN', parseD('mean_nn', 820.0));
    final hrvSd = parseD('HRV_SDNN', parseD('sdnn', parseD('hrv', 45.0)));
    final hrvRms = parseD('HRV_RMSSD', parseD('rmssd', 35.0));
    final hrvCv = parseD('HRV_CVNN', 0.045);
    final hrvMed = parseD('HRV_MedianNN', 815.0);
    final hrvP50 = parseD('HRV_pNN50', parseD('pnn50', 12.0));
    final hrvP20 = parseD('HRV_pNN20', 25.0);

    bool? chagasLabel;
    if (row.containsKey('chagas') || row.containsKey('label')) {
      chagasLabel = parseB('chagas', parseB('label', false));
    }

    final featureMap = <String, double>{};
    row.forEach((key, val) {
      final numVal = double.tryParse(val.trim());
      if (numVal != null) {
        featureMap[key] = numVal;
      }
    });

    return EcgPatientRecord(
      examId: id,
      age: ageVal,
      isMale: isMaleVal,
      pWaveDurationMean: pWaveMean,
      pWaveDurationStd: pWaveStd,
      prIntervalMean: prIntMean,
      prSegmentMean: prSegMean,
      qrsDurationMean: qrsMean,
      qtIntervalMean: qtMean,
      stSegmentMean: stMean,
      stSlopeMean: stSlope,
      hrvMeanNN: hrvMean,
      hrvSDNN: hrvSd,
      hrvRMSSD: hrvRms,
      hrvCVNN: hrvCv,
      hrvMedianNN: hrvMed,
      hrvPNN50: hrvP50,
      hrvPNN20: hrvP20,
      actualLabel: chagasLabel,
      allFeatures: featureMap,
    );
  }
}

class PreprocessingResult {
  final String fileName;
  final int totalRows;
  final List<String> headers;
  final List<EcgPatientRecord> records;
  final List<String> processingLogs;
  final Duration processingTime;

  const PreprocessingResult({
    required this.fileName,
    required this.totalRows,
    required this.headers,
    required this.records,
    required this.processingLogs,
    required this.processingTime,
  });
}

class PredictionResult {
  final EcgPatientRecord patientRecord;
  final double riskScore; // 0.0 to 1.0
  final String riskCategory; // Low, Moderate, High, Critical
  final double confidence;
  final List<BiomarkerContribution> topBiomarkers;
  final List<String> recommendations;
  final List<double> extractedNormalizedVector;

  const PredictionResult({
    required this.patientRecord,
    required this.riskScore,
    required this.riskCategory,
    required this.confidence,
    required this.topBiomarkers,
    required this.recommendations,
    required this.extractedNormalizedVector,
  });
}

class BiomarkerContribution {
  final String name;
  final String category;
  final double rawValue;
  final String unit;
  final double riskImpact; // -1.0 (protective) to +1.0 (elevates risk)
  final String statusDescription;

  const BiomarkerContribution({
    required this.name,
    required this.category,
    required this.rawValue,
    required this.unit,
    required this.riskImpact,
    required this.statusDescription,
  });
}
