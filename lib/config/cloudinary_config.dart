// Cloudinary Configuration
// Aapko yeh values Cloudinary dashboard se milengi
class CloudinaryConfig {
  // Aapka Cloudinary cloud name
  static const String cloudName = 'your_cloud_name_here';

  // Aapka API key
  static const String apiKey = 'your_api_key_here';

  // Aapka API secret
  static const String apiSecret = 'your_api_secret_here';

  // Aapka upload preset (unsigned uploads ke liye)
  static const String uploadPreset = 'your_upload_preset_here';

  // Base URL for Cloudinary API
  static String get baseUrl => 'https://api.cloudinary.com/v1_1/$cloudName';

  // Instructions:
  // 1. Cloudinary account banayein: https://cloudinary.com
  // 2. Dashboard se yeh values copy karein:
  //    - Cloud Name: Dashboard ke top par
  //    - API Key: Account Details section mein
  //    - API Secret: Account Details section mein
  // 3. Upload Preset banayein:
  //    - Settings > Upload > Upload presets
  //    - "Add upload preset" click karein
  //    - Preset name dein (e.g., "servipak_uploads")
  //    - Signing Mode: "Unsigned" select karein
  //    - Save karein
  // 4. Yahan values update karein
}

