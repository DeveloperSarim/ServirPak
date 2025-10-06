import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../config/cloudinary_config.dart';
import '../../constants/app_constants.dart';
import '../../models/lawyer_model.dart';

class LawyerProfileManagementScreen extends StatefulWidget {
  const LawyerProfileManagementScreen({super.key});

  @override
  State<LawyerProfileManagementScreen> createState() =>
      _LawyerProfileManagementScreenState();
}

class _LawyerProfileManagementScreenState
    extends State<LawyerProfileManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  LawyerModel? _currentLawyer;
  bool _isLoading = false;
  bool _isEditing = false;

  // For web compatibility
  Uint8List? _profileImageBytes;

  // Cities list
  List<String> _cities = [];
  String? _selectedCity;

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _barCouncilController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _educationController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _awardsController = TextEditingController();
  final _officeHoursController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _languagesController = TextEditingController();

  // Case studies
  final List<Map<String, String>> _caseStudies = [];
  final _caseTitleController = TextEditingController();
  final _caseDescriptionController = TextEditingController();
  final _caseOutcomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLawyerData();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.citiesCollection)
          .get();
      setState(() {
        _cities = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
      print('🏙️ Loaded ${_cities.length} cities');
    } catch (e) {
      print('❌ Error loading cities: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _barCouncilController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _educationController.dispose();
    _certificationsController.dispose();
    _awardsController.dispose();
    _officeHoursController.dispose();
    _consultationFeeController.dispose();
    _languagesController.dispose();
    _caseTitleController.dispose();
    _caseDescriptionController.dispose();
    _caseOutcomeController.dispose();
    super.dispose();
  }

  Future<void> _loadLawyerData() async {
    try {
      setState(() => _isLoading = true);

      final session = await AuthService.getSavedUserSession();
      String userId = session['userId'] as String;
      print('🔍 Loading data for user: $userId');

      // Load lawyer data
      DocumentSnapshot lawyerDoc = await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(userId)
          .get();

      // Also load user data for profile image
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (lawyerDoc.exists) {
        Map<String, dynamic> lawyerData =
            lawyerDoc.data() as Map<String, dynamic>;
        print('🔍 Raw Lawyer Firestore data: ${lawyerData['profileImage']}');

        _currentLawyer = LawyerModel.fromFirestore(lawyerDoc);

        // If lawyer doesn't have profile image, try to get from users collection
        if (_currentLawyer?.profileImage?.isEmpty ?? true) {
          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            print('🔍 Raw User Firestore data: ${userData['profileImage']}');

            if (userData['profileImage'] != null &&
                userData['profileImage'].toString().isNotEmpty) {
              print('🔄 Using profile image from users collection');
              _currentLawyer = _currentLawyer?.copyWith(
                profileImage: userData['profileImage'],
              );
            }
          }
        }

        _populateFormFields();

        print('🔍 Final Profile Image URL: ${_currentLawyer?.profileImage}');
        print(
          '🔍 Profile Image exists: ${_currentLawyer?.profileImage?.isNotEmpty}',
        );
        print(
          '🔍 Profile Image length: ${_currentLawyer?.profileImage?.length}',
        );
        print('🔍 Lawyer name: ${_currentLawyer?.name}');

        // Force rebuild
        setState(() {});
      } else {
        print('❌ Lawyer document does not exist for user: $userId');
      }
    } catch (e) {
      print('❌ Error loading lawyer data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateFormFields() {
    if (_currentLawyer != null) {
      _nameController.text = _currentLawyer!.name;
      _phoneController.text = _currentLawyer!.phone;
      _specializationController.text = _currentLawyer!.specialization;
      _experienceController.text = _currentLawyer!.experience;
      _barCouncilController.text = _currentLawyer!.barCouncilNumber;
      _bioController.text = _currentLawyer!.bio ?? '';
      _addressController.text = _currentLawyer!.address ?? '';
      _cityController.text = _currentLawyer!.city ?? '';
      _selectedCity = _currentLawyer!.city;
      _provinceController.text = _currentLawyer!.province ?? '';
      _educationController.text = _currentLawyer!.education ?? '';
      _certificationsController.text = _currentLawyer!.certifications ?? '';
      _awardsController.text = _currentLawyer!.awards ?? '';
      _officeHoursController.text = _currentLawyer!.officeHours ?? '';
      _consultationFeeController.text = _currentLawyer!.consultationFee ?? '';
      _languagesController.text = _currentLawyer!.languages?.join(', ') ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (_currentLawyer == null) return;

    try {
      setState(() => _isLoading = true);

      // Update lawyer document
      await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(_currentLawyer!.id)
          .update({
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'specialization': _specializationController.text.trim(),
            'experience': _experienceController.text.trim(),
            'barCouncilNumber': _barCouncilController.text.trim(),
            'bio': _bioController.text.trim(),
            'address': _addressController.text.trim(),
            'city': _cityController.text.trim(),
            'province': _provinceController.text.trim(),
            'education': _educationController.text.trim(),
            'certifications': _certificationsController.text.trim(),
            'awards': _awardsController.text.trim(),
            'officeHours': _officeHoursController.text.trim(),
            'consultationFee': _consultationFeeController.text.trim(),
            'languages': _languagesController.text
                .trim()
                .split(',')
                .map((e) => e.trim())
                .toList(),
            'caseStudies': _caseStudies,
            'updatedAt': Timestamp.now(),
          });

      // Update user document
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_currentLawyer!.id)
          .update({
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'updatedAt': Timestamp.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _isEditing = false);
      await _loadLawyerData(); // Reload data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        // Upload to Cloudinary
        print('🔄 Starting image upload...');

        if (kIsWeb) {
          // For web, read bytes immediately
          try {
            final bytes = await image.readAsBytes();
            setState(() {
              _profileImageBytes = bytes;
            });
            print('🔄 Image bytes read for web: ${bytes.length} bytes');
          } catch (e) {
            print('❌ Error reading image bytes on web: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error reading image: $e'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } else {
          // For mobile, check file path
          print('🔄 Image path: ${image.path}');
          print('🔄 File exists: ${await File(image.path).exists()}');
        }

        // Debug Cloudinary config
        CloudinaryConfig.printConfig();

        try {
          String? imageUrl;

          if (kIsWeb) {
            // For web, use bytes
            imageUrl = await CloudinaryService.uploadImageSimple(
              file: _profileImageBytes!,
              folder: 'lawyer_profile_${_currentLawyer!.id}',
            );
          } else {
            // For mobile, use File
            imageUrl = await CloudinaryService.uploadImageSimple(
              file: File(image.path),
              folder: 'lawyer_profile_${_currentLawyer!.id}',
            );
          }

          print('🔄 Upload result: $imageUrl');

          if (imageUrl == null) {
            print('🔄 Simple upload failed, trying alternative method...');
            // Try alternative method
            if (kIsWeb) {
              imageUrl = await CloudinaryService.uploadImage(
                file: _profileImageBytes!,
                folder: 'lawyer_profile_${_currentLawyer!.id}',
              );
            } else {
              imageUrl = await CloudinaryService.uploadImage(
                file: File(image.path),
                folder: 'lawyer_profile_${_currentLawyer!.id}',
              );
            }
            print('🔄 Alternative upload result: $imageUrl');
          }

          if (imageUrl == null) {
            throw Exception('Both upload methods failed');
          }

          // Update profile image in both collections
          await _firestore
              .collection(AppConstants.lawyersCollection)
              .doc(_currentLawyer!.id)
              .update({'profileImage': imageUrl});

          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(_currentLawyer!.id)
              .update({'profileImage': imageUrl});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          await _loadLawyerData(); // Reload data
        } catch (e) {
          print('❌ Image upload error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addCaseStudy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Case Study'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _caseTitleController,
              decoration: const InputDecoration(labelText: 'Case Title'),
            ),
            TextField(
              controller: _caseDescriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: _caseOutcomeController,
              decoration: const InputDecoration(labelText: 'Outcome'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_caseTitleController.text.isNotEmpty) {
                setState(() {
                  _caseStudies.add({
                    'title': _caseTitleController.text,
                    'description': _caseDescriptionController.text,
                    'outcome': _caseOutcomeController.text,
                  });
                });
                _caseTitleController.clear();
                _caseDescriptionController.clear();
                _caseOutcomeController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Profile Management',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF8B4513)),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save, color: Color(0xFF8B4513)),
              onPressed: _updateProfile,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() => _isEditing = false);
                _populateFormFields(); // Reset form
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildProfileDP(),
                  const SizedBox(height: 20),
                  _buildProfileStats(),
                  const SizedBox(height: 20),
                  _buildProfileSections(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B4513), Color(0xFFA0522D)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            _currentLawyer?.name ?? 'Lawyer Name',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentLawyer?.specialization ?? 'Specialization',
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                '${_currentLawyer?.rating ?? 0.0}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.work, color: Colors.white70, size: 24),
              const SizedBox(width: 8),
              Text(
                '${_currentLawyer?.totalCases ?? 0} Consultations',
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDP() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF8B4513), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const Spacer(),
              if (_isEditing)
                ElevatedButton.icon(
                  onPressed: _updateProfileImage,
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF8B4513),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(75),
                    child: _buildProfileImageWidget(),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _updateProfileImage,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_currentLawyer?.profileImage?.isNotEmpty == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Profile picture set',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: Colors.orange[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'No profile picture set',
                    style: TextStyle(
                      color: Colors.orange[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Debug info
          if (_currentLawyer?.profileImage?.isNotEmpty == true)
            Text(
              'URL: ${_currentLawyer!.profileImage!.substring(0, 50)}...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 60, color: Colors.grey.withOpacity(0.6)),
          const SizedBox(height: 8),
          Text(
            (_currentLawyer?.name.isNotEmpty == true)
                ? (_currentLawyer!.name[0]).toUpperCase()
                : 'L',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageWidget() {
    if (_currentLawyer?.profileImage?.isNotEmpty == true) {
      print(
        '🖼️ Building image widget with URL: ${_currentLawyer!.profileImage}',
      );
      return Image.network(
        _currentLawyer!.profileImage!,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Image load error: $error');
          print('❌ Image URL: ${_currentLawyer!.profileImage}');
          return _buildFallbackAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('✅ Image loaded successfully');
            return child;
          }
          print(
            '⏳ Loading image... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}',
          );
          return Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B4513)),
            ),
          );
        },
      );
    } else {
      print('🚫 No profile image URL available');
      return _buildFallbackAvatar();
    }
  }

  Widget _buildProfileStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Experience',
              '${_currentLawyer?.experience ?? '0'} years',
              Icons.schedule,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem(
              'Rating',
              '${_currentLawyer?.rating ?? 0.0}',
              Icons.star,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem(
              'Consultations',
              '${_currentLawyer?.totalCases ?? 0}',
              Icons.gavel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF8B4513), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProfileSections() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection('Basic Information', Icons.person, [
            _buildEditableField('Name', _nameController, Icons.person),
            _buildEditableField('Phone', _phoneController, Icons.phone),
            _buildEditableField(
              'Specialization',
              _specializationController,
              Icons.work,
            ),
            _buildEditableField(
              'Experience',
              _experienceController,
              Icons.schedule,
            ),
            _buildEditableField(
              'Bar Council Number',
              _barCouncilController,
              Icons.badge,
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('Professional Details', Icons.business, [
            _buildEditableField(
              'Bio',
              _bioController,
              Icons.description,
              maxLines: 3,
            ),
            _buildEditableField(
              'Education',
              _educationController,
              Icons.school,
            ),
            _buildEditableField(
              'Certifications',
              _certificationsController,
              Icons.verified,
            ),
            _buildEditableField(
              'Awards',
              _awardsController,
              Icons.emoji_events,
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('Location & Contact', Icons.location_on, [
            _buildEditableField('Address', _addressController, Icons.home),
            _buildCityDropdown(),
            _buildEditableField('Province', _provinceController, Icons.map),
            _buildOfficeHoursField(),
            _buildEditableField(
              'Consultation Fee (PKR)',
              _consultationFeeController,
              Icons.attach_money,
            ),
            _buildEditableField(
              'Languages',
              _languagesController,
              Icons.language,
            ),
          ]),
          const SizedBox(height: 20),
          _buildCaseStudiesSection(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF8B4513), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildOfficeHoursField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: _isEditing ? _showOfficeHoursDialog : null,
        child: TextField(
          controller: _officeHoursController,
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Office Hours',
            prefixIcon: const Icon(Icons.access_time, color: Color(0xFF8B4513)),
            suffixIcon: _isEditing ? const Icon(Icons.edit) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            filled: true,
            fillColor: _isEditing ? Colors.white : Colors.grey.withOpacity(0.1),
          ),
        ),
      ),
    );
  }

  void _showOfficeHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Office Hours'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select working days and timing'),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Example: Mon-Fri 9:00 AM - 5:00 PM',
                  hintText: 'Mon-Fri 9:00 AM - 5:00 PM',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // For now, set a default value
              setState(() {
                _officeHoursController.text = 'Mon-Fri 9:00 AM - 5:00 PM';
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedCity,
        decoration: InputDecoration(
          labelText: 'City',
          prefixIcon: const Icon(Icons.location_city, color: Color(0xFF8B4513)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _isEditing ? const Color(0xFF8B4513) : Colors.grey,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF8B4513), width: 2),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey.withOpacity(0.1),
        ),
        items: _cities.map((String city) {
          return DropdownMenuItem<String>(value: city, child: Text(city));
        }).toList(),
        onChanged: _isEditing
            ? (String? newValue) {
                setState(() {
                  _selectedCity = newValue;
                  _cityController.text = newValue ?? '';
                });
              }
            : null,
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF8B4513)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _isEditing ? const Color(0xFF8B4513) : Colors.grey,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF8B4513), width: 2),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildCaseStudiesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder, color: Color(0xFF8B4513), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Case Studies',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const Spacer(),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF8B4513)),
                  onPressed: _addCaseStudy,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_caseStudies.isEmpty)
            const Center(
              child: Text(
                'No case studies added yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._caseStudies.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, String> caseStudy = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              caseStudy['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_isEditing)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _caseStudies.removeAt(index);
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        caseStudy['description'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Outcome: ${caseStudy['outcome'] ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
