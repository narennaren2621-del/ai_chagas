class AppConfig {
  const AppConfig._();

  static const googleOAuthClientId =
      '1083808569581-79da40pjl67mnh8fsmuhau5p5ob4n0tp.apps.googleusercontent.com';

  static const _defaultGroqApiKey =
      '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';

  /// Supply this at build/run time or fall back to configured default key.
  static const groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: _defaultGroqApiKey,
  );
  static const groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const chatModel = 'llama-3.3-70b-versatile';
}
