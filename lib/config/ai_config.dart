class AIConfig {
  // Replace this with your actual Gemini API key
  // Get your API key from: https://makersuite.google.com/app/apikey
  static const String geminiApiKey = 'AIzaSyDI6UCPT3w1NbNo5T0YAfB4x23vMOAxne4';

  // Configuration for AI responses
  static const double temperature = 0.7;
  static const int topK = 40;
  static const double topP = 0.95;
  static const int maxOutputTokens = 1024;

  // Model configuration
  static const String modelName = 'gemini-2.0-flash';

  // Instructions for setting up the API key
  static const String setupInstructions = '''
To use the AI Legal Assistant:

1. Go to https://makersuite.google.com/app/apikey
2. Create a new API key
3. Replace 'YOUR_GEMINI_API_KEY_HERE' in lib/config/ai_config.dart with your actual API key
4. Restart the app

The AI will then be able to provide legal advice based on the Constitution of Pakistan.
''';
}
