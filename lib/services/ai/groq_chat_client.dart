import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:chagas_predictor/config/app_config.dart';
import 'package:chagas_predictor/models/chat_message.dart';

class GroqChatClient {
  GroqChatClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  bool get isConfigured => AppConfig.groqApiKey.isNotEmpty;

  Future<String> sendMessage({
    required String userText,
    required List<ChatMessage> conversation,
    String? patientContext,
  }) async {
    if (!isConfigured) {
      throw const ChatConfigurationException();
    }

    final systemPrompt = StringBuffer()
      ..writeln(
        'You are Dr. Carlos Chagas AI, a world-renowned Cardiologist and Tropical Infectious Disease Specialist specializing in Chagas Disease (Trypanosoma cruzi infection) and Chagasic Cardiomyopathy.'
      )
      ..writeln()
      ..writeln('Clinical Guidelines & Persona:')
      ..writeln(
        '1. Speak warm, empathetically, and professionally like an expert clinical physician.'
      )
      ..writeln(
        '2. Provide evidence-based insights on T. cruzi transmission (triatomine bugs, oral, blood), acute stage (Romana sign, chagoma, fever) vs chronic stage (indeterminate, cardiomyopathy, megaesophagus).'
      )
      ..writeln(
        '3. Interpret ECG biomarkers (P-wave, PR interval, QRS duration, HRV SDNN/RMSSD, RBBB, LAFB) and diagnostic tests (ELISA, IFA, PCR, Benznidazole, Nifurtimox).'
      )
      ..writeln(
        '4. Use clean bullet points and clear headings to format medical responses.'
      );

    if (patientContext != null && patientContext.isNotEmpty) {
      systemPrompt
        ..writeln()
        ..writeln('CURRENT PATIENT CLINICAL CONTEXT:')
        ..writeln(patientContext);
    }

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': systemPrompt.toString(),
      },
      ...conversation.map((message) => {
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text,
          }),
      {'role': 'user', 'content': userText},
    ];

    final response = await _httpClient.post(
      Uri.parse(AppConfig.groqEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.groqApiKey}',
      },
      body: jsonEncode({
        'model': AppConfig.chatModel,
        'messages': messages,
        'temperature': 0.4,
        'max_tokens': 450,
      }),
    );

    if (response.statusCode != 200) {
      throw ChatServiceException(response.statusCode);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const ChatServiceException(200);
    }

    final firstChoice = choices.first as Map<String, dynamic>;
    final message = firstChoice['message'] as Map<String, dynamic>?;
    final content = message?['content'];

    if (content is! String || content.trim().isEmpty) {
      throw const ChatServiceException(200);
    }
    return content.trim();
  }
}

class ChatConfigurationException implements Exception {
  const ChatConfigurationException();
}

class ChatServiceException implements Exception {
  const ChatServiceException(this.statusCode);

  final int statusCode;
}
