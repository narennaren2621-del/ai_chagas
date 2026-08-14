import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'pages/auth_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
