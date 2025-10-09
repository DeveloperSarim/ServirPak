import 'package:flutter/material.dart';
import '../../models/lawyer_wallet_model.dart';
import '../../services/lawyer_wallet_service.dart';
import '../../services/withdrawal_service.dart';
import 'withdrawal_screen.dart';

class LawyerWalletScreen extends StatefulWidget {
  final String lawyerId;
  final String lawyerName;
  final String lawyerEmail;

  const LawyerWalletScreen({
    Key? key,
    required this.lawyerId,
    required this.lawyerName,
    required this.lawyerEmail,
  }) : super(key: key);

  @override
  State<LawyerWalletScreen> createState() => _LawyerWalletScreenState();
}

class _LawyerWalletScreenState extends State<LawyerWalletScreen> {
  LawyerWalletModel? _wallet;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _withdrawalRequests = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load wallet data
      _wallet = await LawyerWalletService.getWallet(widget.lawyerId);

      // Create wallet if it doesn't exist
      if (_wallet == null) {
        _wallet = await LawyerWalletService.createOrGetWallet(
          lawyerId: widget.lawyerId,
          lawyerName: widget.lawyerName,
          lawyerEmail: widget.lawyerEmail,
        );
      }

      // Load transactions
      _transactions = await LawyerWalletService.getWalletTransactions(
        widget.lawyerId,
      );

      // Load withdrawal requests
      var withdrawals = await WithdrawalService.getLawyerWithdrawals(
        widget.lawyerId,
      );
      _withdrawalRequests = withdrawals.map((w) => w.toMap()).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading wallet data: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading wallet data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshWallet() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadWalletData();

    setState(() {
      _isRefreshing = false;
    });
  }

  void _navigateToWithdrawal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawalScreen(
          lawyerId: widget.lawyerId,
          lawyerName: widget.lawyerName,
          lawyerEmail: widget.lawyerEmail,
          currentBalance: _wallet?.currentBalance ?? 0.0,
        ),
      ),
    ).then((_) {
      // Refresh wallet data when returning from withdrawal screen
      _refreshWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8B4513),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshWallet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildWalletHeader(),
                    const SizedBox(height: 20),
                    _buildWalletStats(),
                    const SizedBox(height: 20),
                    _buildWithdrawalButton(),
                    const SizedBox(height: 20),
                    _buildTransactionsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWalletHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF8B4513),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              'Current Balance',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Rs. ${_wallet?.currentBalance.toStringAsFixed(0) ?? '0'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Available for withdrawal',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Total Earnings',
              value: 'Rs. ${_wallet?.totalEarnings.toStringAsFixed(0) ?? '0'}',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              title: 'Total Withdrawn',
              value: 'Rs. ${_wallet?.totalWithdrawn.toStringAsFixed(0) ?? '0'}',
              icon: Icons.trending_down,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: (_wallet?.currentBalance ?? 0) >= 10000
              ? _navigateToWithdrawal
              : null,
          icon: const Icon(Icons.account_balance, color: Colors.white),
          label: const Text(
            'Request Withdrawal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B4513),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF8B4513)),
                const SizedBox(width: 8),
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
                const Spacer(),
                if (_isRefreshing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          if (_transactions.isEmpty && _withdrawalRequests.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No transactions yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length + _withdrawalRequests.length,
              itemBuilder: (context, index) {
                if (index < _transactions.length) {
                  // Show wallet transactions first
                  final transaction = _transactions[index];
                  return _buildTransactionItem(transaction);
                } else {
                  // Show withdrawal requests
                  final withdrawalIndex = index - _transactions.length;
                  final withdrawal = _withdrawalRequests[withdrawalIndex];
                  return _buildWithdrawalItem(withdrawal);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final String type = transaction['type'] ?? '';
    final double amount = (transaction['amount'] ?? 0.0).toDouble();
    final double fees = (transaction['fees'] ?? 0.0).toDouble();
    final double netAmount = (transaction['netAmount'] ?? 0.0).toDouble();
    final String description = transaction['description'] ?? '';
    final DateTime createdAt = transaction['createdAt'] is DateTime
        ? transaction['createdAt'] as DateTime
        : (transaction['createdAt']?.toDate() ?? DateTime.now());

    Color amountColor = Colors.green;
    IconData amountIcon = Icons.add;
    String amountText = '+Rs. ${netAmount.toStringAsFixed(0)}';

    if (type == 'withdrawal_request') {
      amountColor = Colors.orange;
      amountIcon = Icons.remove;
      amountText = '-Rs. ${amount.toStringAsFixed(0)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(amountIcon, color: amountColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (fees > 0)
                  Text(
                    'Fees: Rs. ${fees.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
              ],
            ),
          ),
          Text(
            amountText,
            style: TextStyle(
              color: amountColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalItem(Map<String, dynamic> withdrawal) {
    final double amount = (withdrawal['amount'] ?? 0.0).toDouble();
    final double fees = (withdrawal['fees'] ?? 0.0).toDouble();
    final double netAmount = (withdrawal['netAmount'] ?? 0.0).toDouble();
    final String status = withdrawal['status'] ?? 'pending';
    final String bankName = withdrawal['bankName'] ?? '';
    final DateTime requestedAt = withdrawal['requestedAt'] is DateTime
        ? withdrawal['requestedAt'] as DateTime
        : (withdrawal['requestedAt']?.toDate() ?? DateTime.now());

    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending;
    String statusText = 'Pending';

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'Completed';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdrawal Request - $bankName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(requestedAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (fees > 0)
                      Text(
                        'Fees: Rs. ${fees.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-Rs. ${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (netAmount != amount)
                Text(
                  'Net: Rs. ${netAmount.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
