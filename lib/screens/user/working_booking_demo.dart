import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/consultation_booking_service.dart';
import '../../services/http_email_service.dart';
import '../../constants/app_constants.dart';

class WorkingBookingDemo extends StatefulWidget {
  const WorkingBookingDemo({super.key});

  @override
  State<WorkingBookingDemo> createState() => _WorkingBookingDemoState();
}

class _WorkingBookingDemoState extends State<WorkingBookingDemo> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  String _selectedCategory = 'General';
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isTestingSMTP = false;

  final List<String> _categories = [
    'General',
    'Criminal Law',
    'Family Law',
    'Property Law',
    'Business Law',
  ];

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Working Booking Demo'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDemoHeader(),
              const SizedBox(height: 20),
              _buildBookingForm(),
              const SizedBox(height: 20),
              _buildStatusMessage(),
              const SizedBox(height: 20),
              _buildBookButton(),
              const SizedBox(height: 20),
              _buildSMTPTestButton(),
              const SizedBox(height: 20),
              _buildSimpleEmailTestButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B4513).withOpacity(0.1),
                border: Border.all(color: const Color(0xFF8B4513), width: 2),
              ),
              child: const Icon(
                Icons.gavel,
                size: 40,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ahmed Ali Khan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Criminal Law Specialist',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                const Text(
                  '4.8',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.work, color: Colors.grey, size: 20),
                const SizedBox(width: 4),
                const Text('8 years', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Text(
                'Consultation Fee: PKR 5,000',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book Consultation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
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
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
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

  Widget _buildStatusMessage() {
    if (_statusMessage.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _statusMessage.contains('✅') ? Icons.check_circle : Icons.info,
              color: _statusMessage.contains('✅') ? Colors.green : Colors.blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: _statusMessage.contains('✅')
                      ? Colors.green
                      : Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
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
                'Book Consultation - PKR 5,250',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        // Use proper date format for parsing
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

    try {
      setState(() {
        _isLoading = true;
        _statusMessage = '🔄 Processing booking...';
      });

      // Get current user
      final session = await AuthService.getSavedUserSession();
      String userId = session['userId'] as String;

      // Use demo lawyer ID
      String demoLawyerId = 'demo_lawyer_ahmed_khan';

      setState(() {
        _statusMessage = '📅 Creating consultation...';
      });

      // Test booking
      bool success = await ConsultationBookingService.bookConsultation(
        userId: userId,
        lawyerId: demoLawyerId,
        consultationType: 'paid',
        consultationDate: _dateController.text,
        consultationTime: _timeController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
      );

      if (success) {
        setState(() {
          _statusMessage =
              '✅ Booking successful! Consultation created and emails sent.';
        });

        // Clear form
        _descriptionController.clear();
        _dateController.clear();
        _timeController.clear();
        _selectedCategory = 'General';

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Consultation booked successfully! Check your email for details.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _statusMessage = '❌ Booking failed. Please try again.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to book consultation. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSMTPTestButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isTestingSMTP ? null : _testSMTPConnection,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isTestingSMTP
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
                  Text('Testing SMTP...'),
                ],
              )
            : const Text(
                'Test HTTP Email Service',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _testSMTPConnection() async {
    try {
      setState(() {
        _isTestingSMTP = true;
        _statusMessage = '🧪 Testing HTTP email service...';
      });

      bool success = await HTTPEmailService.sendSimpleTestEmailHTTP(
        'sarim@sarimtools.com',
      );

      if (success) {
        setState(() {
          _statusMessage =
              '✅ HTTP email service working! Emails are being sent.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ HTTP email service test successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _statusMessage = '❌ HTTP email service failed. Check configuration.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ HTTP email service test failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ HTTP email test error: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ HTTP email test error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isTestingSMTP = false);
    }
  }

  Widget _buildSimpleEmailTestButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isTestingSMTP ? null : _testSimpleEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isTestingSMTP
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
                  Text('Sending Test Email...'),
                ],
              )
            : const Text(
                'Send Test Email',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _testSimpleEmail() async {
    try {
      setState(() {
        _isTestingSMTP = true;
        _statusMessage = '📧 Sending test email via HTTP...';
      });

      // Use a test email address
      String testEmail = 'sarim@sarimtools.com';

      bool success = await HTTPEmailService.sendSimpleTestEmailHTTP(testEmail);

      if (success) {
        setState(() {
          _statusMessage = '✅ Test email sent successfully to $testEmail!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Test email sent to $testEmail!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _statusMessage =
              '❌ Test email failed. Check HTTP email configuration.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Test email failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Test email error: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Test email error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isTestingSMTP = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}
