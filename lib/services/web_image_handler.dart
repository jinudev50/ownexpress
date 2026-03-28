import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

/// Web-specific image handling utilities
class WebImageHandler {
  /// Check if running on web
  static bool get isWeb => kIsWeb;
  
  /// Convert XFile to web-compatible format
  static Future<Map<String, dynamic>?> convertXFileToWebFormat(XFile xFile) async {
    if (!isWeb) return null;
    
    try {
      final bytes = await xFile.readAsBytes();
      return {
        'bytes': bytes,
        'name': xFile.name,
        'path': xFile.name,
        'size': bytes.length,
        'lastModified': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('Error converting XFile to web format: $e');
      return null;
    }
  }
  
  /// Validate web image data
  static bool isValidWebImageData(Map<String, dynamic>? imageData) {
    if (imageData == null) return false;
    
    return imageData.containsKey('bytes') &&
           imageData.containsKey('name') &&
           imageData['bytes'] is Uint8List &&
           imageData['bytes'].length > 0;
  }
  
  /// Get file extension from web image data
  static String getFileExtension(Map<String, dynamic> imageData) {
    final name = imageData['name'] as String? ?? '';
    final lastDot = name.lastIndexOf('.');
    return lastDot != -1 ? name.substring(lastDot + 1).toLowerCase() : 'jpg';
  }
  
  /// Get MIME type from file extension
  static String getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

/// Mobile-specific image handling utilities
class MobileImageHandler {
  /// Check if running on mobile
  static bool get isMobile => !kIsWeb;
  
  /// Validate mobile image file
  static bool isValidMobileImageFile(dynamic imageFile) {
    if (!isMobile) return false;
    
    return imageFile != null &&
           imageFile is dynamic &&
           imageFile.path != null &&
           imageFile.path.isNotEmpty;
  }
}
