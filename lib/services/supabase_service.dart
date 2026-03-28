import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'dart:io';

class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // Get current user
  static auth.User? get currentUser => auth.FirebaseAuth.instance.currentUser;
  
  // Storage operations
  static SupabaseStorageClient get storage => _supabase.storage;
  
  // Database operations
  static SupabaseQueryBuilder from(String table) => _supabase.from(table);
  
  // Upload profile image to Supabase Storage
  static Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = currentUser;
      if (user == null) throw 'User not logged in';
      
      // Generate unique file name
      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to Supabase Storage
      await storage
          .from('profile_images')
          .upload(fileName, imageFile);
      
      // Get public URL
      final imageUrl = storage
          .from('profile_images')
          .getPublicUrl(fileName);
      
      return imageUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }
  
  // Delete profile image from Supabase Storage
  static Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Extract file name from URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      
      // Delete from storage
      await storage
          .from('profile_images')
          .remove([fileName]);
      
      return true;
    } catch (e) {
      print('Error deleting profile image: $e');
      return false;
    }
  }
  
  // Update user profile in database
  static Future<bool> updateUserProfile({
    required String userId,
    String? profileImageUrl,
  }) async {
    try {
      final profileData = {
        'user_id': userId,
        'profile_image_url': profileImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Check if profile exists
      final existingProfile = await from('user_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existingProfile != null) {
        // Update existing profile
        await from('user_profiles')
            .update(profileData)
            .eq('user_id', userId);
      } else {
        // Insert new profile
        await from('user_profiles')
            .insert(profileData);
      }
      
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }
  
  // Get user profile from database
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  // Store expense data in Supabase
  static Future<bool> storeExpense({
    required String userId,
    required double amount,
    required String category,
    required String description,
    required DateTime date,
  }) async {
    try {
      await from('expenses').insert({
        'user_id': userId,
        'amount': amount,
        'category': category,
        'description': description,
        'date': date.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('Error storing expense: $e');
      return false;
    }
  }
  
  // Store income data in Supabase
  static Future<bool> storeIncome({
    required String userId,
    required double amount,
    required String source,
    required String description,
    required DateTime date,
  }) async {
    try {
      await from('income').insert({
        'user_id': userId,
        'amount': amount,
        'source': source,
        'description': description,
        'date': date.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('Error storing income: $e');
      return false;
    }
  }
  
  // Get expenses for user in date range
  static Future<List<Map<String, dynamic>>> getExpenses({
    required String userId,
    required int month,
    required int year,
  }) async {
    try {
      final response = await from('expenses')
          .select()
          .eq('user_id', userId)
          .gte('date', DateTime(year, month, 1).toIso8601String())
          .lte('date', DateTime(year, month + 1, 0).toIso8601String())
          .order('date', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting expenses: $e');
      return [];
    }
  }
  
  // Get income for user in date range
  static Future<List<Map<String, dynamic>>> getIncome({
    required String userId,
    required int month,
    required int year,
  }) async {
    try {
      final response = await from('income')
          .select()
          .eq('user_id', userId)
          .gte('date', DateTime(year, month, 1).toIso8601String())
          .lte('date', DateTime(year, month + 1, 0).toIso8601String())
          .order('date', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting income: $e');
      return [];
    }
  }
}
