import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../home/home_screen.dart';

class LawyerRegistrationScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String name;
  final String phone;
  final String city;

  const LawyerRegistrationScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.name,
    required this.phone,
    required this.city,
  });

  @override
  State<LawyerRegistrationScreen> createState() =>
      _LawyerRegistrationScreenState();
}

class _LawyerRegistrationScreenState extends State<LawyerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _barCouncilController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _languagesController = TextEditingController();

  bool _isLoading = false;
  String _selectedProvince = 'Punjab';

  // Document upload states
  File? _cnicFront;
  File? _cnicBack;
  File? _barCouncilCertificate;
  File? _degreeCertificate;
  File? _profileImage;
  Uint8List? _profileImageBytes; // For web compatibility

  // Document bytes for web compatibility
  Map<String, Uint8List> _documentBytes = <String, Uint8List>{};
  Map<String, String> _documentNames = <String, String>{};

  // Upload progress
  Map<String, bool> _uploadProgress = <String, bool>{};
  Map<String, String> _uploadedUrls = <String, String>{};

  final List<String> _provinces = [
    'Punjab',
    'Sindh',
    'KPK',
    'Balochistan',
    'Federal',
    'Gilgit-Baltistan',
    'Azad Kashmir',
  ];

  @override
  void dispose() {
    _specializationController.dispose();
    _experienceController.dispose();
    _barCouncilController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _languagesController.dispose();
    super.dispose();
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

  Future<void> _pickDocument(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        if (kIsWeb) {
          // For web, use bytes
          if (file.bytes != null) {
            setState(() {
              _documentBytes[documentType] = file.bytes!;
              _documentNames[documentType] = file.name;
            });
          }
        } else {
          // For mobile, use file path
          if (file.path != null) {
            File fileObj = File(file.path!);
            setState(() {
              switch (documentType) {
                case 'cnic_front':
                  _cnicFront = fileObj;
                  break;
                case 'cnic_back':
                  _cnicBack = fileObj;
                  break;
                case 'bar_council':
                  _barCouncilCertificate = fileObj;
                  break;
                case 'degree':
                  _degreeCertificate = fileObj;
                  break;
              }
            });
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error picking document: $e');
    }
  }

  Future<void> _uploadDocument(dynamic file, String documentType) async {
    setState(() {
      _uploadProgress[documentType] = true;
    });

    try {
      String? url;

      if (kIsWeb) {
        // For web, use bytes
        if (_documentBytes.isNotEmpty &&
            _documentBytes.containsKey(documentType)) {
          url = await CloudinaryService.uploadDocument(
            file: _documentBytes[documentType]!,
            folder: 'lawyer_documents/${widget.userId}',
            publicId:
                '${documentType}_${DateTime.now().millisecondsSinceEpoch}',
            originalFileName: _documentNames[documentType],
          );
        }
      } else {
        // For mobile, use File object
        url = await CloudinaryService.uploadDocument(
          file: file,
          folder: 'lawyer_documents/${widget.userId}',
          publicId: '${documentType}_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      if (url != null) {
        setState(() {
          _uploadedUrls[documentType] = url!;
          _uploadProgress[documentType] = false;
        });
      } else {
        setState(() {
          _uploadProgress[documentType] = false;
        });
        _showErrorSnackBar('$documentType upload failed');
      }
    } catch (e) {
      setState(() {
        _uploadProgress[documentType] = false;
      });
      _showErrorSnackBar('Upload error: $e');
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    setState(() {
      _uploadProgress['profile'] = true;
    });

    try {
      String? url = await CloudinaryService.uploadImage(
        file: _profileImage!,
        folder: 'lawyer_profiles/${widget.userId}',
        publicId: 'profile_${DateTime.now().millisecondsSinceEpoch}',
        width: 400,
        height: 400,
        crop: 'fill',
      );

      if (url != null) {
        setState(() {
          _uploadedUrls['profile'] = url;
          _uploadProgress['profile'] = false;
        });
      } else {
        setState(() {
          _uploadProgress['profile'] = false;
        });
        _showErrorSnackBar('Profile image upload failed');
      }
    } catch (e) {
      setState(() {
        _uploadProgress['profile'] = false;
      });
      _showErrorSnackBar('Profile upload error: $e');
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    // Check required documents
    bool hasRequiredDocs = false;
    if (kIsWeb) {
      hasRequiredDocs =
          _documentBytes.isNotEmpty &&
          _documentBytes.containsKey('cnic_front') &&
          _documentBytes.containsKey('cnic_back') &&
          _documentBytes.containsKey('bar_council');
    } else {
      hasRequiredDocs =
          _cnicFront != null &&
          _cnicBack != null &&
          _barCouncilCertificate != null;
    }

    if (!hasRequiredDocs) {
      _showErrorSnackBar('Please upload all required documents');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload all documents
      List<Future> uploadTasks = [];

      if (kIsWeb) {
        uploadTasks.addAll([
          _uploadDocument(null, 'cnic_front'),
          _uploadDocument(null, 'cnic_back'),
          _uploadDocument(null, 'bar_council'),
        ]);
        if (_documentBytes.isNotEmpty && _documentBytes.containsKey('degree')) {
          uploadTasks.add(_uploadDocument(null, 'degree'));
        }
      } else {
        uploadTasks.addAll([
          _uploadDocument(_cnicFront!, 'cnic_front'),
          _uploadDocument(_cnicBack!, 'cnic_back'),
          _uploadDocument(_barCouncilCertificate!, 'bar_council'),
        ]);
        if (_degreeCertificate != null) {
          uploadTasks.add(_uploadDocument(_degreeCertificate!, 'degree'));
        }
      }

      if (_profileImage != null) {
        uploadTasks.add(_uploadProfileImage());
      }

      await Future.wait(uploadTasks);

      // Check if all uploads completed
      bool allUploaded =
          _uploadedUrls.isNotEmpty &&
          _uploadedUrls.containsKey('cnic_front') &&
          _uploadedUrls.containsKey('cnic_back') &&
          _uploadedUrls.containsKey('bar_council');

      if (!allUploaded) {
        _showErrorSnackBar(
          'Some documents failed to upload. Please try again.',
        );
        return;
      }

      // Create lawyer profile
      await AuthService.createLawyerProfile(
        userId: widget.userId,
        specialization: _specializationController.text.trim(),
        experience: _experienceController.text.trim(),
        barCouncilNumber: _barCouncilController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        languages: _languagesController.text.trim().isNotEmpty
            ? _languagesController.text
                  .trim()
                  .split(',')
                  .map((e) => e.trim())
                  .toList()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        city: widget.city,
        province: _selectedProvince,
        documentUrls: _uploadedUrls,
      );

      // Update user with document URLs
      await AuthService.updateUserProfile(
        userId: widget.userId,
        profileImage: _uploadedUrls['profile'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lawyer registration successful! Please wait for admin approval.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Registration failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required String documentType,
    required File? file,
    required bool isRequired,
  }) {
    // Check if document is uploaded (for both web and mobile)
    bool isDocumentUploaded = false;
    String fileName = '';

    if (kIsWeb) {
      isDocumentUploaded =
          _documentBytes.isNotEmpty && _documentBytes.containsKey(documentType);
      fileName = _documentNames[documentType] ?? '';
    } else {
      isDocumentUploaded = file != null;
      fileName = file?.path.split('/').last ?? '';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isRequired)
                  const Text(' *', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            if (isDocumentUploaded) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                    if (_uploadProgress.isNotEmpty &&
                        _uploadProgress[documentType] == true)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (_uploadedUrls.isNotEmpty &&
                        _uploadedUrls.containsKey(documentType))
                      Icon(Icons.cloud_done, color: Colors.green.shade600),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => _pickDocument(documentType),
                icon: const Icon(Icons.upload_file),
                label: const Text('Document Upload Karein'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lawyer Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF8B4513),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Complete Your Lawyer Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete your profile and apply for verification',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Profile Image Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Profile Image',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_profileImage != null) ...[
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: kIsWeb
                                  ? _profileImageBytes != null
                                        ? Image.memory(
                                            _profileImageBytes!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.person,
                                                      size: 60,
                                                    ),
                                          )
                                        : const Icon(Icons.person, size: 60)
                                  : Image.file(
                                      _profileImage!,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_uploadProgress['profile'] == true)
                            const CircularProgressIndicator(),
                          if (_uploadedUrls.containsKey('profile'))
                            const Icon(Icons.cloud_done, color: Colors.green),
                        ] else ...[
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.grey.shade100,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 40),
                              onPressed: () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B4513),
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B4513),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Basic Information
                TextFormField(
                  controller: _specializationController,
                  decoration: InputDecoration(
                    labelText: 'Specialization *',
                    hintText: 'e.g., Criminal Law, Family Law, Corporate Law',
                    prefixIcon: const Icon(Icons.work_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8B4513)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your specialization';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _experienceController,
                  decoration: InputDecoration(
                    labelText: 'Experience (Years) *',
                    hintText: 'e.g., 5',
                    prefixIcon: const Icon(Icons.timeline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8B4513)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your experience';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _barCouncilController,
                  decoration: InputDecoration(
                    labelText: 'Bar Council Number *',
                    hintText: 'e.g., BC-12345',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8B4513)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your bar council number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: InputDecoration(
                    labelText: 'Province *',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8B4513)),
                    ),
                  ),
                  items: _provinces.map((province) {
                    return DropdownMenuItem(
                      value: province,
                      child: Text(province),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value!;
                    });
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    hintText: 'Your complete address',
                    prefixIcon: const Icon(Icons.home),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8B4513)),
                    ),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _languagesController,
                  decoration: InputDecoration(
                    labelText: 'Languages (Comma separated)',
                    hintText: 'e.g., English, Urdu, Punjabi',
                    prefixIcon: const Icon(Icons.language),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8B4513)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself and your expertise',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8B4513)),
                    ),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 30),

                // Document Upload Section
                const Text(
                  'Required Documents',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                _buildDocumentUploadCard(
                  title: 'CNIC Front',
                  documentType: 'cnic_front',
                  file: _cnicFront,
                  isRequired: true,
                ),

                _buildDocumentUploadCard(
                  title: 'CNIC Back',
                  documentType: 'cnic_back',
                  file: _cnicBack,
                  isRequired: true,
                ),

                _buildDocumentUploadCard(
                  title: 'Bar Council Certificate',
                  documentType: 'bar_council',
                  file: _barCouncilCertificate,
                  isRequired: true,
                ),

                _buildDocumentUploadCard(
                  title: 'Degree Certificate (Optional)',
                  documentType: 'degree',
                  file: _degreeCertificate,
                  isRequired: false,
                ),

                const SizedBox(height: 30),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegistration,
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
                          'Submit Registration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
