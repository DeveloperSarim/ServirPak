# AI Legal Assistant Setup

This document explains how to set up the AI Legal Assistant feature in ServirPak.

## Features

- **AI-Powered Legal Advice**: Get instant legal advice based on the Constitution of Pakistan
- **Constitution Integration**: The AI has access to the complete Constitution of Pakistan
- **Gemini Integration**: Powered by Google's Gemini AI model
- **Real-time Chat**: Interactive chat interface for legal questions

## Setup Instructions

### 1. Get Your Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated API key

### 2. Configure the API Key

1. Open `lib/config/ai_config.dart`
2. Replace `YOUR_GEMINI_API_KEY_HERE` with your actual API key:

```dart
static const String geminiApiKey = 'your-actual-api-key-here';
```

### 3. Test the Integration

1. Run the app: `flutter run`
2. Navigate to the user dashboard
3. Look for the "AI Legal Assistant" section
4. Try asking a legal question

## Usage

### For Users

1. **Access**: The AI Legal Assistant is available on the main user dashboard
2. **Ask Questions**: Type your legal questions in the chat interface
3. **Get Responses**: Receive AI-powered responses based on Pakistani law and Constitution
4. **Clear Chat**: Use the clear button to start a new conversation

### Example Questions

- "What are my fundamental rights as a Pakistani citizen?"
- "How does the judicial system work in Pakistan?"
- "What is the process for filing a case in court?"
- "What are the constitutional provisions for freedom of speech?"

## Technical Details

### AI Model Configuration

- **Model**: Gemini 1.5 Flash
- **Temperature**: 0.7 (balanced creativity and accuracy)
- **Max Tokens**: 1024
- **Context**: Full Constitution of Pakistan

### Files Structure

```
lib/
├── config/
│   └── ai_config.dart          # API key and configuration
├── services/
│   └── ai_service.dart         # AI service implementation
├── widgets/
│   └── ai_chat_widget.dart     # Chat interface widget
└── screens/user/
    └── user_dashboard.dart     # Integration point
```

### Dependencies

- `google_generative_ai: ^0.2.2` - Gemini AI integration
- `flutter/services` - Asset loading for Constitution text

## Troubleshooting

### Common Issues

1. **"AI Service not initialized"**
   - Check if your API key is correctly set
   - Ensure internet connection
   - Restart the app

2. **"Constitution text not loaded"**
   - Check if `assets/Constitution.txt` exists
   - Verify `pubspec.yaml` includes the asset

3. **API Key Issues**
   - Verify the API key is correct
   - Check if the API key has proper permissions
   - Check your Google AI Studio quota

### Debug Information

The app will show debug information in the console:
- `✅ AI Service initialized successfully` - Service is ready
- `❌ Error initializing AI Service` - Check configuration

## Security Notes

- Never commit your API key to version control
- Use environment variables for production
- Consider implementing rate limiting for production use
- The Constitution text is loaded locally for privacy

## Support

For technical support or questions about the AI Legal Assistant:
1. Check the console logs for error messages
2. Verify your API key configuration
3. Ensure all dependencies are installed (`flutter pub get`)
4. Test with a simple question first

## Future Enhancements

- [ ] Support for multiple languages (Urdu, English)
- [ ] Document upload and analysis
- [ ] Case law integration
- [ ] Lawyer recommendation based on AI analysis
- [ ] Voice input/output support
