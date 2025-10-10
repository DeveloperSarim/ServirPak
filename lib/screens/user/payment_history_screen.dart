import 'package:flutter/material.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';
import 'review_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String _userId = '';
  Map<String, bool> _hasReviewed = {};

  @override
  void initState() {
    super.initState();
    _loadUserPayments();
  }

  Future<void> _loadUserPayments() async {
    try {
      setState(() => _isLoading = true);

      // Get current user
      final session = await AuthService.getSavedUserSession();
      _userId = session['userId'] as String;

      // Load payment history
      List<Map<String, dynamic>> payments =
          await PaymentService.getUserPaymentHistory(_userId);

      setState(() {
        _payments = payments;
        _isLoading = false;
      });

      // Check which lawyers have been reviewed
      await _checkReviewStatus();
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading payment history: $e');
    }
  }

  Future<void> _checkReviewStatus() async {
    try {
      Map<String, bool> reviewStatus = {};

      for (var payment in _payments) {
        String lawyerId = payment['lawyerId'] ?? '';
        if (lawyerId.isNotEmpty) {
          bool hasReviewed = await ReviewService().hasClientReviewed(
            lawyerId,
            _userId,
          );
          reviewStatus[lawyerId] = hasReviewed;
        }
      }

      setState(() {
        _hasReviewed = reviewStatus;
      });
    } catch (e) {
      print('Error checking review status: $e');
    }
  }

  Future<void> _navigateToReview(Map<String, dynamic> payment) async {
    try {
      bool? reviewSubmitted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewScreen(
            lawyerId: payment['lawyerId'] ?? '',
            lawyerName: payment['lawyerName'] ?? 'Unknown Lawyer',
            lawyerSpecialization:
                payment['lawyerSpecialization'] ?? 'General Law',
            consultationId: payment['paymentId'] ?? '',
            consultationType: payment['category'] ?? 'Consultation',
          ),
        ),
      );

      if (reviewSubmitted == true) {
        // Refresh review status
        await _checkReviewStatus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Payment History',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B4513)),
            )
          : _payments.isEmpty
          ? _buildEmptyState()
          : _buildPaymentList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No Payment History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment history will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList() {
    return RefreshIndicator(
      onRefresh: _loadUserPayments,
      color: const Color(0xFF8B4513),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> payment = _payments[index];
          return _buildPaymentCard(payment);
        },
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip(payment['paymentStatus'] ?? 'unknown'),
                Text(
                  'PKR ${(payment['totalAmount'] ?? 0.0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lawyer info
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF8B4513), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    payment['lawyerName'] ?? 'Unknown Lawyer',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.work, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  payment['lawyerSpecialization'] ?? 'General Law',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Payment details
            _buildDetailRow('Date', payment['consultationDate'] ?? 'N/A'),
            _buildDetailRow('Time', payment['consultationTime'] ?? 'N/A'),
            _buildDetailRow('Category', payment['category'] ?? 'N/A'),
            _buildDetailRow(
              'Card',
              '**** ${payment['cardLastFour'] ?? '****'}',
            ),
            _buildDetailRow('Card Type', payment['cardType'] ?? 'Unknown'),

            const SizedBox(height: 12),
            const Divider(),

            // Fee breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Consultation Fee:', style: TextStyle(fontSize: 14)),
                Text(
                  'PKR ${(payment['consultationFee'] ?? 0.0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Platform Fee:', style: TextStyle(fontSize: 14)),
                Text(
                  'PKR ${(payment['platformFee'] ?? 0.0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'PKR ${(payment['totalAmount'] ?? 0.0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),

            // Payment ID
            const SizedBox(height: 8),
            Text(
              'Payment ID: ${payment['paymentId'] ?? 'N/A'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.withOpacity(0.7),
                fontFamily: 'monospace',
              ),
            ),

            // Review Button (only for completed payments)
            if (payment['paymentStatus'] == 'completed') ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _buildReviewButton(payment),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        text = 'Completed';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'failed':
        color = Colors.red;
        text = 'Failed';
        break;
      case 'refunded':
        color = Colors.blue;
        text = 'Refunded';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewButton(Map<String, dynamic> payment) {
    String lawyerId = payment['lawyerId'] ?? '';
    bool hasReviewed = _hasReviewed[lawyerId] ?? false;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: hasReviewed ? null : () => _navigateToReview(payment),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasReviewed
              ? Colors.grey.withOpacity(0.3)
              : const Color(0xFF8B4513),
          foregroundColor: hasReviewed ? Colors.grey : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: hasReviewed ? 0 : 2,
        ),
        icon: Icon(hasReviewed ? Icons.check_circle : Icons.star, size: 20),
        label: Text(
          hasReviewed ? 'Review Submitted' : 'Write Review',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
