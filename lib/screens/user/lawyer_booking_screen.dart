import 'package:flutter/material.dart';
import '../../services/consultation_booking_service.dart';
import 'payment_screen.dart';

class LawyerBookingScreen extends StatefulWidget {
  final String lawyerId;
  final Map<String, dynamic> lawyerData;

  const LawyerBookingScreen({
    super.key,
    required this.lawyerId,
    required this.lawyerData,
  });

  @override
  State<LawyerBookingScreen> createState() => _LawyerBookingScreenState();
}

class _LawyerBookingScreenState extends State<LawyerBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  // State variables
  String _selectedCategory =
      'General'; // Will be updated with lawyer's specialization
  String _consultationFee = 'PKR 5000';
  String _platformFee = 'PKR 250';
  String _totalAmount = 'PKR 5250';
  bool _isLoading = false;

  // Categories removed - now using lawyer's specialization

  // Time slots
  final List<String> _timeSlots = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadLawyerDetails();
  }

  Future<void> _loadLawyerDetails() async {
    try {
      // Set lawyer's specialization as category
      setState(() {
        _selectedCategory =
            widget.lawyerData['specialization'] ?? 'General Law';
      });

      // Get consultation fee
      double fee = await ConsultationBookingService.getLawyerConsultationFee(
        widget.lawyerId,
      );
      setState(() {
        _consultationFee = fee.toString();
      });

      // Calculate platform fee and total
      _calculateFees();
    } catch (e) {
      print('❌ Error loading lawyer details: $e');
    }
  }

  void _calculateFees() {
    try {
      // Extract numeric value from fee string
      String feeString = _consultationFee
          .replaceAll('PKR ', '')
          .replaceAll(',', '');
      double baseFee = double.tryParse(feeString) ?? 5000.0;
      double platformFeeAmount = baseFee * 0.05; // 5% platform fee
      double total = baseFee + platformFeeAmount;

      setState(() {
        _platformFee = 'PKR ${platformFeeAmount.toStringAsFixed(0)}';
        _totalAmount = 'PKR ${total.toStringAsFixed(0)}';
      });
    } catch (e) {
      print('❌ Error calculating fees: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 120),
      ), // 4 months (120 days)
    );

    if (picked != null) {
      setState(() {
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _timeSlots.map((time) {
            return ListTile(
              title: Text(time),
              onTap: () {
                setState(() {
                  _timeController.text = time;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _bookConsultation() async {
    if (!_formKey.currentState!.validate()) return;

    // Navigate to payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          lawyerId: widget.lawyerId,
          lawyerName: widget.lawyerData['name'] ?? 'Unknown Lawyer',
          lawyerSpecialization:
              widget.lawyerData['specialization'] ?? 'General Law',
          consultationFee: _getNumericFee(_consultationFee),
          platformFee: _getNumericFee(_platformFee),
          totalAmount: _getNumericFee(_totalAmount),
          consultationDate: _dateController.text,
          consultationTime: _timeController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
        ),
      ),
    );
  }

  double _getNumericFee(String feeString) {
    try {
      String numericString = feeString
          .replaceAll('PKR ', '')
          .replaceAll(',', '');
      return double.tryParse(numericString) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Book Consultation',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLawyerInfo(),
              const SizedBox(height: 20),
              _buildConsultationDetails(),
              const SizedBox(height: 20),
              _buildFeeBreakdown(),
              const SizedBox(height: 30),
              _buildBookButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLawyerInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Profile Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFF8B4513), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child:
                    widget.lawyerData['profileImage'] != null &&
                        widget.lawyerData['profileImage'].isNotEmpty
                    ? Image.network(
                        widget.lawyerData['profileImage'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF8B4513),
                          );
                        },
                      )
                    : const Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFF8B4513),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Lawyer Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lawyerData['name'] ?? 'Unknown Lawyer',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.lawyerData['specialization'] ?? 'General Law',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.lawyerData['rating'] ?? 0.0}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.work, color: Colors.grey, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.lawyerData['experience'] ?? 0} years',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationDetails() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consultation Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 16),

            // Lawyer's Category (Read-only)
            TextFormField(
              readOnly: true,
              initialValue:
                  widget.lawyerData['specialization'] ?? 'General Law',
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(
                  Icons.category,
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
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 16),

            // Date Picker
            TextFormField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Select Date',
                prefixIcon: const Icon(
                  Icons.calendar_today,
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
              ),
              onTap: _selectDate,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a date';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Time Picker
            TextFormField(
              controller: _timeController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Select Time',
                prefixIcon: const Icon(
                  Icons.access_time,
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
              ),
              onTap: _selectTime,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a time';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: const Icon(
                  Icons.description,
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
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe your legal issue';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeBreakdown() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fee Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 16),

            _buildFeeRow('Consultation Fee', _consultationFee, Icons.gavel),
            _buildFeeRow('Platform Fee (5%)', _platformFee, Icons.business),
            const Divider(),
            _buildFeeRow(
              'Total Amount',
              _totalAmount,
              Icons.account_balance_wallet,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(
    String label,
    String amount,
    IconData icon, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: isTotal ? const Color(0xFF8B4513) : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? const Color(0xFF8B4513) : Colors.black87,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? const Color(0xFF8B4513) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _bookConsultation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B4513),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isLoading
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
                  Text('Booking...'),
                ],
              )
            : const Text(
                'Proceed to Payment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}
