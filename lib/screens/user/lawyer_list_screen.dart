import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../services/realtime_chat_service.dart';
import '../../services/review_service.dart';
import '../../constants/app_constants.dart';
import 'lawyer_booking_screen.dart';
import '../lawyer/lawyer_details_screen.dart';
import 'user_chat_screen.dart';

class LawyerListScreen extends StatefulWidget {
  const LawyerListScreen({super.key});

  @override
  State<LawyerListScreen> createState() => _LawyerListScreenState();
}

class _LawyerListScreenState extends State<LawyerListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'All';
  String _selectedCity = 'All';
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final session = await AuthService.getSavedUserSession();
      String userId = session['userId'] as String;

      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _currentUser = UserModel.fromFirestore(userDoc);
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Find Lawyers',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),

          // Lawyers List
          Expanded(child: _buildLawyersList()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Specialization Filter with Icons
          Row(
            children: [
              const Icon(Icons.category, color: Color(0xFF8B4513), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Specialization:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _getSpecializationItems(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // City Filter
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF8B4513), size: 20),
              const SizedBox(width: 8),
              const Text(
                'City:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _getCityItems(),
                  onChanged: (value) => setState(() => _selectedCity = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLawyersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getLawyersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading lawyers: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No lawyers found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Try adjusting your filters',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildLawyerCard(doc.id, data);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getLawyersStream() {
    // Show both verified and pending lawyers, but prioritize verified ones
    Query query = _firestore
        .collection(AppConstants.lawyersCollection)
        .where(
          'status',
          whereIn: [AppConstants.verifiedStatus, AppConstants.pendingStatus],
        );

    if (_selectedCategory != 'All') {
      query = query.where('specialization', isEqualTo: _selectedCategory);
    }

    if (_selectedCity != 'All') {
      query = query.where('city', isEqualTo: _selectedCity);
    }

    return query.snapshots();
  }

  List<DropdownMenuItem<String>> _getSpecializationItems() {
    return [
      const DropdownMenuItem(
        value: 'All',
        child: Row(
          children: [
            Icon(Icons.all_inclusive, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text('All Specializations'),
          ],
        ),
      ),
      const DropdownMenuItem(
        value: 'Tax Law',
        child: Row(
          children: [
            Icon(Icons.account_balance, size: 16, color: Colors.blue),
            SizedBox(width: 8),
            Text('Tax Law'),
          ],
        ),
      ),
      const DropdownMenuItem(
        value: 'Criminal Law',
        child: Row(
          children: [
            Icon(Icons.gavel, size: 16, color: Colors.red),
            SizedBox(width: 8),
            Text('Criminal Law'),
          ],
        ),
      ),
      const DropdownMenuItem(
        value: 'Family Law',
        child: Row(
          children: [
            Icon(Icons.family_restroom, size: 16, color: Colors.green),
            SizedBox(width: 8),
            Text('Family Law'),
          ],
        ),
      ),
      const DropdownMenuItem(
        value: 'Corporate Law',
        child: Row(
          children: [
            Icon(Icons.business, size: 16, color: Colors.purple),
            SizedBox(width: 8),
            Text('Corporate Law'),
          ],
        ),
      ),
      const DropdownMenuItem(
        value: 'Property Law',
        child: Row(
          children: [
            Icon(Icons.home, size: 16, color: Colors.orange),
            SizedBox(width: 8),
            Text('Property Law'),
          ],
        ),
      ),
      const DropdownMenuItem(
        value: 'Immigration Law',
        child: Row(
          children: [
            Icon(Icons.flight_takeoff, size: 16, color: Colors.teal),
            SizedBox(width: 8),
            Text('Immigration Law'),
          ],
        ),
      ),
      const DropdownMenuItem(
        value: 'Labor Law',
        child: Row(
          children: [
            Icon(Icons.work, size: 16, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Labor Law'),
          ],
        ),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _getCityItems() {
    return [
      const DropdownMenuItem(
        value: 'All',
        child: Row(
          children: [
            Icon(Icons.location_city, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text('All Cities'),
          ],
        ),
      ),
      const DropdownMenuItem(
        value: 'Karachi',
        child: Row(
          children: [
            Icon(Icons.location_city, size: 16, color: Colors.blue),
            SizedBox(width: 8),
            Text('Karachi'),
          ],
        ),
      ),
      const DropdownMenuItem(
        value: 'Lahore',
        child: Row(
          children: [
            Icon(Icons.location_city, size: 16, color: Colors.green),
            SizedBox(width: 8),
            Text('Lahore'),
          ],
        ),
      ),
      const DropdownMenuItem(
        value: 'Islamabad',
        child: Row(
          children: [
            Icon(Icons.location_city, size: 16, color: Colors.red),
            SizedBox(width: 8),
            Text('Islamabad'),
          ],
        ),
      ),
      const DropdownMenuItem(
        value: 'Rawalpindi',
        child: Row(
          children: [
            Icon(Icons.location_city, size: 16, color: Colors.orange),
            SizedBox(width: 8),
            Text('Rawalpindi'),
          ],
        ),
      ),
      const DropdownMenuItem(
        value: 'Faisalabad',
        child: Row(
          children: [
            Icon(Icons.location_city, size: 16, color: Colors.purple),
            SizedBox(width: 8),
            Text('Faisalabad'),
          ],
        ),
      ),
    ];
  }

  Widget _buildLawyerCard(String lawyerId, Map<String, dynamic> data) {
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
                // Profile Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF8B4513),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: FutureBuilder<String?>(
                      future: _getLawyerProfileImage(lawyerId, data),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF8B4513),
                            ),
                          );
                        }

                        final profileImage = snapshot.data;
                        print(
                          '🔍 LawyerListScreen: Lawyer ${data['name']} - ProfileImage: $profileImage',
                        );

                        if (profileImage != null && profileImage.isNotEmpty) {
                          return Image.network(
                            profileImage,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF8B4513),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print(
                                '❌ LawyerListScreen: Error loading image for ${data['name']}: $error',
                              );
                              return const Icon(
                                Icons.person,
                                size: 30,
                                color: Color(0xFF8B4513),
                              );
                            },
                          );
                        } else {
                          print(
                            '⚠️ LawyerListScreen: No profile image for ${data['name']}',
                          );
                          return const Icon(
                            Icons.person,
                            size: 30,
                            color: Color(0xFF8B4513),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Lawyer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] as String? ?? 'Unknown Lawyer',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['specialization'] ?? 'General Law',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Reviews Overview Section
                      _buildReviewsOverview(lawyerId),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.work, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _getCalculatedExperience(data),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${data['city'] as String? ?? 'Unknown'}, ${data['province'] as String? ?? 'Unknown'}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Description
            if (data['bio'] != null &&
                (data['bio'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                data['bio'] as String? ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Action Buttons - Responsive Layout
            const SizedBox(height: 16),
            // Use responsive layout based on screen width
            LayoutBuilder(
              builder: (context, constraints) {
                // If screen is too narrow, stack buttons vertically
                if (constraints.maxWidth < 400) {
                  return Column(
                    children: [
                      // View Details Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _viewLawyerDetails(lawyerId, data),
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('View Details'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF8B4513)),
                            foregroundColor: const Color(0xFF8B4513),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Chat and Book buttons in a row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _startChatWithLawyer(lawyerId, data),
                              icon: const Icon(Icons.chat, size: 16),
                              label: const Text('Chat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _bookLawyer(lawyerId, data),
                              icon: const Icon(Icons.book_online, size: 16),
                              label: const Text('Book'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B4513),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // For wider screens, use horizontal layout with flexible sizing
                  return Row(
                    children: [
                      // View Details - flexible width
                      Flexible(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () => _viewLawyerDetails(lawyerId, data),
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('View Details'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF8B4513)),
                            foregroundColor: const Color(0xFF8B4513),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Chat - fixed width
                      Flexible(
                        flex: 1,
                        child: ElevatedButton.icon(
                          onPressed: () => _startChatWithLawyer(lawyerId, data),
                          icon: const Icon(Icons.chat, size: 16),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Book - fixed width
                      Flexible(
                        flex: 1,
                        child: ElevatedButton.icon(
                          onPressed: () => _bookLawyer(lawyerId, data),
                          icon: const Icon(Icons.book_online, size: 16),
                          label: const Text('Book'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewLawyerDetails(
    String lawyerId,
    Map<String, dynamic> data,
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LawyerDetailsScreen(lawyerId: lawyerId, lawyerData: data),
      ),
    );
  }

  Future<String?> _getLawyerProfileImage(
    String lawyerId,
    Map<String, dynamic> data,
  ) async {
    try {
      // First check if profileImage exists in lawyers collection
      String? profileImage = data['profileImage'] as String?;

      if (profileImage != null && profileImage.isNotEmpty) {
        print(
          '✅ LawyerListScreen: Found profile image in lawyers collection: $profileImage',
        );
        return profileImage;
      }

      // If not found, check users collection
      print(
        '🔄 LawyerListScreen: Checking users collection for lawyer: $lawyerId',
      );
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(lawyerId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String? userProfileImage = userData['profileImage'] as String?;

        if (userProfileImage != null && userProfileImage.isNotEmpty) {
          print(
            '✅ LawyerListScreen: Found profile image in users collection: $userProfileImage',
          );
          return userProfileImage;
        }
      }

      print(
        '⚠️ LawyerListScreen: No profile image found for lawyer: $lawyerId',
      );
      return null;
    } catch (e) {
      print('❌ LawyerListScreen: Error fetching profile image: $e');
      return null;
    }
  }

  Future<void> _bookLawyer(String lawyerId, Map<String, dynamic> data) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to book consultation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to booking screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LawyerBookingScreen(lawyerId: lawyerId, lawyerData: data),
      ),
    );
  }

  // Start chat with lawyer
  Future<void> _startChatWithLawyer(
    String lawyerId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get current user
      if (_currentUser == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to start chatting'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Extract lawyer information
      String lawyerName = data['name'] as String? ?? 'Unknown Lawyer';
      String lawyerEmail = data['email'] as String? ?? 'lawyer@servipak.com';
      String? lawyerProfileImage = data['profileImage'] as String?;

      // Debug: Print lawyer profile image
      print(
        '🔍 LawyerListScreen: Lawyer ${lawyerName} - ProfileImage: $lawyerProfileImage',
      );

      // Create or get existing chat
      await RealtimeChatService.createChatRealtime(
        lawyerId: lawyerId,
        userId: _currentUser!.id,
      );

      // Create ChatModel for navigation
      ChatModel chat = ChatModel(
        id: _generateChatId(lawyerId, _currentUser!.id),
        lawyerId: lawyerId,
        lawyerName: lawyerName,
        lawyerEmail: lawyerEmail,
        lawyerProfileImage: lawyerProfileImage,
        userId: _currentUser!.id,
        userName: _currentUser!.name,
        userEmail: _currentUser!.email,
        userProfileImage: _currentUser!.profileImage,
        createdAt: DateTime.now(),
        consultationIds: [],
      );

      Navigator.pop(context); // Close loading dialog

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserChatScreen(chat: chat)),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Generate unique chat ID
  String _generateChatId(String lawyerId, String userId) {
    List<String> ids = [lawyerId, userId];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Build reviews overview section
  Widget _buildReviewsOverview(String lawyerId) {
    // Check if lawyer ID is valid
    if (lawyerId.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.star, color: Colors.grey, size: 16),
          const SizedBox(width: 4),
          const Text(
            'No reviews yet',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getLawyerReviews(lawyerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Loading...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Row(
            children: [
              const Icon(Icons.star, color: Colors.grey, size: 16),
              const SizedBox(width: 4),
              const Text(
                'No reviews yet',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          );
        }

        final reviews = snapshot.data!;
        final averageRating = _calculateAverageRating(reviews);
        final reviewCount = reviews.length;

        return Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              averageRating.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Text(
              '($reviewCount reviews)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        );
      },
    );
  }

  // Get lawyer reviews from Firebase
  Future<List<Map<String, dynamic>>> _getLawyerReviews(String lawyerId) async {
    try {
      print('🔍 Getting reviews for lawyer: $lawyerId');
      final reviewService = ReviewService();
      final reviews = await reviewService.getLawyerReviews(lawyerId);
      print('📊 Found ${reviews.length} reviews for lawyer: $lawyerId');

      if (reviews.isNotEmpty) {
        print(
          '✅ Sample review: ${reviews.first.clientName} - ${reviews.first.rating} stars',
        );
      }

      return reviews
          .map(
            (review) => {
              'rating': review.rating,
              'comment': review.comment,
              'clientName': review.clientName,
              'createdAt': review.createdAt,
            },
          )
          .toList();
    } catch (e) {
      print('❌ Error getting lawyer reviews: $e');
      return [];
    }
  }

  // Calculate average rating from reviews
  double _calculateAverageRating(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return 0.0;

    double totalRating = 0.0;
    for (var review in reviews) {
      totalRating += (review['rating'] as double? ?? 0.0);
    }

    return totalRating / reviews.length;
  }

  String _getCalculatedExperience(Map<String, dynamic> data) {
    // Check if firstCaseDate exists
    if (data['firstCaseDate'] != null) {
      try {
        final firstCaseDate = (data['firstCaseDate'] as Timestamp).toDate();
        final now = DateTime.now();
        final difference = now.difference(firstCaseDate);
        final years = (difference.inDays / 365).floor();
        final months = ((difference.inDays % 365) / 30).floor();

        if (years > 0) {
          return months > 0 ? '$years years $months months' : '$years years';
        } else if (months > 0) {
          return '$months months';
        } else {
          return 'Less than 1 month';
        }
      } catch (e) {
        // Fallback to manual experience
        return '${data['experience'] as String? ?? '0'} years';
      }
    }

    // Fallback to manual experience
    return '${data['experience'] as String? ?? '0'} years';
  }
}
