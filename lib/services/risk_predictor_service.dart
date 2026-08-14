import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/training_data.dart';

/// Loads the supplied training data packaged inside the app assets.
///
/// The CSV is an app asset: no upload, API call, or external data service is
/// used at runtime. The selected columns match the assessment form.
Future<List<TrainingData>> loadTrainingDataset() async {
  final csv = await rootBundle.loadString('assets/data/signals_features.csv');
  final lines = const LineSplitter().convert(csv);
  if (lines.length < 2) return const [];

  final headers = lines.first.split(',');
  int column(String name) => headers.indexOf(name);
  final ageColumn = column('age');
  final sexColumn = column('is_male');
  final pWaveColumn = column('P_wave_duration_mean');
  final hrvColumn = column('HRV_SDNN');
  final labelColumn = column('chagas');
  if ([ageColumn, sexColumn, pWaveColumn, hrvColumn, labelColumn]
      .any((index) => index < 0)) {
    throw const FormatException('The bundled dataset is missing required columns.');
  }

  final data = <TrainingData>[];
  for (final line in lines.skip(1)) {
    if (line.trim().isEmpty) continue;
    final values = line.split(',');
    if (values.length != headers.length) continue;
    final age = double.tryParse(values[ageColumn]);
    final pWave = double.tryParse(values[pWaveColumn]);
    final hrv = double.tryParse(values[hrvColumn]);
    if (age == null || pWave == null || hrv == null) continue;

    data.add(TrainingData(
      features: [
        age,
        values[sexColumn].trim().toLowerCase() == 'true' ? 1.0 : 0.0,
        pWave,
        hrv,
      ],
      label: values[labelColumn].trim().toLowerCase() == 'true' ? 1.0 : 0.0,
    ));
  }
  return data;
}

class SimpleRiskModel {
  final List<TrainingData> trainingData;
  late final List<double> featureMeans;

  SimpleRiskModel(this.trainingData) {
    train();
  }

  void train() {
    if (trainingData.isEmpty) {
      featureMeans = [];
      return;
    }

    final dim = trainingData.first.features.length;
    featureMeans = List.filled(dim, 0.0);

    for (final sample in trainingData) {
      for (var i = 0; i < dim; i++) {
        featureMeans[i] += sample.features[i];
      }
    }

    for (var i = 0; i < dim; i++) {
      featureMeans[i] /= trainingData.length;
    }
  }

  double predict(List<double> features) {
    if (features.length != featureMeans.length || trainingData.isEmpty) {
      return 0.0;
    }

    final best = trainingData.reduce((a, b) {
      final da = _distance(a.features, features, featureMeans);
      final db = _distance(b.features, features, featureMeans);
      return da < db ? a : b;
    });

    return best.label;
  }

  static double _distance(
      List<double> a, List<double> b, List<double> featureMeans) {
    var sum = 0.0;
    for (var i = 0; i < a.length && i < b.length; i++) {
      final diff = (a[i] - b[i]) / (featureMeans[i].abs() + 1);
      sum += diff * diff;
    }
    return sum;
  }
}
