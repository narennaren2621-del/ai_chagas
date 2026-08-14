import 'dart:math' as math;

// Feature extraction service to convert patient data to ML model features
class FeatureExtractionService {
  // Extract 49 features from patient data
  // These match the features your LSTM/Dense model was trained on
  static List<double> extractFeaturesFromPatientData({
    required int age,
    required String gender,
    required String city,
    required int heartRate,
    required double bpSystolic,
    required double bpDiastolic,
    List<double>? ecgSignals, // Optional ECG signal data
  }) {
    // Initialize 49 features
    List<double> features = List<double>.filled(49, 0.0);

    // 1-5: Basic patient info features
    features[0] = (age / 100.0); // Normalize age
    features[1] = (gender == 'Male' ? 1.0 : 0.0); // Gender encoding
    features[2] = (gender == 'Female' ? 1.0 : 0.0);
    features[3] = (gender == 'Other' ? 1.0 : 0.0);

    // 5-8: Heart rate features
    features[4] = (heartRate / 200.0); // Normalize heart rate
    features[5] = _calculateHeartRateVariability(heartRate);
    features[6] = _normalizeHeartRate(heartRate);
    features[7] = _getHeartRateCategory(heartRate);

    // 8-15: Blood pressure features
    features[8] = (bpSystolic / 200.0); // Normalize systolic
    features[9] = (bpDiastolic / 130.0); // Normalize diastolic
    features[10] = ((bpSystolic - bpDiastolic) / 100.0); // Pulse pressure
    features[11] = ((bpSystolic + 2 * bpDiastolic) / 3 / 130.0); // Mean arterial pressure
    features[12] = _calculateBPVariability(bpSystolic, bpDiastolic);
    features[13] = _getBPCategory(bpSystolic, bpDiastolic);
    features[14] = _getRiskFromBP(bpSystolic);

    // 15-25: ECG-derived features (if available)
    if (ecgSignals != null && ecgSignals.isNotEmpty) {
      features[15] = _calculateMean(ecgSignals);
      features[16] = _calculateStd(ecgSignals);
      features[17] = _calculateMax(ecgSignals);
      features[18] = _calculateMin(ecgSignals);
      features[19] = _calculateRMS(ecgSignals);
      features[20] = _calculateSkewness(ecgSignals);
      features[21] = _calculateKurtosis(ecgSignals);
      features[22] = _calculatePeakCount(ecgSignals);
      features[23] = _calculateCrestFactor(ecgSignals);
    } else {
      // Default ECG features if not provided
      features[15] = 0.5;
      features[16] = 0.5;
      features[17] = 0.5;
      features[18] = 0.5;
      features[19] = 0.5;
      features[20] = 0.0;
      features[21] = 0.0;
      features[22] = 0.3;
      features[23] = 0.5;
    }

    // 24-35: Risk factor encoding
    features[24] = _getRiskScore(age, heartRate); // Age + HR risk
    features[25] = _getChronicDiseaseRisk(age); // Chronic disease probability
    features[26] = _getSymptomsRisk(age, heartRate, bpSystolic);
    features[27] = _calculateComorbidityIndex(age, bpSystolic);
    features[28] = _getLifestyleRisk(age);
    features[29] = _calculateCardiacStress(heartRate, bpSystolic, bpDiastolic);

    // 30-40: Normalized features
    features[30] = _normalizeAge(age);
    features[31] = _normalizeHeartRate(heartRate);
    features[32] = _normalizeBP(bpSystolic);
    features[33] = (bpDiastolic / 130.0);

    // 40-49: Additional derived features
    features[34] = _calculateHeartRateIndex(heartRate, bpSystolic);
    features[35] = _calculateVascularRiskScore(age, bpSystolic, bpDiastolic);
    features[36] = _getAgeGroup(age);
    features[37] = _getHeartRateVariabilityIndex(heartRate);
    features[38] = _calculateOverallRiskFactor(age, heartRate, bpSystolic, bpDiastolic);
    features[39] = _getPrognosticScore(age, heartRate, bpSystolic);

    // Fill remaining features with normalized values
    for (int i = 40; i < 49; i++) {
      features[i] = _calculateFeatureByIndex(i, age, heartRate, bpSystolic, bpDiastolic);
    }

    return features;
  }

  // Helper functions for feature calculation

  static double _calculateHeartRateVariability(int heartRate) {
    // Estimate HRV (0.0 - 1.0)
    if (heartRate < 60) return 0.8;
    if (heartRate < 100) return 0.6;
    if (heartRate < 120) return 0.4;
    return 0.2;
  }

  static double _normalizeHeartRate(int heartRate) {
    return (heartRate / 200.0).clamp(0.0, 1.0);
  }

  static double _getHeartRateCategory(int heartRate) {
    if (heartRate < 60) return 0.1; // Bradycardia
    if (heartRate < 100) return 0.3; // Normal
    if (heartRate < 120) return 0.6; // Tachycardia
    return 0.9; // Severe tachycardia
  }

  static double _calculateBPVariability(double systolic, double diastolic) {
    return ((systolic - diastolic) / 200.0).clamp(0.0, 1.0);
  }

  static double _getBPCategory(double systolic, double diastolic) {
    if (systolic < 120 && diastolic < 80) return 0.1; // Normal
    if (systolic < 130 && diastolic < 80) return 0.3; // Elevated
    if (systolic < 140 || diastolic < 90) return 0.5; // Stage 1 Hypertension
    return 0.8; // Stage 2 Hypertension
  }

  static double _getRiskFromBP(double systolic) {
    if (systolic < 120) return 0.1;
    if (systolic < 140) return 0.4;
    if (systolic < 160) return 0.7;
    return 0.9;
  }

  static double _calculateMean(List<double> data) {
    if (data.isEmpty) return 0.0;
    return data.reduce((a, b) => a + b) / data.length;
  }

  static double _calculateStd(List<double> data) {
    if (data.isEmpty) return 0.0;
    double mean = _calculateMean(data);
    double variance = data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / data.length;
    return (math.sqrt(variance) / 100).clamp(0.0, 1.0); // Normalize
  }

  static double _calculateMax(List<double> data) {
    return (data.isEmpty ? 0.0 : data.reduce((a, b) => a > b ? a : b)) / 1000;
  }

  static double _calculateMin(List<double> data) {
    return (data.isEmpty ? 0.0 : data.reduce((a, b) => a < b ? a : b)) / 1000;
  }

  static double _calculateRMS(List<double> data) {
    if (data.isEmpty) return 0.0;
    double sum = data.map((x) => x * x).reduce((a, b) => a + b);
    return math.sqrt(sum / data.length) / 100;
  }

  static double _calculateSkewness(List<double> data) {
    if (data.length < 3) return 0.0;
    double mean = _calculateMean(data);
    double n = data.length.toDouble();
    double m3 = data.map((x) => (x - mean) * (x - mean) * (x - mean)).reduce((a, b) => a + b) / n;
    double m2 = data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / n;
    return (m3 / (m2 * math.sqrt(m2))).abs().clamp(-1.0, 1.0) / 2 + 0.5;
  }

  static double _calculateKurtosis(List<double> data) {
    if (data.length < 4) return 0.0;
    double mean = _calculateMean(data);
    double n = data.length.toDouble();
    double m4 = data.map((x) => (x - mean) * (x - mean) * (x - mean) * (x - mean)).reduce((a, b) => a + b) / n;
    double m2 = data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / n;
    return (m4 / (m2 * m2)).clamp(0.0, 5.0) / 5;
  }

  static double _calculatePeakCount(List<double> data) {
    if (data.length < 3) return 0.0;
    int peaks = 0;
    for (int i = 1; i < data.length - 1; i++) {
      if (data[i] > data[i - 1] && data[i] > data[i + 1]) peaks++;
    }
    return (peaks / data.length).clamp(0.0, 1.0);
  }

  static double _calculateCrestFactor(List<double> data) {
    if (data.isEmpty) return 0.0;
    double max = _calculateMax(data) * 1000;
    double rms = _calculateRMS(data) * 100;
    if (rms == 0) return 0.0;
    return (max / rms).clamp(0.0, 10.0) / 10;
  }

  static double _getRiskScore(int age, int heartRate) {
    double ageRisk = (age / 120.0).clamp(0.0, 1.0);
    double hrRisk = ((heartRate - 60).abs() / 100.0).clamp(0.0, 1.0);
    return (ageRisk + hrRisk) / 2;
  }

  static double _getChronicDiseaseRisk(int age) {
    if (age < 30) return 0.05;
    if (age < 50) return 0.2;
    if (age < 70) return 0.5;
    return 0.8;
  }

  static double _getSymptomsRisk(int age, int heartRate, double bpSystolic) {
    double risk = 0.0;
    if (heartRate > 100) risk += 0.3;
    if (bpSystolic > 140) risk += 0.3;
    if (age > 60) risk += 0.2;
    return risk.clamp(0.0, 1.0);
  }

  static double _calculateComorbidityIndex(int age, double bpSystolic) {
    double index = 0.0;
    if (age > 50) index += 0.2;
    if (bpSystolic > 140) index += 0.3;
    return index.clamp(0.0, 1.0);
  }

  static double _getLifestyleRisk(int age) {
    // Simplified lifestyle risk based on age
    if (age < 40) return 0.2;
    if (age < 60) return 0.4;
    return 0.6;
  }

  static double _calculateCardiacStress(int heartRate, double bpSystolic, double bpDiastolic) {
    double stress = (heartRate / 100.0) * 0.4;
    stress += (bpSystolic / 200.0) * 0.3;
    stress += ((bpSystolic - bpDiastolic) / 100.0) * 0.3;
    return stress.clamp(0.0, 1.0);
  }

  static double _normalizeAge(int age) {
    return (age / 120.0).clamp(0.0, 1.0);
  }

  static double _normalizeBP(double bpSystolic) {
    return (bpSystolic / 200.0).clamp(0.0, 1.0);
  }

  static double _calculateHeartRateIndex(int heartRate, double bpSystolic) {
    return ((heartRate * bpSystolic) / 20000.0).clamp(0.0, 1.0);
  }

  static double _calculateVascularRiskScore(int age, double bpSystolic, double bpDiastolic) {
    double score = 0.0;
    score += (age / 120.0) * 0.5;
    score += (bpSystolic / 200.0) * 0.3;
    score += ((bpSystolic - bpDiastolic) / 100.0) * 0.2;
    return score.clamp(0.0, 1.0);
  }

  static double _getAgeGroup(int age) {
    if (age < 30) return 0.1;
    if (age < 45) return 0.3;
    if (age < 60) return 0.5;
    if (age < 75) return 0.7;
    return 0.9;
  }

  static double _getHeartRateVariabilityIndex(int heartRate) {
    if (heartRate < 50) return 0.9;
    if (heartRate < 70) return 0.7;
    if (heartRate < 100) return 0.5;
    return 0.2;
  }

  static double _calculateOverallRiskFactor(int age, int heartRate, double bpSystolic, double bpDiastolic) {
    double risk = 0.0;
    risk += _normalizeAge(age) * 0.3;
    risk += _normalizeHeartRate(heartRate) * 0.3;
    risk += _normalizeBP(bpSystolic) * 0.4;
    return risk.clamp(0.0, 1.0);
  }

  static double _getPrognosticScore(int age, int heartRate, double bpSystolic) {
    return (_normalizeAge(age) + _normalizeHeartRate(heartRate) + _normalizeBP(bpSystolic)) / 3;
  }

  static double _calculateFeatureByIndex(int index, int age, int heartRate, double bpSystolic, double bpDiastolic) {
    switch (index % 9) {
      case 0:
        return _normalizeAge(age);
      case 1:
        return _normalizeHeartRate(heartRate);
      case 2:
        return _normalizeBP(bpSystolic);
      case 3:
        return (bpDiastolic / 130.0).clamp(0.0, 1.0);
      case 4:
        return _getRiskScore(age, heartRate);
      case 5:
        return _getChronicDiseaseRisk(age);
      case 6:
        return _calculateCardiacStress(heartRate, bpSystolic, bpDiastolic);
      case 7:
        return _calculateComorbidityIndex(age, bpSystolic);
      case 8:
        return _calculateOverallRiskFactor(age, heartRate, bpSystolic, bpDiastolic);
      default:
        return 0.5;
    }
  }
}
