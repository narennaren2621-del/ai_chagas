import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chagas_predictor/firebase_options.dart';
import 'package:chagas_predictor/config/app_theme.dart';
import 'package:chagas_predictor/pages/auth/auth_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }
  runApp(const ChagasPredictorApp());
}

class ChagasPredictorApp extends StatelessWidget {
  const ChagasPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chagas Predict',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthPage(),
    );
  }
}
