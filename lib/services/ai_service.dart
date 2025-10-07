import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/ai_config.dart';

class AIService {
  static GenerativeModel? _model;
  static String? _constitutionText;

  // Initialize the AI service
  static Future<void> initialize() async {
    try {
      // Load Constitution text from assets
      try {
        _constitutionText = await rootBundle.loadString(
          'assets/Constitution.txt',
        );
        print(
          '✅ Constitution text loaded successfully (${_constitutionText?.length ?? 0} characters)',
        );
      } catch (assetError) {
        print('⚠️ Could not load Constitution.txt: $assetError');
        // Try alternative path
        try {
          _constitutionText = await rootBundle.loadString(
            'assets/Constitution.txt',
          );
          print('✅ Constitution text loaded with alternative path');
        } catch (e) {
          print('❌ Failed to load Constitution.txt: $e');
          _constitutionText =
              'Constitution of Pakistan - Text not available. Please ensure the file exists in assets folder.';
        }
      }

      // Initialize Gemini model
      _model = GenerativeModel(
        model: AIConfig.modelName,
        apiKey: AIConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: AIConfig.temperature,
          topK: AIConfig.topK,
          topP: AIConfig.topP,
          maxOutputTokens: AIConfig.maxOutputTokens,
        ),
      );

      print('✅ AI Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing AI Service: $e');
      // Don't rethrow, allow the service to work with mock responses
    }
  }

  // Get AI response for legal questions
  static Future<String> getLegalAdvice(String userQuestion) async {
    if (_model == null) {
      await initialize();
    }

    try {
      // Create a comprehensive prompt that includes the Constitution text
      final constitutionContext =
          _constitutionText != null && _constitutionText!.isNotEmpty
          ? _constitutionText!
          : 'Constitution text not available. Please provide general legal advice about Pakistani law.';

      final prompt =
          '''
You are a legal AI assistant specialized in Pakistani law. You should provide accurate, helpful legal advice based on Pakistani constitutional provisions and legal principles.

CONSTITUTION OF PAKISTAN:
$constitutionContext

USER QUESTION: $userQuestion

Please provide a comprehensive legal response based on Pakistani law. Include:
1. Relevant constitutional articles (if available)
2. Legal interpretation
3. Practical implications
4. Any limitations or disclaimers

Keep your response clear, accurate, and helpful. If the question is not related to Pakistani law, politely redirect the user to ask about Pakistani legal matters.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      return response.text ??
          'Sorry, I could not generate a response. Please try again.';
    } catch (e) {
      print('❌ Error getting AI response: $e');

      // Fallback to Constitution-based responses if Gemini API fails
      return _getFallbackResponse(userQuestion);
    }
  }

  // Fallback response when Gemini API is not available
  static String _getFallbackResponse(String userQuestion) {
    final question = userQuestion.toLowerCase();

    if (question.contains('right') || question.contains('حق')) {
      return '''🤖 AI Legal Assistant (Fallback Mode)

According to the Constitution of Pakistan, fundamental rights are guaranteed under Part II (Articles 8-28). These include:

• Right to life and liberty (Article 9)
• Freedom of movement (Article 15)
• Freedom of assembly and association (Article 16)
• Freedom of speech and expression (Article 19)
• Freedom of religion (Article 20)
• Right to education (Article 25A)
• Right to property (Article 24)

These rights are subject to reasonable restrictions in the interest of public order, morality, and security of the state.

⚠️ Note: This is a fallback response. The Gemini API is currently unavailable. Please check your internet connection and API key configuration.''';
    } else if (question.contains('citizen') || question.contains('شہری')) {
      return '''🤖 AI Legal Assistant (Fallback Mode)

Citizenship in Pakistan is governed by Articles 7-8 of the Constitution:

• A person is a citizen of Pakistan if they were a citizen before the Constitution came into effect
• Anyone born in Pakistan after the Constitution came into effect is a citizen
• Children of Pakistani citizens born abroad are also citizens
• Dual citizenship is allowed under certain conditions

Citizens have both rights and responsibilities under the Constitution.

⚠️ Note: This is a fallback response. The Gemini API is currently unavailable.''';
    } else if (question.contains('government') || question.contains('حکومت')) {
      return '''🤖 AI Legal Assistant (Fallback Mode)

The government structure is defined in Part III of the Constitution:

• Federal Parliamentary System
• President as Head of State
• Prime Minister as Head of Government
• Bicameral Parliament (National Assembly + Senate)
• Provincial Governments with Chief Ministers
• Independent Judiciary

The system ensures separation of powers and checks and balances.

⚠️ Note: This is a fallback response. The Gemini API is currently unavailable.''';
    } else if (question.contains('court') || question.contains('عدالت')) {
      return '''🤖 AI Legal Assistant (Fallback Mode)

The judicial system is established under Part VII of the Constitution:

• Supreme Court (highest court)
• High Courts (provincial level)
• District and Sessions Courts
• Specialized courts (Family, Commercial, etc.)

The judiciary is independent and has the power of judicial review over legislative and executive actions.

⚠️ Note: This is a fallback response. The Gemini API is currently unavailable.''';
    } else if (question.contains('constitution') || question.contains('آئین')) {
      return '''🤖 AI Legal Assistant (Fallback Mode)

The Constitution of Pakistan (1973) is the supreme law of the land:

• Adopted on April 10, 1973
• Establishes Islamic Republic of Pakistan
• Defines fundamental rights and principles
• Sets up federal structure
• Provides for independent judiciary
• Includes Islamic provisions

It has been amended several times to reflect changing needs of the nation.

⚠️ Note: This is a fallback response. The Gemini API is currently unavailable.''';
    } else {
      return '''🤖 AI Legal Assistant (Fallback Mode)

I can help you with questions about:

• Fundamental rights and freedoms
• Government structure and functions
• Judicial system and courts
• Constitutional provisions
• Legal procedures and processes

Please ask a specific question about Pakistani law, and I'll provide information based on the Constitution.

⚠️ Note: This is a fallback response. The Gemini API is currently unavailable. Please check your internet connection and API key configuration.''';
    }
  }

  // Get quick legal information
  static Future<String> getQuickLegalInfo(String query) async {
    if (_model == null) {
      await initialize();
    }

    try {
      final prompt =
          '''
You are a legal AI assistant for Pakistani law. Provide a brief, accurate answer based on the Constitution of Pakistan.

CONSTITUTION REFERENCE:
${_constitutionText ?? 'Constitution text not available'}

QUERY: $query

Provide a concise, accurate response (2-3 sentences maximum) based on Pakistani constitutional law.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      return response.text ??
          'Sorry, I could not provide information on this topic.';
    } catch (e) {
      print('❌ Error getting quick legal info: $e');
      return 'Sorry, I encountered an error. Please try again.';
    }
  }

  // Search for specific constitutional articles
  static Future<String> searchConstitutionalArticle(String topic) async {
    if (_model == null) {
      await initialize();
    }

    try {
      final prompt =
          '''
Find and explain the relevant constitutional articles related to: $topic

CONSTITUTION OF PAKISTAN:
${_constitutionText ?? 'Constitution text not available'}

Please:
1. Identify the specific articles related to $topic
2. Quote the relevant constitutional text
3. Provide a clear explanation
4. Mention any related provisions

If no relevant articles are found, state that clearly.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      return response.text ??
          'No relevant constitutional articles found for this topic.';
    } catch (e) {
      print('❌ Error searching constitutional articles: $e');
      return 'Sorry, I encountered an error while searching the Constitution.';
    }
  }

  // Check if the service is properly initialized
  static bool get isInitialized => _model != null && _constitutionText != null;

  // Get service status
  static String getStatus() {
    if (_model == null) {
      return 'AI Service not initialized';
    }
    if (_constitutionText == null) {
      return 'Constitution text not loaded';
    }
    return 'AI Service ready';
  }
}
