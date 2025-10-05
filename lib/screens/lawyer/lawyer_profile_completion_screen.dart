import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/cloudinary_service.dart';
import '../../services/auth_service.dart';
import '../../constants/app_constants.dart';

class LawyerProfileCompletionScreen extends StatefulWidget {
  const LawyerProfileCompletionScreen({super.key});

  @override
  State<LawyerProfileCompletionScreen> createState() =>
      _LawyerProfileCompletionScreenState();
}

class _LawyerProfileCompletionScreenState
    extends State<LawyerProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _educationController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _awardsController = TextEditingController();
  final _languagesController = TextEditingController();

  // Profile image
  File? _profileImage;
  Uint8List? _profileImageBytes;
  bool _isUploadingImage = false;

  // Office hours
  Map<String, Map<String, dynamic>> _officeHours = {
    'Monday': {'isWorking': true, 'startTime': '09:00', 'endTime': '17:00'},
    'Tuesday': {'isWorking': true, 'startTime': '09:00', 'endTime': '17:00'},
    'Wednesday': {'isWorking': true, 'startTime': '09:00', 'endTime': '17:00'},
    'Thursday': {'isWorking': true, 'startTime': '09:00', 'endTime': '17:00'},
    'Friday': {'isWorking': true, 'startTime': '09:00', 'endTime': '17:00'},
    'Saturday': {'isWorking': false, 'startTime': '09:00', 'endTime': '17:00'},
    'Sunday': {'isWorking': false, 'startTime': '09:00', 'endTime': '17:00'},
  };

  // Cities
  List<Map<String, dynamic>> _cities = [];
  String? _selectedCity;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _addressController.dispose();
    _officeAddressController.dispose();
    _consultationFeeController.dispose();
    _educationController.dispose();
    _certificationsController.dispose();
    _awardsController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.citiesCollection)
          .get();

      setState(() {
        _cities = snapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'name': doc.data()['name'],
                'province': doc.data()['province'],
              },
            )
            .toList();
      });
    } catch (e) {
      print('❌ Error loading cities: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });

        // For web, we need to read bytes immediately
        if (kIsWeb) {
          try {
            final bytes = await image.readAsBytes();
            setState(() {
              _profileImageBytes = bytes;
            });
          } catch (e) {
            print('❌ Error reading image bytes on web: $e');
            _showErrorSnackBar('Error reading image: $e');
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      String? imageUrl;

      if (kIsWeb) {
        imageUrl = await CloudinaryService.uploadImageSimple(
          file: _profileImageBytes!,
          folder: 'user_profiles',
          publicId: 'profile_${AuthService.currentUser?.uid}',
        );
      } else {
        imageUrl = await CloudinaryService.uploadImageSimple(
          file: _profileImage!,
          folder: 'user_profiles',
          publicId: 'profile_${AuthService.currentUser?.uid}',
        );
      }

      if (imageUrl != null) {
        print('✅ Image uploaded successfully: $imageUrl');

        // Update user profile image
        try {
          await FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .doc(AuthService.currentUser?.uid)
              .update({'profileImage': imageUrl});
          print('✅ Updated users collection with image URL');
        } catch (e) {
          print('❌ Error updating users collection: $e');
          // Try to set instead of update
          await FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .doc(AuthService.currentUser?.uid)
              .set({'profileImage': imageUrl}, SetOptions(merge: true));
          print('✅ Set users collection with image URL (merge)');
        }

        // Update lawyer profile image
        try {
          await FirebaseFirestore.instance
              .collection(AppConstants.lawyersCollection)
              .doc(AuthService.currentUser?.uid)
              .update({'profileImage': imageUrl});
          print('✅ Updated lawyers collection with image URL');
        } catch (e) {
          print('❌ Error updating lawyers collection: $e');
          // Try to set instead of update
          await FirebaseFirestore.instance
              .collection(AppConstants.lawyersCollection)
              .doc(AuthService.currentUser?.uid)
              .set({'profileImage': imageUrl}, SetOptions(merge: true));
          print('✅ Set lawyers collection with image URL (merge)');
        }

        _showSuccessSnackBar('Profile image uploaded successfully!');
      } else {
        _showErrorSnackBar('Failed to upload profile image');
      }
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      _showErrorSnackBar('Error uploading profile image: $e');
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileImage == null) {
      _showErrorSnackBar('Please select a profile image');
      return;
    }
    if (_selectedCity == null) {
      _showErrorSnackBar('Please select a city');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First upload profile image
      await _uploadProfileImage();

      // Update lawyer profile with all details
      await FirebaseFirestore.instance
          .collection(AppConstants.lawyersCollection)
          .doc(AuthService.currentUser?.uid)
          .update({
            'bio': _bioController.text.trim(),
            'address': _addressController.text.trim(),
            'officeAddress': _officeAddressController.text.trim(),
            'consultationFee': _consultationFeeController.text.trim(),
            'education': _educationController.text.trim(),
            'certifications': _certificationsController.text.trim(),
            'awards': _awardsController.text.trim(),
            'languages': _languagesController.text
                .split(',')
                .map((e) => e.trim())
                .toList(),
            'city': _selectedCity,
            'officeHours': _officeHours,
            'profileCompleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _showSuccessSnackBar('Profile completed successfully!');

      // Navigate to dashboard
      Navigator.pushReplacementNamed(context, '/lawyer-dashboard');
    } catch (e) {
      print('❌ Error completing profile: $e');
      _showErrorSnackBar('Error completing profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showOfficeHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Office Hours'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _officeHours.length,
            itemBuilder: (context, index) {
              final day = _officeHours.keys.elementAt(index);
              final schedule = _officeHours[day]!;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Switch(
                            value: schedule['isWorking'],
                            onChanged: (value) {
                              setState(() {
                                _officeHours[day]!['isWorking'] = value;
                              });
                            },
                          ),
                        ],
                      ),
                      if (schedule['isWorking']) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: schedule['startTime'],
                                decoration: const InputDecoration(
                                  labelText: 'Start Time',
                                  border: OutlineInputBorder(),
                                ),
                                items: _getTimeOptions()
                                    .map(
                                      (time) => DropdownMenuItem(
                                        value: time,
                                        child: Text(time),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _officeHours[day]!['startTime'] = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: schedule['endTime'],
                                decoration: const InputDecoration(
                                  labelText: 'End Time',
                                  border: OutlineInputBorder(),
                                ),
                                items: _getTimeOptions()
                                    .map(
                                      (time) => DropdownMenuItem(
                                        value: time,
                                        child: Text(time),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _officeHours[day]!['endTime'] = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  List<String> _getTimeOptions() {
    List<String> times = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final time =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        times.add(time);
      }
    }
    return times;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(60),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: _profileImage != null
                                    ? kIsWeb
                                          ? _profileImageBytes != null
                                                ? Image.memory(
                                                    _profileImageBytes!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => const Icon(
                                                          Icons.person,
                                                          size: 60,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.person,
                                                    size: 60,
                                                  )
                                          : Image.file(
                                              _profileImage!,
                                              fit: BoxFit.cover,
                                            )
                                    : const Icon(Icons.person, size: 60),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8B4513),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                  onPressed: () =>
                                      _pickImage(ImageSource.gallery),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isUploadingImage)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Basic Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bio
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          labelText: 'Bio *',
                          hintText: 'Tell us about yourself',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bio is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address *',
                          hintText: 'Your home address',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Address is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Office Address
                      TextFormField(
                        controller: _officeAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Office Address *',
                          hintText: 'Your office address',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Office address is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // City
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          border: OutlineInputBorder(),
                        ),
                        items: _cities.map((city) {
                          return DropdownMenuItem<String>(
                            value: city['name'],
                            child: Text('${city['name']}, ${city['province']}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a city';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Consultation Fee
                      TextFormField(
                        controller: _consultationFeeController,
                        decoration: const InputDecoration(
                          labelText: 'Consultation Fee (PKR) *',
                          hintText: 'e.g., 5000',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Consultation fee is required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Professional Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Professional Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Education
                      TextFormField(
                        controller: _educationController,
                        decoration: const InputDecoration(
                          labelText: 'Education *',
                          hintText: 'e.g., LLB from University of Punjab',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Education is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Certifications
                      TextFormField(
                        controller: _certificationsController,
                        decoration: const InputDecoration(
                          labelText: 'Certifications',
                          hintText:
                              'e.g., Bar Council Certificate, Specialized Training',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Awards
                      TextFormField(
                        controller: _awardsController,
                        decoration: const InputDecoration(
                          labelText: 'Awards & Recognition',
                          hintText: 'e.g., Best Lawyer Award 2023',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Languages
                      TextFormField(
                        controller: _languagesController,
                        decoration: const InputDecoration(
                          labelText: 'Languages *',
                          hintText: 'e.g., Urdu, English, Punjabi',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Languages are required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Office Hours
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Office Hours',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B4513),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _showOfficeHoursDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B4513),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Set Hours'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Configure your working hours for each day of the week.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Complete Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
