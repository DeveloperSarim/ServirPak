import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/withdrawal_service.dart';

class WithdrawalScreen extends StatefulWidget {
  final String lawyerId;
  final String lawyerName;
  final String lawyerEmail;
  final double currentBalance;

  const WithdrawalScreen({
    Key? key,
    required this.lawyerId,
    required this.lawyerName,
    required this.lawyerEmail,
    required this.currentBalance,
  }) : super(key: key);

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ibanController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  double _fees = 0.0;
  double _netAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateFees);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ibanController.dispose();
    _accountHolderNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateFees() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount > 0) {
      setState(() {
        _fees = amount * 0.05; // 5% fees
        _netAmount = amount - _fees;
      });
    } else {
      setState(() {
        _fees = 0.0;
        _netAmount = 0.0;
      });
    }
  }

  Future<void> _submitWithdrawalRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    // Check minimum withdrawal amount
    if (amount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum withdrawal amount is Rs. 10,000'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if amount is greater than current balance
    if (amount > widget.currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance for withdrawal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await WithdrawalService.createWithdrawalRequest(
        lawyerId: widget.lawyerId,
        lawyerName: widget.lawyerName,
        lawyerEmail: widget.lawyerEmail,
        amount: amount,
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        iban: _ibanController.text.trim(),
        accountHolderName: _accountHolderNameController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit withdrawal request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error submitting withdrawal request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Request Withdrawal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8B4513),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 20),
              _buildWithdrawalForm(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          const Icon(
            Icons.account_balance_wallet,
            size: 40,
            color: Color(0xFF8B4513),
          ),
          const SizedBox(height: 10),
          const Text(
            'Available Balance',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Rs. ${widget.currentBalance.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Minimum withdrawal: Rs. 10,000',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalForm() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Withdrawal Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
          const SizedBox(height: 20),
          _buildAmountField(),
          const SizedBox(height: 20),
          _buildBankDetailsSection(),
          const SizedBox(height: 20),
          _buildFeesCalculation(),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'Withdrawal Amount',
        hintText: 'Enter amount (minimum Rs. 10,000)',
        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF8B4513)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF8B4513)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter withdrawal amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount < 10000) {
          return 'Minimum withdrawal amount is Rs. 10,000';
        }
        if (amount > widget.currentBalance) {
          return 'Insufficient balance';
        }
        return null;
      },
    );
  }

  Widget _buildBankDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bank Account Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _bankNameController,
          decoration: InputDecoration(
            labelText: 'Bank Name',
            hintText: 'e.g., HBL, MCB, UBL',
            prefixIcon: const Icon(
              Icons.account_balance,
              color: Color(0xFF8B4513),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B4513)),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter bank name';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _accountNumberController,
          decoration: InputDecoration(
            labelText: 'Account Number',
            hintText: 'Enter your account number',
            prefixIcon: const Icon(Icons.credit_card, color: Color(0xFF8B4513)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B4513)),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter account number';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _ibanController,
          decoration: InputDecoration(
            labelText: 'IBAN',
            hintText: 'Enter your IBAN',
            prefixIcon: const Icon(Icons.receipt, color: Color(0xFF8B4513)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B4513)),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter IBAN';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _accountHolderNameController,
          decoration: InputDecoration(
            labelText: 'Account Holder Name',
            hintText: 'Name as it appears on bank account',
            prefixIcon: const Icon(Icons.person, color: Color(0xFF8B4513)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B4513)),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter account holder name';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Notes (Optional)',
            hintText: 'Any additional information...',
            prefixIcon: const Icon(Icons.note, color: Color(0xFF8B4513)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B4513)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeesCalculation() {
    if (_amountController.text.isEmpty ||
        double.tryParse(_amountController.text) == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Calculation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Withdrawal Amount:'),
              Text(
                'Rs. ${_amountController.text}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Platform Fee (5%):'),
              Text(
                'Rs. ${_fees.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Amount:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Rs. ${_netAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitWithdrawalRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B4513),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Submit Withdrawal Request',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
