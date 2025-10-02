import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../models/consultation_model.dart';
import '../../services/auth_service.dart';

class LawyerScheduleScreen extends StatefulWidget {
  const LawyerScheduleScreen({super.key});

  @override
  State<LawyerScheduleScreen> createState() => _LawyerScheduleScreenState();
}

class _LawyerScheduleScreenState extends State<LawyerScheduleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ConsultationModel> _scheduledConsultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledConsultations();
  }

  Future<void> _loadScheduledConsultations() async {
    try {
      final session = await AuthService.getSavedUserSession();
      if (session != null) {
        String lawyerId = session['userId'] as String;

        QuerySnapshot consultationsSnapshot = await _firestore
            .collection(AppConstants.consultationsCollection)
            .where('lawyerId', isEqualTo: lawyerId)
            .where('status', whereIn: ['accepted', 'pending'])
            .orderBy('scheduledAt', descending: false)
            .get();

        _scheduledConsultations = consultationsSnapshot.docs
            .map((doc) => ConsultationModel.fromFirestore(doc))
            .toList();
      }
    } catch (e) {
      print('Error loading scheduled consultations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Schedule Meeting',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF8B4513),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scheduledConsultations.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No scheduled meetings',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Your scheduled consultations will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _scheduledConsultations.length,
              itemBuilder: (context, index) {
                ConsultationModel consultation = _scheduledConsultations[index];
                return _buildScheduleCard(consultation);
              },
            ),
    );
  }

  Widget _buildScheduleCard(ConsultationModel consultation) {
    DateTime scheduledDate = consultation.scheduledAt;
    String dateStr =
        '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}';
    String timeStr =
        '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      consultation.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: _getStatusColor(consultation.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consultation.category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        consultation.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      consultation.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    consultation.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(consultation.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '$dateStr at $timeStr',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'PKR ${consultation.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showConsultationDetails(consultation),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B4513),
                      side: const BorderSide(color: Color(0xFF8B4513)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (consultation.status == 'pending')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateConsultationStatus(
                        consultation.id,
                        'accepted',
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showConsultationDetails(ConsultationModel consultation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(consultation.category),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${consultation.description}'),
            const SizedBox(height: 8),
            Text('Type: ${consultation.type}'),
            const SizedBox(height: 8),
            Text('Status: ${consultation.status}'),
            const SizedBox(height: 8),
            Text('Price: PKR ${consultation.price.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Text('Scheduled: ${consultation.scheduledAt.toString()}'),
          ],
        ),
        actions: [
          if (consultation.status == AppConstants.pendingStatus) ...[
            TextButton(
              onPressed: () {
                _updateConsultationStatus(consultation.id, 'accepted');
                Navigator.pop(context);
              },
              child: const Text('Accept'),
            ),
            TextButton(
              onPressed: () {
                _updateConsultationStatus(consultation.id, 'rejected');
                Navigator.pop(context);
              },
              child: const Text('Reject'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateConsultationStatus(
    String consultationId,
    String status,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.consultationsCollection)
          .doc(consultationId)
          .update({'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Consultation $status successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh data
      await _loadScheduledConsultations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update consultation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
