import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

class ImageService {
  static const String _cloudName = 'dii8rpixj';
  static const String _uploadPreset =
      'servipak_preset'; // You need to create this in Cloudinary
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // Removed signature generation - using unsigned uploads with preset

  /// Upload image to Cloudinary
  static Future<String?> uploadImage(
    dynamic imageFile, {
    String? folder,
  }) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Add upload preset for unsigned upload
      request.fields['upload_preset'] = _uploadPreset;

      // Add public_id for unique naming (no need for separate folder parameter)
      var timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      var fileName = 'image_$timestamp';
      var publicId = '${folder ?? 'servipak'}/$fileName';
      request.fields['public_id'] = publicId;

      // Add the image file
      http.MultipartFile multipartFile;
      if (kIsWeb) {
        // For web, imageFile should be Uint8List
        multipartFile = http.MultipartFile.fromBytes(
          'file',
          imageFile as Uint8List,
          filename: 'image.jpg',
        );
      } else {
        // For mobile, imageFile should be File
        multipartFile = await http.MultipartFile.fromPath(
          'file',
          (imageFile as File).path,
        );
      }
      request.files.add(multipartFile);

      // Send request
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        if (jsonResponse['secure_url'] != null) {
          return jsonResponse['secure_url'];
        } else {
          print('❌ ImageService: No secure_url in response');
          return null;
        }
      } else {
        print(
          '❌ ImageService: Upload failed with status ${response.statusCode}',
        );
        var errorData = await response.stream.bytesToString();
        print('❌ ImageService: Error response: $errorData');
        return null;
      }
    } catch (e) {
      print('❌ ImageService: Upload error: $e');
      return null;
    }
  }

  /// Upload profile image with specific naming convention
  static Future<String?> uploadProfileImage(
    dynamic imageFile,
    String userId,
  ) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Add upload preset for unsigned upload
      request.fields['upload_preset'] = _uploadPreset;

      // Add public_id with user ID (no need for separate folder parameter)
      var publicId = 'servipak/profiles/profile_$userId';
      request.fields['public_id'] = publicId;

      // Add the image file
      http.MultipartFile multipartFile;
      if (kIsWeb) {
        // For web, imageFile should be Uint8List
        multipartFile = http.MultipartFile.fromBytes(
          'file',
          imageFile as Uint8List,
          filename: 'profile_$userId.jpg',
        );
      } else {
        // For mobile, imageFile should be File
        multipartFile = await http.MultipartFile.fromPath(
          'file',
          (imageFile as File).path,
        );
      }
      request.files.add(multipartFile);

      // Send request
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        if (jsonResponse['secure_url'] != null) {
          print('✅ ImageService: Profile image uploaded successfully');
          // Return the original URL without transformations for now
          String originalUrl = jsonResponse['secure_url'];
          print('🔗 ImageService: Original URL: $originalUrl');
          return originalUrl;
        } else {
          print('❌ ImageService: No secure_url in response');
          return null;
        }
      } else {
        print(
          '❌ ImageService: Profile image upload failed with status ${response.statusCode}',
        );
        var errorData = await response.stream.bytesToString();
        print('❌ ImageService: Error response: $errorData');
        return null;
      }
    } catch (e) {
      print('❌ ImageService: Profile image upload error: $e');
      return null;
    }
  }

  /// Delete image from Cloudinary
  static Future<bool> deleteImage(String publicId) async {
    try {
      // Note: This requires the API secret for deletion
      // For now, we'll just return true as images will be overwritten
      print(
        'ℹ️ ImageService: Image deletion not implemented (requires API secret)',
      );
      return true;
    } catch (e) {
      print('❌ ImageService: Delete error: $e');
      return false;
    }
  }

  /// Get optimized image URL with transformations
  static String getOptimizedImageUrl(
    String originalUrl, {
    int? width,
    int? height,
    String? crop,
    String? gravity,
  }) {
    if (originalUrl.contains('cloudinary.com')) {
      // Extract the public_id from the URL
      var uri = Uri.parse(originalUrl);
      var pathSegments = uri.pathSegments;

      if (pathSegments.length >= 3) {
        var cloudName = pathSegments[1];
        var publicId = pathSegments.sublist(2).join('/');

        // Remove file extension from public_id
        publicId = publicId.replaceAll(RegExp(r'\.[^.]*$'), '');

        // Build transformation string
        List<String> transformations = [];
        if (width != null) transformations.add('w_$width');
        if (height != null) transformations.add('h_$height');
        if (crop != null) transformations.add('c_$crop');
        if (gravity != null) transformations.add('g_$gravity');

        var transformationString = transformations.isNotEmpty
            ? transformations.join(',') + '/'
            : '';

        return 'https://res.cloudinary.com/$cloudName/image/upload/$transformationString$publicId';
      }
    }

    return originalUrl;
  }

  /// Get thumbnail URL for profile images
  static String getProfileThumbnailUrl(String originalUrl) {
    return getOptimizedImageUrl(
      originalUrl,
      width: 100,
      height: 100,
      crop: 'fill',
      gravity: 'face',
    );
  }

  /// Get medium size URL for profile images
  static String getProfileMediumUrl(String originalUrl) {
    return getOptimizedImageUrl(
      originalUrl,
      width: 200,
      height: 200,
      crop: 'fill',
      gravity: 'face',
    );
  }
}
