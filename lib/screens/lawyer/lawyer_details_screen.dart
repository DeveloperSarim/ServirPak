import 'package:flutter/material.dart';
import '../../models/lawyer_model.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';

class LawyerDetailsScreen extends StatefulWidget {
  final LawyerModel lawyer;

  const LawyerDetailsScreen({super.key, required this.lawyer});

  @override
  State<LawyerDetailsScreen> createState() => _LawyerDetailsScreenState();
}

class _LawyerDetailsScreenState extends State<LawyerDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;
  final ReviewService _reviewService = ReviewService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => _isLoadingReviews = true);
      final reviews = await _reviewService.getLawyerReviews(widget.lawyer.id);
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => _isLoadingReviews = false);
      print('Error loading reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildLawyerHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildReviewsTab(),
                _buildEducationTab(),
                _buildContactTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildBookConsultationButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF8B4513),
      foregroundColor: Colors.white,
      title: const Text('Lawyer Details'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share lawyer profile
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Profile shared!')));
          },
        ),
      ],
    );
  }

  Widget _buildLawyerHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B4513), Color(0xFFA0522D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Image and Basic Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: widget.lawyer.profileImage != null
                        ? NetworkImage(widget.lawyer.profileImage!)
                        : null,
                    child: widget.lawyer.profileImage == null
                        ? const Icon(
                            Icons.gavel,
                            size: 50,
                            color: Color(0xFF8B4513),
                          )
                        : null,
                  ),
                ),

                const SizedBox(width: 20),

                // Basic Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lawyer.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.lawyer.specialization,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            _calculateRating(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${_reviews.length} reviews)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Experience',
                    widget.lawyer.experience,
                    Icons.work,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Success Rate',
                    '${_calculateSuccessRate()}%',
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Consultations',
                    '${_calculateTotalConsultations()}',
                    Icons.handshake,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF8B4513),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF8B4513),
        tabs: const [
          Tab(icon: Icon(Icons.person), text: 'Overview'),
          Tab(icon: Icon(Icons.rate_review), text: 'Reviews'),
          Tab(icon: Icon(Icons.school), text: 'Education'),
          Tab(icon: Icon(Icons.contact_phone), text: 'Contact'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Professional Summary',
            widget.lawyer.bio ?? 'No bio available yet.',
            Icons.description,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Specializations',
            widget.lawyer.specialization,
            Icons.gavel,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Languages',
            'English, Urdu${widget.lawyer.languages?.isNotEmpty == true ? ', ${widget.lawyer.languages!.join(', ')}' : ''}',
            Icons.language,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Office Location',
            widget.lawyer.officeAddress ?? 'Not specified',
            Icons.location_on,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Consultation Fee',
            'PKR ${widget.lawyer.consultationFee ?? 'Contact for rates'}',
            Icons.payments,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            Text(
              'Be the first to review this lawyer',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF8B4513),
                  child: Text(
                    review.clientName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(review.createdAt),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStarRating(review.rating),
              ],
            ),

            const SizedBox(height: 12),

            Text(review.comment, style: const TextStyle(fontSize: 14)),

            if (review.consultationType != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  review.consultationType!,
                  style: TextStyle(
                    color: const Color(0xFF8B4513),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEducationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Education',
            widget.lawyer.education ?? 'Educational background not specified',
            Icons.school,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Bar Council Number',
            widget.lawyer.barCouncilNumber,
            Icons.badge,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Certifications',
            widget.lawyer.certifications?.isNotEmpty == true
                ? widget.lawyer.certifications!
                : 'No certifications available',
            Icons.verified,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Awards & Recognition',
            widget.lawyer.awards?.isNotEmpty == true
                ? widget.lawyer.awards!
                : 'No awards listed yet',
            Icons.workspace_premium,
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactCard(
            'Phone Number',
            widget.lawyer.phone,
            Icons.phone,
            Colors.green,
          ),

          const SizedBox(height: 12),

          _buildContactCard(
            'Email Address',
            widget.lawyer.email,
            Icons.email,
            Colors.blue,
          ),

          const SizedBox(height: 12),

          _buildContactCard(
            'Office Address',
            widget.lawyer.officeAddress ?? 'Not specified',
            Icons.location_on,
            Colors.red,
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF8B4513)),
                      const SizedBox(width: 8),
                      const Text(
                        'Office Hours',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.lawyer.officeHours ??
                        'Available 24/7 for urgent consultations',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        subtitle: Text(value),
        onTap: () {
          if (title == 'Phone Number') {
            // Make phone call
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Calling ${widget.lawyer.name}...')),
            );
          } else if (title == 'Email Address') {
            // Send email
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Opening email...')));
          }
        },
      ),
    );
  }

  Widget _buildSectionCard(String title, String content, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF8B4513)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  Widget _buildBookConsultationButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        // Navigate to consultation booking
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking consultation with ${widget.lawyer.name}...'),
          ),
        );
      },
      backgroundColor: const Color(0xFF8B4513),
      label: const Text('Book Consultation'),
      icon: const Icon(Icons.calendar_today),
    );
  }

  String _calculateRating() {
    if (_reviews.isEmpty) return 'Not rated';

    double totalRating = 0;
    for (var review in _reviews) {
      totalRating += review.rating;
    }

    return (totalRating / _reviews.length).toStringAsFixed(1);
  }

  String _calculateSuccessRate() {
    if (_reviews.isEmpty) return '0';

    int successfulConsultations = 0;
    for (var review in _reviews) {
      if (review.rating >= 4.0) {
        successfulConsultations++;
      }
    }

    return ((successfulConsultations / _reviews.length) * 100)
        .round()
        .toString();
  }

  String _calculateTotalConsultations() {
    return _reviews.length.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
