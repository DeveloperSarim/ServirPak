import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/consultation_service.dart';
import '../../constants/app_constants.dart';
import '../../models/consultation_model.dart';
import '../../models/lawyer_model.dart';

class LawyerAnalyticsScreen extends StatefulWidget {
  final LawyerModel lawyer;

  const LawyerAnalyticsScreen({super.key, required this.lawyer});

  @override
  State<LawyerAnalyticsScreen> createState() => _LawyerAnalyticsScreenState();
}

class _LawyerAnalyticsScreenState extends State<LawyerAnalyticsScreen> {
  List<ConsultationModel> _consultations = [];
  bool _isLoading = true;
  String _selectedPeriod = 'month'; // month, week, year

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      _consultations = await ConsultationService.getConsultationsByLawyerId(
        widget.lawyer.id,
      );
    } catch (e) {
      print('Error loading analytics data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Revenue'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _buildPeriodSelector(),
            const SizedBox(height: 20),

            // Revenue Overview
            _buildRevenueOverview(),
            const SizedBox(height: 20),

            // Performance Metrics
            _buildPerformanceMetrics(),
            const SizedBox(height: 20),

            // Consultation Trends
            _buildConsultationTrends(),
            const SizedBox(height: 20),

            // Top Categories
            _buildTopCategories(),
            const SizedBox(height: 20),

            // Recent Activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPeriodButton('Week', 'week'),
            _buildPeriodButton('Month', 'month'),
            _buildPeriodButton('Year', 'year'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    bool isSelected = _selectedPeriod == value;

    return InkWell(
      onTap: () => setState(() => _selectedPeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B4513) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B4513) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueOverview() {
    double totalRevenue = _getTotalRevenue();
    double monthlyRevenue = _getMonthlyRevenue();
    double weeklyRevenue = _getWeeklyRevenue();
    int totalConsultations = _consultations.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    'Total Revenue',
                    'PKR ${totalRevenue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    'This Month',
                    'PKR ${monthlyRevenue.toStringAsFixed(0)}',
                    Icons.calendar_month,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    'This Week',
                    'PKR ${weeklyRevenue.toStringAsFixed(0)}',
                    Icons.date_range,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    'Total Cases',
                    totalConsultations.toString(),
                    Icons.folder,
                    const Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    double avgRating = widget.lawyer.rating ?? 0.0;
    int completedCases = _consultations
        .where((c) => c.status == AppConstants.completedStatus)
        .length;
    int pendingCases = _consultations
        .where((c) => c.status == AppConstants.pendingStatus)
        .length;
    int totalConsultations = _consultations.length;
    double completionRate = totalConsultations > 0
        ? (completedCases / totalConsultations) * 100
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Rating',
                    avgRating.toStringAsFixed(1),
                    Icons.star,
                    Colors.amber,
                    '${avgRating.toStringAsFixed(1)}/5.0',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Completion Rate',
                    '${completionRate.toStringAsFixed(0)}%',
                    Icons.check_circle,
                    Colors.green,
                    '$completedCases/$totalConsultations',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Pending Cases',
                    pendingCases.toString(),
                    Icons.schedule,
                    Colors.orange,
                    'Awaiting response',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Experience',
                    '${widget.lawyer.experience} years',
                    Icons.work,
                    Colors.blue,
                    'Professional experience',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationTrends() {
    Map<String, int> weeklyTrends = _getWeeklyTrends();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consultation Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: weeklyTrends.length,
                itemBuilder: (context, index) {
                  String day = weeklyTrends.keys.elementAt(index);
                  int count = weeklyTrends[day]!;
                  double maxCount = weeklyTrends.values
                      .reduce((a, b) => a > b ? a : b)
                      .toDouble();
                  double height = maxCount > 0 ? (count / maxCount) * 150 : 0;

                  return Container(
                    width: 40,
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height,
                          width: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B4513),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          day,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          count.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategories() {
    Map<String, int> categoryCounts = _getCategoryCounts();
    List<MapEntry<String, int>> sortedCategories =
        categoryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Legal Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.take(5).map((entry) {
              String category = entry.key;
              int count = entry.value;
              double percentage = _consultations.isNotEmpty
                  ? (count / _consultations.length) * 100
                  : 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF8B4513),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${count} (${percentage.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    List<ConsultationModel> recentConsultations = _consultations
        .take(5)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (recentConsultations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No recent activity',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...recentConsultations.map((consultation) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _getStatusColor(
                          consultation.status,
                        ).withOpacity(0.1),
                        child: Icon(
                          _getStatusIcon(consultation.status),
                          color: _getStatusColor(consultation.status),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              consultation.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${consultation.type} • PKR ${consultation.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _getTimeAgo(consultation.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  // Helper methods
  double _getTotalRevenue() {
    return _consultations
        .where((c) => c.status == AppConstants.completedStatus)
        .fold(0.0, (sum, c) => sum + c.price);
  }

  double _getMonthlyRevenue() {
    DateTime now = DateTime.now();
    DateTime monthStart = DateTime(now.year, now.month, 1);

    return _consultations
        .where(
          (c) =>
              c.status == AppConstants.completedStatus &&
              c.completedAt != null &&
              c.completedAt!.isAfter(monthStart),
        )
        .fold(0.0, (sum, c) => sum + c.price);
  }

  double _getWeeklyRevenue() {
    DateTime now = DateTime.now();
    DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));

    return _consultations
        .where(
          (c) =>
              c.status == AppConstants.completedStatus &&
              c.completedAt != null &&
              c.completedAt!.isAfter(weekStart),
        )
        .fold(0.0, (sum, c) => sum + c.price);
  }

  Map<String, int> _getWeeklyTrends() {
    Map<String, int> trends = {};
    List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (String day in days) {
      trends[day] = 0;
    }

    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      DateTime date = now.subtract(Duration(days: i));
      String dayName = days[date.weekday - 1];

      int count = _consultations.where((c) {
        return c.createdAt.day == date.day &&
            c.createdAt.month == date.month &&
            c.createdAt.year == date.year;
      }).length;

      trends[dayName] = count;
    }

    return trends;
  }

  Map<String, int> _getCategoryCounts() {
    Map<String, int> counts = {};

    for (ConsultationModel consultation in _consultations) {
      counts[consultation.category] = (counts[consultation.category] ?? 0) + 1;
    }

    return counts;
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
