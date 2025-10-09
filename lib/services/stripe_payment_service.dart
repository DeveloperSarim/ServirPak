class StripePaymentService {
  static void init() {
    print('🔧 Stripe Payment Service initialized in test mode');
  }

  // Validate card number using Luhn algorithm
  static bool _isValidCardNumber(String cardNumber) {
    // Remove spaces and non-digits
    String cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    // Luhn algorithm
    int sum = 0;
    bool alternate = false;

    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  // Validate card type
  static String _getCardType(String cardNumber) {
    String cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cleanNumber.startsWith('4')) {
      return 'Visa';
    } else if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2')) {
      return 'Mastercard';
    } else if (cleanNumber.startsWith('3')) {
      return 'American Express';
    } else if (cleanNumber.startsWith('6')) {
      return 'Discover';
    }

    return 'Unknown';
  }

  // Validate expiry date
  static bool _isValidExpiryDate(String month, String year) {
    try {
      int expMonth = int.parse(month);
      int expYear = int.parse(year);

      if (expMonth < 1 || expMonth > 12) {
        return false;
      }

      DateTime now = DateTime.now();
      DateTime expiryDate = DateTime(expYear, expMonth);

      return expiryDate.isAfter(now) ||
          (expiryDate.year == now.year && expiryDate.month == now.month);
    } catch (e) {
      return false;
    }
  }

  // Validate CVC
  static bool _isValidCVC(String cvc, String cardNumber) {
    String cardType = _getCardType(cardNumber);

    if (cardType == 'American Express') {
      return cvc.length == 4;
    } else {
      return cvc.length == 3;
    }
  }

  static Future<bool> processPayment({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
    required double amount,
    required String currency,
  }) async {
    try {
      print('💳 Processing payment...');

      // Clean card number
      String cleanCardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

      // Validate card number
      if (!_isValidCardNumber(cleanCardNumber)) {
        throw Exception('Invalid card number');
      }

      // Validate expiry date
      if (!_isValidExpiryDate(expiryMonth, expiryYear)) {
        throw Exception('Card has expired or invalid expiry date');
      }

      // Validate CVC
      if (!_isValidCVC(cvc, cleanCardNumber)) {
        throw Exception('Invalid CVC');
      }

      // Get card type
      String cardType = _getCardType(cleanCardNumber);
      print('Card Type: $cardType');
      print('Amount: $currency ${amount.toStringAsFixed(2)}');

      // Simulate payment method creation
      print('🔄 Creating payment method...');
      await Future.delayed(const Duration(milliseconds: 500));

      // For test mode, simulate successful payment
      // In production, you would create a PaymentIntent on your backend
      print('🔄 Processing payment...');
      await Future.delayed(const Duration(seconds: 2));

      print('✅ Payment processed successfully!');
      return true;
    } catch (e) {
      print('❌ Payment error: $e');
      return false;
    }
  }
}
