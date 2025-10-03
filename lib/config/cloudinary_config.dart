// Cloudinary Configuration
// Aapko yeh values Cloudinary dashboard se milengi
class CloudinaryConfig {
  // Your Cloudinary cloud name (working credentials)
  static const String cloudName = 'dii8rpixj';

  // Aapka API key
  static const String apiKey = '294514962427167';

  // Aapka API secret
  static const String apiSecret = 'yH0uP4MNAUv_scZzCbn5LCt53WM';

  // Your upload preset (working preset name)
  static const String uploadPreset = 'servipak_preset';

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
