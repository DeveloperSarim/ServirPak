import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/ai_config.dart';
import 'lawyer_suggestion_service.dart';
import '../models/lawyer_model.dart';
import '../models/case_info_model.dart';

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

Please provide a comprehensive legal response based on Pakistani law. Format your response using markdown:
- Use **bold** for important terms and concepts
- Use *italic* for emphasis
- Use bullet points (•) for lists
- Use numbered lists for steps or procedures
- Use clear headings and structure

Include:
1. **Relevant constitutional articles** (if available)
2. **Legal interpretation**
3. **Practical implications**
4. **Any limitations or disclaimers**

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

  // Handle lawyer suggestion requests
  static Future<String> handleLawyerSuggestion(String userQuestion) async {
    try {
      // Check if user is asking about finding a lawyer
      final question = userQuestion.toLowerCase();
      if (question.contains('lawyer') ||
          question.contains('advocate') ||
          question.contains('attorney') ||
          question.contains('legal help') ||
          question.contains('chaiye') ||
          question.contains('چاہیے') ||
          question.contains('وکیل') ||
          question.contains('lawyer chaiye') ||
          question.contains('advocate chaiye')) {
        // Extract case information from the question
        final caseInfo = await _extractCaseInfo(userQuestion);

        if (caseInfo != null) {
          // Search for lawyers based on case information
          final lawyers = await LawyerSuggestionService.findLawyersForCase(
            caseType: caseInfo.caseType,
            city: caseInfo.city,
            specialization: caseInfo.specialization,
            experience: caseInfo.experience,
            budget: caseInfo.budget,
          );

          if (lawyers.isNotEmpty) {
            return _formatLawyerSuggestions(lawyers, caseInfo);
          } else {
            return '''**No lawyers found** for your specific requirements.

**Suggestions:**
• Try expanding your search criteria
• Consider different cities or specializations
• Contact our support team for assistance

Would you like me to help you refine your search criteria?''';
          }
        } else {
          // If no specific case info, show some general lawyers
          final generalLawyers =
              await LawyerSuggestionService.findLawyersForCase(
                caseType: 'general',
                city: '',
                specialization: '',
                experience: '',
                budget: '',
              );

          if (generalLawyers.isNotEmpty) {
            return '''**I'd be happy to help you find a lawyer!**

Here are some **verified lawyers** from our database:

${_formatGeneralLawyers(generalLawyers)}

**To get more specific recommendations, please tell me:**
• **What type of case** do you have? (e.g., family law, criminal, civil, etc.)
• **Which city** are you in?
• **What's your budget** for consultation?

This will help me find the best lawyers for your specific needs!''';
          } else {
            // If no lawyers found, create sample lawyers and try again
            print('🔍 No lawyers found, creating sample lawyers...');
            await LawyerSuggestionService.createSampleLawyers();

            // Try to get lawyers again
            final retryLawyers =
                await LawyerSuggestionService.findLawyersForCase(
                  caseType: 'general',
                  city: '',
                  specialization: '',
                  experience: '',
                  budget: '',
                );

            if (retryLawyers.isNotEmpty) {
              return '''**I'd be happy to help you find a lawyer!**

Here are some **verified lawyers** from our database:

${_formatGeneralLawyers(retryLawyers)}

**To get more specific recommendations, please tell me:**
• **What type of case** do you have? (e.g., family law, criminal, civil, etc.)
• **Which city** are you in?
• **What's your budget** for consultation?

This will help me find the best lawyers for your specific needs!''';
            } else {
              return '''**I'd be happy to help you find a lawyer!**

To provide the best recommendations, please tell me:

• **What type of case** do you have? (e.g., family law, criminal, civil, etc.)
• **Which city** are you in?
• **What's your budget** for consultation?
• **Any specific requirements** (experience level, specialization)?

Please provide these details and I'll find the best lawyers for you!''';
            }
          }
        }
      }

      // If not about lawyers, return regular legal advice
      return await getLegalAdvice(userQuestion);
    } catch (e) {
      print('❌ Error handling lawyer suggestion: $e');
      return 'Sorry, I encountered an error while searching for lawyers. Please try again.';
    }
  }

  // Extract case information from user question
  static Future<CaseInfo?> _extractCaseInfo(String userQuestion) async {
    try {
      final prompt =
          '''
Analyze this user question and extract case information. The user may be asking in English, Urdu, or mixed language:

User Question: $userQuestion

Extract the following information if mentioned:
- Case type (e.g., family law, criminal, civil, property, divorce, marriage, etc.)
- City/location (e.g., Karachi, Lahore, Islamabad, etc.)
- Budget/consultation fee
- Experience level needed
- Specialization required
- Urgency level

Common Urdu terms:
- "lawyer chaiye" = need a lawyer
- "family law" = family matters, divorce, marriage
- "criminal law" = criminal cases, theft, assault
- "property law" = property disputes, land issues

If the user hasn't provided enough information, return null.
If they have provided sufficient information, return a structured response with the details.

Format your response as:
CASE_TYPE: [type]
CITY: [city]
BUDGET: [budget]
EXPERIENCE: [experience]
SPECIALIZATION: [specialization]
URGENCY: [urgency]
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text ?? '';

      // Parse the response to extract case information
      return _parseCaseInfo(responseText);
    } catch (e) {
      print('❌ Error extracting case info: $e');
      return null;
    }
  }

  // Parse case information from AI response
  static CaseInfo? _parseCaseInfo(String response) {
    try {
      final lines = response.split('\n');
      String caseType = '';
      String city = '';
      String budget = '';
      String experience = '';
      String specialization = '';
      String urgency = '';

      for (final line in lines) {
        if (line.startsWith('CASE_TYPE:')) {
          caseType = line.substring(10).trim();
        } else if (line.startsWith('CITY:')) {
          city = line.substring(5).trim();
        } else if (line.startsWith('BUDGET:')) {
          budget = line.substring(7).trim();
        } else if (line.startsWith('EXPERIENCE:')) {
          experience = line.substring(11).trim();
        } else if (line.startsWith('SPECIALIZATION:')) {
          specialization = line.substring(15).trim();
        } else if (line.startsWith('URGENCY:')) {
          urgency = line.substring(8).trim();
        }
      }

      // Check if we have minimum required information
      if (caseType.isNotEmpty && city.isNotEmpty) {
        return CaseInfo(
          caseType: caseType,
          description: 'User case description',
          city: city,
          urgency: urgency.isNotEmpty ? urgency : 'normal',
          budget: budget.isNotEmpty ? budget : 'flexible',
          experience: experience.isNotEmpty ? experience : 'any',
          specialization: specialization.isNotEmpty
              ? specialization
              : 'general',
          contactPreference: 'any',
        );
      }

      return null;
    } catch (e) {
      print('❌ Error parsing case info: $e');
      return null;
    }
  }

  // Format lawyer suggestions
  static String _formatLawyerSuggestions(
    List<LawyerModel> lawyers,
    CaseInfo caseInfo,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('**🏛️ Recommended Lawyers for Your Case**\n');
    buffer.writeln('**Case Type:** ${caseInfo.caseType}');
    buffer.writeln('**Location:** ${caseInfo.city}\n');

    for (int i = 0; i < lawyers.length; i++) {
      final lawyer = lawyers[i];
      buffer.writeln('**${i + 1}. ${lawyer.name}**');
      buffer.writeln('• **Specialization:** ${lawyer.specialization}');
      buffer.writeln('• **Experience:** ${lawyer.experience} years');
      buffer.writeln(
        '• **Rating:** ${lawyer.rating?.toStringAsFixed(1) ?? 'N/A'}/5.0',
      );
      buffer.writeln('• **Total Cases:** ${lawyer.totalCases ?? 0}');

      if (lawyer.consultationFee != null) {
        buffer.writeln('• **Consultation Fee:** Rs. ${lawyer.consultationFee}');
      }

      if (lawyer.city != null) {
        buffer.writeln('• **Location:** ${lawyer.city}');
      }

      if (lawyer.bio != null && lawyer.bio!.isNotEmpty) {
        buffer.writeln('• **Bio:** ${lawyer.bio}');
      }

      buffer.writeln('• **Contact:** ${lawyer.phone}');
      buffer.writeln('');
    }

    buffer.writeln('**💡 Next Steps:**');
    buffer.writeln('• Contact the lawyers directly using their phone numbers');
    buffer.writeln('• Schedule consultations to discuss your case');
    buffer.writeln('• Ask about their experience with similar cases');
    buffer.writeln('• Inquire about fees and payment terms');

    return buffer.toString();
  }

  // Format general lawyers list
  static String _formatGeneralLawyers(List<LawyerModel> lawyers) {
    final buffer = StringBuffer();

    for (int i = 0; i < lawyers.length && i < 3; i++) {
      final lawyer = lawyers[i];
      buffer.writeln('**${i + 1}. ${lawyer.name}**');
      buffer.writeln('• **Specialization:** ${lawyer.specialization}');
      buffer.writeln('• **Experience:** ${lawyer.experience} years');
      buffer.writeln(
        '• **Rating:** ${lawyer.rating?.toStringAsFixed(1) ?? 'N/A'}/5.0',
      );

      if (lawyer.city != null) {
        buffer.writeln('• **Location:** ${lawyer.city}');
      }

      if (lawyer.consultationFee != null) {
        buffer.writeln('• **Consultation Fee:** Rs. ${lawyer.consultationFee}');
      }

      buffer.writeln('• **Contact:** ${lawyer.phone}');
      buffer.writeln('');
    }

    return buffer.toString();
  }
}
