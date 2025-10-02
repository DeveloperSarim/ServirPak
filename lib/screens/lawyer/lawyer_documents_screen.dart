import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';

class LawyerDocumentsScreen extends StatefulWidget {
  const LawyerDocumentsScreen({super.key});

  @override
  State<LawyerDocumentsScreen> createState() => _LawyerDocumentsScreenState();
}

class _LawyerDocumentsScreenState extends State<LawyerDocumentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final session = await AuthService.getSavedUserSession();
      if (session != null) {
        String lawyerId = session['userId'] as String;

        QuerySnapshot docsSnapshot = await _firestore
            .collection('lawyer_documents')
            .where('lawyerId', isEqualTo: lawyerId)
            .orderBy('uploadedAt', descending: true)
            .get();

        _documents = docsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      }
    } catch (e) {
      print('Error loading documents: $e');
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
          'Documents',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.upload, color: Color(0xFF8B4513)),
            onPressed: _showUploadDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No documents uploaded yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Upload your legal documents and case files',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> document = _documents[index];
                return _buildDocumentCard(document);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        backgroundColor: const Color(0xFF8B4513),
        child: const Icon(Icons.upload, color: Colors.white),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    String fileName = document['fileName'] ?? 'Unknown';
    String fileType = document['fileType'] ?? 'Unknown';
    String uploadedAt = document['uploadedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            document['uploadedAt'],
          ).toString().split(' ')[0]
        : 'Unknown';
    String category = document['category'] ?? 'General';
    String url = document['url'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getFileTypeColor(fileType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getFileTypeIcon(fileType),
                color: _getFileTypeColor(fileType),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Uploaded: $uploadedAt',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'view') {
                  _viewDocument(url, fileName);
                } else if (value == 'download') {
                  _downloadDocument(url, fileName);
                } else if (value == 'delete') {
                  _deleteDocument(document['id']);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('View'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 20),
                      SizedBox(width: 8),
                      Text('Download'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: const Text('Select the type of document you want to upload:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadDocument('Case File');
            },
            child: const Text('Case File'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadDocument('Contract');
            },
            child: const Text('Contract'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadDocument('Certificate');
            },
            child: const Text('Certificate'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadDocument('Other');
            },
            child: const Text('Other'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadDocument(String category) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() => _isUploading = true);

        PlatformFile file = result.files.first;
        String fileName = file.name;
        String fileType = fileName.split('.').last.toLowerCase();

        // For demo purposes, create a mock URL
        String url =
            'https://example.com/demo_${fileName}_${DateTime.now().millisecondsSinceEpoch}';

        // Simulate upload delay
        await Future.delayed(const Duration(seconds: 2));

        // Save to Firestore
        final session = await AuthService.getSavedUserSession();
        if (session != null) {
          await _firestore.collection('lawyer_documents').add({
            'lawyerId': session['userId'],
            'fileName': fileName,
            'fileType': fileType,
            'category': category,
            'url': url,
            'uploadedAt': DateTime.now().millisecondsSinceEpoch,
            'size': file.size,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh documents list
          await _loadDocuments();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _viewDocument(String url, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fileName),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.description,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Document preview not available',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Open document in new tab
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Opening document in new tab...'),
                                backgroundColor: Color(0xFF8B4513),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open Document'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _downloadDocument(String url, String fileName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $fileName...'),
        backgroundColor: const Color(0xFF8B4513),
      ),
    );
  }

  Future<void> _deleteDocument(String documentId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore
            .collection('lawyer_documents')
            .doc(documentId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh documents list
        await _loadDocuments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
