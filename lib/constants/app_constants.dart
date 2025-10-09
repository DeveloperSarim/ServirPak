class AppConstants {
  // App Info
  static const String appName = 'ServirPak';
  static const String appVersion = '1.0.0';

  // User Roles
  static const String userRole = 'user';
  static const String lawyerRole = 'lawyer';
  static const String adminRole = 'admin';

  // User Status
  static const String pendingStatus = 'pending';
  static const String approvedStatus = 'approved';
  static const String rejectedStatus = 'rejected';
  static const String verifiedStatus = 'verified';
  static const String confirmedStatus = 'confirmed';
  static const String completedStatus = 'completed';
  static const String cancelledStatus = 'cancelled';
  static const String failedStatus = 'failed';
  static const String refundedStatus = 'refunded';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String lawyersCollection = 'lawyers';
  static const String kycCollection = 'kyc_documents';
  static const String notificationsCollection = 'notifications';
  static const String citiesCollection = 'cities';
  static const String consultationsCollection = 'consultations';
  static const String chatsCollection = 'chats';
  static const String chatMessagesCollection = 'chat_messages';
  static const String chatCollection = 'chats';
  static const String paymentsCollection = 'payments';
  static const String reviewsCollection = 'reviews';
  static const String userWalletsCollection = 'user_wallets';
  static const String walletTransactionsCollection = 'wallet_transactions';

  // Shared Preferences Keys
  static const String isFirstTimeKey = 'is_first_time';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';

  // KYC Document Types
  static const String cnicDocument = 'cnic';
  static const String degreeDocument = 'degree';
  static const String licenseDocument = 'license';
  static const String experienceDocument = 'experience';

  // Consultation Types
  static const String freeConsultation = 'free';
  static const String paidConsultation = 'paid';
  static const String premiumConsultation = 'premium';

  // Legal Categories
  static const List<String> legalCategories = [
    'Criminal Law',
    'Family Law',
    'Property Law',
    'Business Law',
    'Constitutional Law',
    'Tax Law',
    'Labor Law',
    'Immigration Law',
    'Intellectual Property',
    'Environmental Law',
  ];

  // Payment Methods
  static const List<String> paymentMethods = [
    'card',
    'bank_transfer',
    'easypaisa',
    'jazzcash',
  ];

  // Consultation Pricing
  static const Map<String, double> consultationPricing = {
    'free': 0.0,
    'paid': 5000.0, // 5000 PKR
    'premium': 15000.0, // 15000 PKR
  };

  // Demo Credentials
  static const Map<String, String> demoUsers = {
    'admin@servirpak.com': 'admin123',
    'lawyer1@servirpak.com': 'lawyer123',
    'lawyer2@servirpak.com': 'lawyer123',
    'user1@servirpak.com': 'user123',
    'user2@servirpak.com': 'user123',
  };
}
