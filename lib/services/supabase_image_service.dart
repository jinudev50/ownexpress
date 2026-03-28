import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'web_image_handler.dart';

/// Supabase Image Upload Service with Firebase Integration
class SupabaseImageService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Bucket configuration
  static const String _bucketName = 'profile-images';
  
  /// Get current user ID
  static String? get userId => _firebaseAuth.currentUser?.uid;
  
  /// Check if user is authenticated
  static bool get isAuthenticated => userId != null;
  
  /// 1. Pick Image from Gallery (Mobile & Web Support)
  static Future<dynamic> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image
        maxWidth: 800,     // Resize for optimization
        maxHeight: 800,
      );
      
      if (pickedFile != null) {
        if (WebImageHandler.isWeb) {
          // For web, convert to web-compatible format
          return await WebImageHandler.convertXFileToWebFormat(pickedFile);
        } else {
          // For mobile, return the File
          return File(pickedFile.path);
        }
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }
  
  /// 2. Pick Image from Camera (Mobile & Web Support)
  static Future<dynamic> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Compress image
        maxWidth: 800,     // Resize for optimization
        maxHeight: 800,
      );
      
      if (pickedFile != null) {
        if (WebImageHandler.isWeb) {
          // For web, convert to web-compatible format
          return await WebImageHandler.convertXFileToWebFormat(pickedFile);
        } else {
          // For mobile, return the File
          return File(pickedFile.path);
        }
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }
  
  /// 3. Upload Image to Supabase Storage (Mobile & Web Support)
  static Future<String?> uploadImageToSupabase(dynamic imageData) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }
      
      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.uid}_profile_$timestamp.jpg';
      
      print('Uploading image: $fileName');
      print('Platform: ${WebImageHandler.isWeb ? 'Web' : 'Mobile'}');
      print('Bucket: $_bucketName');
      
      // Upload based on platform
      if (WebImageHandler.isWeb) {
        // Web: Validate and upload using bytes
        if (!WebImageHandler.isValidWebImageData(imageData)) {
          throw 'Invalid image data for web platform';
        }
        
        final Uint8List bytes = imageData['bytes'];
        final fileExtension = WebImageHandler.getFileExtension(imageData);
        final mimeType = WebImageHandler.getMimeType(fileExtension);
        
        await _supabase.storage
            .from(_bucketName)
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                contentType: mimeType,
                upsert: true,
              ),
            );
      } else {
        // Mobile: Validate and upload using File
        if (!MobileImageHandler.isValidMobileImageFile(imageData)) {
          throw 'Invalid image data for mobile platform';
        }
        
        await _supabase.storage
            .from(_bucketName)
            .upload(
              fileName,
              imageData,
              fileOptions: FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
      }
      
      // Get public URL - ensure proper format
      final imageUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);
      
      print('Image uploaded successfully: $imageUrl');
      
      // Verify URL format
      if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
        return imageUrl;
      } else {
        print('Invalid URL format: $imageUrl');
        return null;
      }
    } catch (e) {
      print('Error uploading image to Supabase: $e');
      return null;
    }
  }
  
  /// 4. Get URL from Supabase (if already uploaded)
  static String? getImageUrl(String fileName) {
    try {
      return _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);
    } catch (e) {
      print('Error getting image URL: $e');
      return null;
    }
  }
  
  /// 5. Save URL in Firebase Firestore
  static Future<bool> saveImageUrlToFirebase(String imageUrl) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }
      
      // Save to user profile document in Firestore using set with merge
      await _firestore.collection('users').doc(user.uid).set({
        'profileImageUrl': imageUrl,
        'profileImageUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('Image URL saved to Firebase: $imageUrl');
      return true;
    } catch (e) {
      print('Error saving image URL to Firebase: $e');
      return false;
    }
  }
  
  /// 7. Delete Image from Supabase Storage
  static Future<bool> deleteImageFromSupabase(String imageUrl) async {
    try {
      // Extract file name from URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      
      await _supabase.storage
          .from(_bucketName)
          .remove([fileName]);
      
      print('Image deleted from Supabase: $fileName');
      return true;
    } catch (e) {
      print('Error deleting image from Supabase: $e');
      return false;
    }
  }
  
  /// 8. Force refresh profile image (for debugging)
  static Future<String?> refreshProfileImage() async {
    try {
      print('Force refreshing profile image...');
      final imageUrl = await getUserProfileImage();
      
      if (imageUrl != null) {
        print('Image URL found: $imageUrl');
        
        // Test if URL is accessible by trying to load it
        if (imageUrl.startsWith('http')) {
          print('URL format is valid');
          return imageUrl;
        } else {
          print('Invalid URL format: $imageUrl');
          return null;
        }
      } else {
        print('No image URL found in Firebase');
        return null;
      }
    } catch (e) {
      print('Error refreshing profile image: $e');
      return null;
    }
  }
  
  /// 7. Remove URL from Firebase Firestore
  static Future<bool> removeImageUrlFromFirebase() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }
      
      // Remove from user profile document in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': FieldValue.delete(),
        'profileImageUpdatedAt': FieldValue.delete(),
      });
      
      print('Image URL removed from Firebase');
      return true;
    } catch (e) {
      print('Error removing image URL from Firebase: $e');
      return false;
    }
  }
  
  /// Complete Flow: Pick -> Upload -> Save URL (Mobile & Web Support)
  static Future<String?> completeImageUploadFlow({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Step 1: Pick Image (platform-specific)
      final dynamic imageData = source == ImageSource.gallery 
          ? await pickImageFromGallery()
          : await pickImageFromCamera();
      
      if (imageData == null) {
        throw 'No image selected';
      }
      
      print('Image picked successfully on ${kIsWeb ? 'Web' : 'Mobile'} platform');
      
      // Step 2: Upload to Supabase (platform-specific)
      final String? imageUrl = await uploadImageToSupabase(imageData);
      
      if (imageUrl == null) {
        throw 'Failed to upload image';
      }
      
      print('Image uploaded to Supabase successfully');
      
      // Step 3: Save URL to Firebase
      final bool saved = await saveImageUrlToFirebase(imageUrl);
      
      if (!saved) {
        throw 'Failed to save image URL';
      }
      
      print('Image URL saved to Firebase successfully');
      return imageUrl;
    } catch (e) {
      print('Error in complete image upload flow: $e');
      return null;
    }
  }
  
  /// Get current user's profile image URL from Firebase
  static Future<String?> getUserProfileImage() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        print('No user logged in');
        return null;
      }
      
      print('Fetching profile image for user: ${user.uid}');
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final data = doc.data();
        final imageUrl = data?['profileImageUrl'];
        print('Document exists, profileImageUrl: $imageUrl');
        
        if (imageUrl != null && imageUrl.isNotEmpty) {
          print('Returning image URL: $imageUrl');
          return imageUrl;
        } else {
          print('No profileImageUrl found in document');
          return null;
        }
      } else {
        print('User document does not exist in Firestore');
        return null;
      }
    } catch (e) {
      print('Error getting user profile image: $e');
      return null;
    }
  }
  
  /// Complete Delete Flow: Remove from Supabase -> Remove from Firebase
  static Future<bool> completeImageDeleteFlow() async {
    try {
      // Get current image URL from Firebase
      final String? currentImageUrl = await getUserProfileImage();
      
      if (currentImageUrl != null) {
        // Delete from Supabase
        await deleteImageFromSupabase(currentImageUrl);
      }
      
      // Remove from Firebase
      return await removeImageUrlFromFirebase();
    } catch (e) {
      print('Error in complete image delete flow: $e');
      return false;
    }
  }
}
