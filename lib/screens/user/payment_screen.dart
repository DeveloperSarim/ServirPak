import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/stripe_payment_service.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';

// Card number formatter for proper spacing
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(' ', '');
    String formatted = '';

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Month formatter (01-12)
class MonthInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    if (text.length > 2) {
      text = text.substring(0, 2);
    }

    if (text.isNotEmpty) {
      int month = int.tryParse(text) ?? 0;
      if (month > 12) {
        text = '12';
      }
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// Year formatter (4 digits)
class YearInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    if (text.length > 4) {
      text = text.substring(0, 4);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// CVC formatter (3-4 digits)
class CVCInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    if (text.length > 4) {
      text = text.substring(0, 4);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final String lawyerId;
  final String lawyerName;
  final String lawyerSpecialization;
  final double consultationFee;
  final double platformFee;
  final double totalAmount;
  final String consultationDate;
  final String consultationTime;
  final String description;
  final String category;

  const PaymentScreen({
    super.key,
    required this.lawyerId,
    required this.lawyerName,
    required this.lawyerSpecialization,
    required this.consultationFee,
    required this.platformFee,
    required this.totalAmount,
    required this.consultationDate,
    required this.consultationTime,
    required this.description,
    required this.category,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvcController = TextEditingController();
  final _cardholderNameController = TextEditingController();

  bool _isPaymentProcessing = false;

  @override
  void initState() {
    super.initState();
    StripePaymentService.init();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isPaymentProcessing = true;
    });

    try {
      // Get current user
      final session = await AuthService.getSavedUserSession();
      String userId = session['userId'] as String;

      // Process payment
      bool success = await StripePaymentService.processPayment(
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        expiryMonth: _expiryMonthController.text,
        expiryYear: _expiryYearController.text,
        cvc: _cvcController.text,
        amount: widget.totalAmount,
        currency: 'PKR',
      );

      if (success) {
        // Generate payment ID
        String paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';

        // Get card details for saving
        String cardNumber = _cardNumberController.text.replaceAll(' ', '');
        String cardLastFour = cardNumber.length >= 4
            ? cardNumber.substring(cardNumber.length - 4)
            : '****';

        // Determine card type
        String cardType = _getCardType(cardNumber);

        // Save payment to Firestore
        bool saved = await PaymentService.savePayment(
          userId: userId,
          lawyerId: widget.lawyerId,
          lawyerName: widget.lawyerName,
          lawyerSpecialization: widget.lawyerSpecialization,
          consultationFee: widget.consultationFee,
          platformFee: widget.platformFee,
          totalAmount: widget.totalAmount,
          consultationDate: widget.consultationDate,
          consultationTime: widget.consultationTime,
          description: widget.description,
          category: widget.category,
          cardLastFour: cardLastFour,
          cardType: cardType,
          paymentStatus: 'completed',
          paymentId: paymentId,
        );

        if (saved) {
          print('✅ Payment saved to Firestore successfully');
          _showPaymentSuccessDialog();
        } else {
          _showPaymentErrorDialog(
            'Payment processed but failed to save. Please contact support.',
          );
        }
      } else {
        _showPaymentErrorDialog('Payment failed. Please try again.');
      }
    } catch (e) {
      _showPaymentErrorDialog('Payment error: $e');
    } finally {
      setState(() {
        _isPaymentProcessing = false;
      });
    }
  }

  String _getCardType(String cardNumber) {
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

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 12),
            Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your consultation has been booked successfully.'),
            const SizedBox(height: 16),
            const Text(
              'Booking Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Lawyer: ${widget.lawyerName}'),
            Text('Date: ${widget.consultationDate}'),
            Text('Time: ${widget.consultationTime}'),
            Text('Amount: PKR ${widget.totalAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            const Text(
              'You will receive a confirmation email shortly.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to booking screen
              Navigator.of(context).pop(); // Go back to lawyer details
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showPaymentErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 30),
            SizedBox(width: 12),
            Text('Payment Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookingSummary(),
              const SizedBox(height: 20),
              _buildPaymentForm(),
              const SizedBox(height: 20),
              _buildTestCardInfo(),
              const SizedBox(height: 30),
              _buildPayButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Lawyer', widget.lawyerName),
            _buildSummaryRow('Specialization', widget.lawyerSpecialization),
            _buildSummaryRow('Date', widget.consultationDate),
            _buildSummaryRow('Time', widget.consultationTime),
            _buildSummaryRow('Category', widget.category),
            const Divider(),
            _buildSummaryRow(
              'Consultation Fee',
              'PKR ${widget.consultationFee.toStringAsFixed(0)}',
            ),
            _buildSummaryRow(
              'Platform Fee',
              'PKR ${widget.platformFee.toStringAsFixed(0)}',
            ),
            _buildSummaryRow(
              'Total Amount',
              'PKR ${widget.totalAmount.toStringAsFixed(0)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF8B4513) : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? const Color(0xFF8B4513) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 16),

            // Cardholder Name
            TextFormField(
              controller: _cardholderNameController,
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                prefixIcon: const Icon(Icons.person, color: Color(0xFF8B4513)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B4513),
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter cardholder name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Card Number
            TextFormField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CardNumberInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Card Number',
                prefixIcon: const Icon(
                  Icons.credit_card,
                  color: Color(0xFF8B4513),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B4513),
                    width: 2,
                  ),
                ),
                hintText: '1234 5678 9012 3456',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter card number';
                }
                String cleanNumber = value.replaceAll(' ', '');
                if (cleanNumber.length < 13 || cleanNumber.length > 19) {
                  return 'Please enter a valid card number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Expiry and CVC Row
            Row(
              children: [
                // Expiry Month
                Expanded(
                  child: TextFormField(
                    controller: _expiryMonthController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      MonthInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Month',
                      prefixIcon: const Icon(
                        Icons.calendar_month,
                        color: Color(0xFF8B4513),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B4513),
                          width: 2,
                        ),
                      ),
                      hintText: 'MM',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      int? month = int.tryParse(value);
                      if (month == null || month < 1 || month > 12) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Expiry Year
                Expanded(
                  child: TextFormField(
                    controller: _expiryYearController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      YearInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Year',
                      prefixIcon: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF8B4513),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B4513),
                          width: 2,
                        ),
                      ),
                      hintText: 'YYYY',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      int? year = int.tryParse(value);
                      if (year == null || year < DateTime.now().year) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // CVC
                Expanded(
                  child: TextFormField(
                    controller: _cvcController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CVCInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: 'CVC',
                      prefixIcon: const Icon(
                        Icons.security,
                        color: Color(0xFF8B4513),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B4513),
                          width: 2,
                        ),
                      ),
                      hintText: '123',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (value.length < 3) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCardInfo() {
    return Card(
      elevation: 2,
      color: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Test Mode - Use Test Cards',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'For testing purposes, use these test card numbers:',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            _buildTestCardRow('Visa', '4242 4242 4242 4242'),
            _buildTestCardRow('Mastercard', '5555 5555 5555 4444'),
            _buildTestCardRow('American Express', '3782 822463 10005'),
            _buildTestCardRow('Discover', '6011 1111 1111 1117'),
            const SizedBox(height: 8),
            const Text(
              'Use any future expiry date and any 3-digit CVC (4-digit for Amex).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCardRow(String cardType, String cardNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$cardType: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          Text(
            cardNumber,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isPaymentProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B4513),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isPaymentProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Processing Payment...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pay PKR ${widget.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvcController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }
}
