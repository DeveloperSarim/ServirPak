import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  // Base URL for Cloudinary API
  static String get _baseUrl => CloudinaryConfig.baseUrl;

  // Document upload for Web Compatible
  static Future<String?> uploadDocument({
    required dynamic file, // File for mobile, Uint8List for web
    required String folder,
    String? publicId,
    String? originalFileName,
  }) async {
    try {
      // Generate unique public ID agar nahi diya gaya ho
      final String finalPublicId =
          publicId ?? '${folder}_${DateTime.now().millisecondsSinceEpoch}';

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/auto/upload'),
      );

      // Add file to request - cross-platform
      if (kIsWeb) {
        // For web, use Uint8List
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file as Uint8List,
            filename:
                originalFileName ??
                'document_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
      } else {
        // For mobile, use File
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            (file as File).path,
            filename: originalFileName ?? file.path.split('/').last,
          ),
        );
      }

      // Add parameters
      request.fields.addAll({
        'upload_preset': CloudinaryConfig.uploadPreset,
        'folder': folder,
        'public_id': finalPublicId,
        'resource_type': 'auto', // Auto detect file type
      });

      // Send request
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);

        if (jsonData['secure_url'] != null) {
          print('✅ Document uploaded successfully: ${jsonData['secure_url']}');
          return jsonData['secure_url'];
        }
      } else {
        print('❌ Upload failed with status: ${response.statusCode}');
        var errorData = await response.stream.bytesToString();
        print('Error response: $errorData');
      }
    } catch (e) {
      print('❌ Error uploading document: $e');
    }
    return null;
  }

  // Simple image upload without complex parameters
  static Future<String?> uploadImageSimple({
    required dynamic file,
    required String folder,
    String? publicId,
  }) async {
    try {
      print('🚀 Starting simple image upload...');

      final String finalPublicId =
          publicId ?? '${folder}_${DateTime.now().millisecondsSinceEpoch}';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/image/upload'),
      );

      // Add file
      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file as Uint8List,
            filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            (file as File).path,
            filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      // Simple fields - no complex parameters
      request.fields['upload_preset'] = CloudinaryConfig.unsignedPreset;
      request.fields['public_id'] = finalPublicId;

      print('🚀 Sending simple request...');
      var response = await request.send();
      print('🚀 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        print('🚀 Response: $responseData');
        var jsonData = json.decode(responseData);

        if (jsonData['secure_url'] != null) {
          print('✅ Simple upload successful: ${jsonData['secure_url']}');
          return jsonData['secure_url'];
        }
      } else {
        var errorBody = await response.stream.bytesToString();
        print('❌ Simple upload failed: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('❌ Simple upload error: $e');
    }
    return null;
  }

  // Image upload for Web Compatible
  static Future<String?> uploadImage({
    required dynamic file, // File for mobile, Uint8List for web
    required String folder,
    String? publicId,
    String? originalFileName,
    int? width,
    int? height,
    String? crop,
  }) async {
    try {
      final String finalPublicId =
          publicId ?? '${folder}_${DateTime.now().millisecondsSinceEpoch}';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/image/upload'),
      );

      // Add file - cross-platform
      if (kIsWeb) {
        // For web, use Uint8List
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file as Uint8List,
            filename:
                originalFileName ??
                'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      } else {
        // For mobile, use File
        print('📱 Mobile platform detected');
        print('📱 File path: ${file.path}');
        print('📱 File exists: ${await file.exists()}');

        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            filename: originalFileName ?? file.path.split('/').last,
          ),
        );
      }

      Map<String, String> fields = {
        'upload_preset': CloudinaryConfig.uploadPreset,
        'folder': folder,
        'public_id': finalPublicId,
      };

      // Add transformation parameters
      if (width != null) fields['width'] = width.toString();
      if (height != null) fields['height'] = height.toString();
      if (crop != null) fields['crop'] = crop;

      request.fields.addAll(fields);

      // Send request
      print('🚀 Sending request to Cloudinary...');
      print('🚀 URL: $_baseUrl/image/upload');
      print('🚀 Upload preset: ${CloudinaryConfig.uploadPreset}');
      print('🚀 Folder: $folder');
      print('🚀 Public ID: $finalPublicId');

      var response = await request.send();
      print('🚀 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        print('🚀 Response body: $responseData');
        var jsonData = json.decode(responseData);

        if (jsonData['secure_url'] != null) {
          print('✅ Image uploaded successfully: ${jsonData['secure_url']}');
          return jsonData['secure_url'];
        } else {
          print('❌ No secure_url in response');
          return null;
        }
      } else {
        var errorBody = await response.stream.bytesToString();
        print('❌ Image upload failed with status: ${response.statusCode}');
        print('❌ Error body: $errorBody');
        throw Exception('Upload failed: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
    }
    return null;
  }

  // Multiple files upload for Web Compatible
  static Future<List<String>> uploadMultipleDocuments({
    required List<dynamic>
    files, // List<File> for mobile, List<Uint8List> for web
    required String folder,
    String? prefix,
    List<String>? fileNames, // Optional list of original file names for web
  }) async {
    List<String> uploadedUrls = [];

    for (int i = 0; i < files.length; i++) {
      final String publicId = prefix != null
          ? '${prefix}_${i + 1}_${DateTime.now().millisecondsSinceEpoch}'
          : '${folder}_${i + 1}_${DateTime.now().millisecondsSinceEpoch}';

      final String? url = await uploadDocument(
        file: files[i],
        folder: folder,
        publicId: publicId,
        originalFileName: fileNames != null && i < fileNames.length
            ? fileNames[i]
            : null,
      );

      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  // Delete file from Cloudinary
  static Future<bool> deleteFile({
    required String publicId,
    String resourceType = 'auto',
  }) async {
    try {
      // Generate signature for deletion
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String signature = _generateSignature(publicId, timestamp);

      final response = await http.post(
        Uri.parse('$_baseUrl/$resourceType/destroy'),
        body: {
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': CloudinaryConfig.apiKey,
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return jsonData['result'] == 'ok';
      }
    } catch (e) {
      print('❌ Error deleting file: $e');
    }
    return false;
  }

  // Generate signature for authenticated requests
  static String _generateSignature(String publicId, String timestamp) {
    final String stringToSign =
        'public_id=$publicId&timestamp=$timestamp${CloudinaryConfig.apiSecret}';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  // Get optimized image URL with transformations
  static String getOptimizedImageUrl({
    required String publicId,
    int? width,
    int? height,
    String? crop,
    String? quality,
    String? format,
  }) {
    String url =
        'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload';

    List<String> transformations = [];

    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    if (crop != null) transformations.add('c_$crop');
    if (quality != null) transformations.add('q_$quality');
    if (format != null) transformations.add('f_$format');

    if (transformations.isNotEmpty) {
      url += '/${transformations.join(',')}';
    }

    url += '/$publicId';

    return url;
  }
}
