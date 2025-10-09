import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/lawyer_model.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../constants/app_constants.dart';
import '../user/lawyer_booking_screen.dart';

class LawyerDetailsScreen extends StatefulWidget {
  final LawyerModel? lawyer;
  final String? lawyerId;
  final Map<String, dynamic>? lawyerData;

  const LawyerDetailsScreen({
    super.key,
    this.lawyer,
    this.lawyerId,
    this.lawyerData,
  });

  @override
  State<LawyerDetailsScreen> createState() => _LawyerDetailsScreenState();
}

class _LawyerDetailsScreenState extends State<LawyerDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;
  final ReviewService _reviewService = ReviewService();
  LawyerModel? _currentLawyer;
  int _consultationCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeLawyer();
    _loadReviews();
    _loadConsultationCount();
  }

  void _initializeLawyer() {
    if (widget.lawyer != null) {
      _currentLawyer = widget.lawyer;
      print('🔍 LawyerDetailsScreen: Using provided lawyer model');
    } else if (widget.lawyerData != null) {
      // Check if profileImage exists in lawyers collection first
      String? profileImage = widget.lawyerData!['profileImage'] as String?;

      if (profileImage == null || profileImage.isEmpty) {
        print(
          '🔄 LawyerDetailsScreen: No profile image in lawyers collection, will check users collection later',
        );
      } else {
        print(
          '✅ LawyerDetailsScreen: Found profile image in lawyers collection: $profileImage',
        );
      }

      // Create LawyerModel from lawyerData
      _currentLawyer = LawyerModel(
        id: widget.lawyerId ?? 'unknown',
        userId: widget.lawyerData!['userId'] as String? ?? 'unknown',
        email: widget.lawyerData!['email'] as String? ?? 'lawyer@servipak.com',
        name: widget.lawyerData!['name'] as String? ?? 'Unknown Lawyer',
        phone: widget.lawyerData!['phone'] as String? ?? '+92-300-0000000',
        status: widget.lawyerData!['status'] as String? ?? 'verified',
        specialization:
            widget.lawyerData!['specialization'] as String? ??
            'General Practice',
        experience: widget.lawyerData!['experience'] as String? ?? '0 years',
        barCouncilNumber:
            widget.lawyerData!['barCouncilNumber'] as String? ?? 'BC-2023-000',
        bio: widget.lawyerData!['bio'] as String? ?? 'Experienced lawyer',
        rating: (widget.lawyerData!['rating'] as num?)?.toDouble() ?? 0.0,
        totalCases: widget.lawyerData!['totalCases'] as int? ?? 0,
        languages: widget.lawyerData!['languages'] is List
            ? List<String>.from(widget.lawyerData!['languages'])
            : widget.lawyerData!['languages'] is String
            ? [widget.lawyerData!['languages'] as String]
            : ['Urdu', 'English'],
        address:
            widget.lawyerData!['address'] as String? ?? 'Address not provided',
        city: widget.lawyerData!['city'] as String? ?? 'Unknown',
        province: widget.lawyerData!['province'] as String? ?? 'Unknown',
        profileImage: profileImage,
        education: widget.lawyerData!['education'] as String?,
        officeAddress: widget.lawyerData!['officeAddress'] as String?,
        officeHours: widget.lawyerData!['officeHours'] as String?,
        consultationFee: widget.lawyerData!['consultationFee'] as String?,
        certifications: widget.lawyerData!['certifications'] as String?,
        awards: widget.lawyerData!['awards'] as String?,
        createdAt: DateTime.now(),
      );

      // If no profile image, try to fetch from users collection
      if (profileImage == null || profileImage.isEmpty) {
        _fetchProfileImageFromUsers();
      }
    }
  }

  Future<void> _fetchProfileImageFromUsers() async {
    try {
      if (_currentLawyer != null && widget.lawyerId != null) {
        print(
          '🔄 LawyerDetailsScreen: Checking users collection for lawyer: ${widget.lawyerId}',
        );
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(widget.lawyerId!)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          String? userProfileImage = userData['profileImage'] as String?;

          if (userProfileImage != null && userProfileImage.isNotEmpty) {
            print(
              '✅ LawyerDetailsScreen: Found profile image in users collection: $userProfileImage',
            );
            setState(() {
              _currentLawyer = _currentLawyer!.copyWith(
                profileImage: userProfileImage,
              );
            });
          } else {
            print(
              '⚠️ LawyerDetailsScreen: No profile image found in users collection',
            );
          }
        }
      }
    } catch (e) {
      print(
        '❌ LawyerDetailsScreen: Error fetching profile image from users: $e',
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => _isLoadingReviews = true);
      if (_currentLawyer != null) {
        final reviews = await _reviewService.getLawyerReviews(
          _currentLawyer!.id,
        );
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      } else {
        setState(() => _isLoadingReviews = false);
      }
    } catch (e) {
      setState(() => _isLoadingReviews = false);
      print('Error loading reviews: $e');
    }
  }

  Future<void> _loadConsultationCount() async {
    try {
      if (_currentLawyer != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection(AppConstants.consultationsCollection)
            .where('lawyerId', isEqualTo: _currentLawyer!.id)
            .get();

        setState(() {
          _consultationCount = querySnapshot.docs.length;
        });

        print(
          '🔍 LawyerDetailsScreen: Loaded ${_consultationCount} consultations for ${_currentLawyer!.name}',
        );
      }
    } catch (e) {
      print('❌ Error loading consultation count: $e');
    }
  }

  ImageProvider? _getProfileImage() {
    if (_currentLawyer?.profileImage != null &&
        _currentLawyer!.profileImage!.isNotEmpty) {
      print(
        '🔍 LawyerDetailsScreen: Using profile image: ${_currentLawyer!.profileImage}',
      );
      return NetworkImage(_currentLawyer!.profileImage!);
    }

    print(
      '⚠️ LawyerDetailsScreen: No profile image available for ${_currentLawyer?.name}',
    );
    return null;
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
                    backgroundImage: _getProfileImage(),
                    child: _getProfileImage() == null
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
                        _currentLawyer?.name ?? 'Unknown Lawyer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentLawyer?.specialization ?? 'General Practice',
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
                    _currentLawyer?.experience ?? '0 years',
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
                    '$_consultationCount',
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
            _currentLawyer?.bio ?? 'No bio available yet.',
            Icons.description,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Specializations',
            _currentLawyer?.specialization ?? 'General Practice',
            Icons.gavel,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Languages',
            'English, Urdu${_currentLawyer?.languages?.isNotEmpty == true ? ', ${_currentLawyer!.languages!.join(', ')}' : ''}',
            Icons.language,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Office Location',
            _currentLawyer?.address ?? 'Not specified',
            Icons.location_on,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Consultation Fee',
            'PKR ${_currentLawyer?.consultationFee ?? 'Contact for rates'}',
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
            _currentLawyer?.education ?? 'Educational background not specified',
            Icons.school,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Bar Council Number',
            _currentLawyer?.barCouncilNumber ?? 'Not specified',
            Icons.badge,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Certifications',
            _currentLawyer?.certifications is List
                ? (_currentLawyer!.certifications as List<String>?)?.join(
                        ', ',
                      ) ??
                      'No certifications'
                : _currentLawyer?.certifications is String
                ? _currentLawyer!.certifications as String
                : 'No certifications available',
            Icons.verified,
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            'Awards & Recognition',
            _currentLawyer?.awards is List
                ? (_currentLawyer!.awards as List<String>?)?.join(', ') ??
                      'No awards'
                : _currentLawyer?.awards is String
                ? _currentLawyer!.awards as String
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
            _currentLawyer?.phone ?? 'Not provided',
            Icons.phone,
            Colors.green,
          ),

          const SizedBox(height: 12),

          _buildContactCard(
            'Email Address',
            _currentLawyer?.email ?? 'Not provided',
            Icons.email,
            Colors.blue,
          ),

          const SizedBox(height: 12),

          _buildContactCard(
            'Office Address',
            _currentLawyer?.address ?? 'Not specified',
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
                    _currentLawyer?.officeHours ?? 'Office hours not specified',
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
              SnackBar(
                content: Text('Calling ${_currentLawyer?.name ?? 'lawyer'}...'),
              ),
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
        // Navigate to consultation booking screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LawyerBookingScreen(
              lawyerId: _currentLawyer?.id ?? widget.lawyerId ?? '',
              lawyerData: _currentLawyer != null
                  ? {
                      'id': _currentLawyer!.id,
                      'userId': _currentLawyer!.userId,
                      'name': _currentLawyer!.name,
                      'email': _currentLawyer!.email,
                      'phone': _currentLawyer!.phone,
                      'specialization': _currentLawyer!.specialization,
                      'experience': _currentLawyer!.experience,
                      'rating': _currentLawyer!.rating,
                      'profileImage': _currentLawyer!.profileImage,
                      'consultationFee': _currentLawyer!.consultationFee,
                      'officeHours': _currentLawyer!.officeHours,
                    }
                  : widget.lawyerData ?? {},
            ),
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
