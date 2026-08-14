# ML Model Integration Guide - Chagas Predictor App

## Overview
Integrating your TensorFlow Chagas prediction model into the Flutter app with 3 components:
1. **ML Model Service** - Loads and runs the TFLite model
2. **Feature Extraction Service** - Converts patient data to 49 features
3. **Model Assets** - TensorFlow Lite model file

---

## Implementation Steps

### STEP 1: Convert Your Model to TFLite (Python)
```bash
# Navigate to your AI project
cd c:\Users\acer\Desktop\chagas_ai

# Run the conversion script
python convert_to_tflite.py
```

**Expected Output:**
```
✓ Model converted successfully!
✓ Saved to: c:\Users\acer\Desktop\chagas_ai\flutter_model\chagas_model.tflite
✓ Model size: ~150 KB
```

---

### STEP 2: Copy Model to Flutter Assets
```bash
# Create assets folder if it doesn't exist
mkdir d:\final_chagas_app\assets\models

# Copy the TFLite model
copy c:\Users\acer\Desktop\chagas_ai\flutter_model\chagas_model.tflite d:\final_chagas_app\assets\models\
```

---

### STEP 3: Install Dependencies
In VS Code terminal:
```bash
# Navigate to Flutter project
cd d:\final_chagas_app

# Update pubspec.yaml with tflite_flutter
flutter pub get
```

---

### STEP 4: Use in Your App

#### Example: In Prediction Page
```dart
import 'package:flutter/material.dart';
import '../services/ml_model_service.dart';
import '../services/feature_extraction_service.dart';
import '../models/user_profile.dart';

class PredictionPage extends StatefulWidget {
  final UserProfile profile;
  final PatientDetails patientDetails;

  const PredictionPage({
    required this.profile,
    required this.patientDetails,
    super.key,
  });

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  double? _riskScore;
  bool _isLoading = false;

  void _calculateRisk() async {
    setState(() => _isLoading = true);

    try {
      // Extract features from patient data
      List<double> features = FeatureExtractionService.extractFeaturesFromPatientData(
        age: widget.patientDetails.age,
        gender: widget.patientDetails.gender,
        city: widget.patientDetails.city,
        heartRate: 75, // Get from input
        bpSystolic: 120, // Get from input
        bpDiastolic: 80, // Get from input
      );

      // Get risk prediction
      double risk = await MLModelService().predictRisk(features);

      setState(() {
        _riskScore = risk;
        _isLoading = false;
      });

      // Show result
      _showRiskResult(risk);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _showRiskResult(double riskScore) {
    String category = MLModelService().getRiskCategory(riskScore);
    String percentage = '${(riskScore * 100).toStringAsFixed(1)}%';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Risk Assessment Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Risk Score: $percentage', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Category: $category', style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Risk Prediction')),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _calculateRisk,
                child: Text('Calculate Chagas Risk'),
              ),
      ),
    );
  }
}
```

---

## Feature Extraction Explanation

### 49 Features Extracted:
**Group 1: Patient Info (Features 0-4)**
- Normalized age
- Gender (Male/Female/Other)
- Heart rate features

**Group 2: Blood Pressure (Features 5-14)**
- Systolic/Diastolic BP
- Mean arterial pressure
- BP variability and risk categories

**Group 3: ECG-Derived (Features 15-23)**
- Statistical measures (mean, std, max, min, RMS)
- Skewness, Kurtosis
- Peak count, Crest factor

**Group 4: Risk Factors (Features 24-39)**
- Overall risk score
- Chronic disease risk
- Cardiac stress index
- Comorbidity index

**Group 5: Derived Features (Features 40-48)**
- Age groups, HR variability index
- Prognostic scores

---

## Risk Categories

| Risk Score | Category | Color |
|-----------|----------|-------|
| 0.0 - 0.3 | Low Risk | 🟢 Green |
| 0.3 - 0.6 | Medium Risk | 🟡 Amber |
| 0.6 - 0.8 | High Risk | 🟠 Orange |
| 0.8 - 1.0 | Critical Risk | 🔴 Red |

---

## Testing the Integration

### Test Code:
```dart
// Test in main.dart or anywhere
void testMLModel() async {
  try {
    // Initialize
    await MLModelService().initializeModel();
    print('✓ Model initialized');

    // Extract test features
    List<double> testFeatures = FeatureExtractionService.extractFeaturesFromPatientData(
      age: 45,
      gender: 'Male',
      city: 'São Paulo',
      heartRate: 78,
      bpSystolic: 130,
      bpDiastolic: 85,
    );

    // Predict
    double risk = await MLModelService().predictRisk(testFeatures);
    String category = MLModelService().getRiskCategory(risk);

    print('Risk Score: ${(risk * 100).toStringAsFixed(1)}%');
    print('Category: $category');
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## Troubleshooting

### Issue: "Model not found"
**Solution:** Ensure `assets/models/chagas_model.tflite` exists

### Issue: "Input shape mismatch"
**Solution:** Verify features are exactly 49 elements

### Issue: "Null output"
**Solution:** Check model is initialized before calling `predictRisk()`

### Issue: "tflite_flutter error on iOS"
**Solution:** Run `flutter clean` and rebuild

---

## Performance Tips

1. **Initialize model once** - Use singleton pattern (already implemented)
2. **Cache features** - Avoid recalculating same features
3. **Batch predictions** - Use `predictBatch()` for multiple patients
4. **Offload to API** - For production, consider calling a server

---

## Next Steps

1. ✅ Convert model to TFLite
2. ✅ Copy model to Flutter assets
3. ✅ Run `flutter pub get`
4. ✅ Hot reload: press `r` in terminal
5. ✅ Test with patient data
6. ✅ Integrate with Prediction Page

---

## Questions?

Refer to:
- `lib/services/ml_model_service.dart` - Model loading and prediction
- `lib/services/feature_extraction_service.dart` - Feature engineering
- `lib/main.dart` - Model initialization

Good luck! 🚀
