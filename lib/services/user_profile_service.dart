import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _usersCollection = 'users';

  /// Get current user's profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc =
          await _firestore.collection(_usersCollection).doc(user.uid).get();

      if (doc.exists) {
        return UserProfile.fromJson({
          'uid': user.uid,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (doc.exists) {
        return UserProfile.fromJson({
          'uid': userId,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Create a new user profile
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      final profileData = profile.toJson();
      profileData.remove('uid'); // Don't store uid in the document

      await _firestore
          .collection(_usersCollection)
          .doc(profile.uid)
          .set(profileData);
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? photoUrl,
    UserRole? role,
    Map<String, dynamic>? preferences,
    String? address,
    String? city,
    String? country,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final Map<String, dynamic> updates = {};

      if (fullName != null) updates['fullName'] = fullName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (dateOfBirth != null)
        updates['dateOfBirth'] = dateOfBirth.toIso8601String();
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (role != null) updates['role'] = role.name;
      if (preferences != null) updates['preferences'] = preferences;
      if (address != null) updates['address'] = address;
      if (city != null) updates['city'] = city;
      if (country != null) updates['country'] = country;

      // Always update lastActiveAt when profile is updated
      updates['lastActiveAt'] = DateTime.now().toIso8601String();

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .update(updates);

      // Also update Firebase Auth profile if name or photo changed
      if (fullName != null || photoUrl != null) {
        try {
          if (fullName != null) {
            await user.updateDisplayName(fullName);
          }
          if (photoUrl != null && photoUrl.isNotEmpty) {
            await user.updatePhotoURL(photoUrl);
          }
        } catch (authError) {
          // Log auth error but don't throw - Firestore update was successful
          print('Firebase Auth profile update failed: $authError');
        }
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Update user address specifically
  Future<void> updateUserAddress({
    required String address,
    required String city,
    required String country,
    String? postalCode,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final updates = <String, dynamic>{
        'address': address,
        'city': city,
        'country': country,
        'lastActiveAt': DateTime.now().toIso8601String(),
      };

      if (postalCode != null && postalCode.isNotEmpty) {
        updates['postalCode'] = postalCode;
      }

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update user address: $e');
    }
  }

  /// Upload profile photo as Base64 (Free - no Firebase Storage needed!)
  Future<String> uploadProfilePhoto(File imageFile) async {
    try {
      // Read image as bytes
      final bytes = await imageFile.readAsBytes();

      // Check file size (Firestore document limit is 1MB)
      if (bytes.length > 800000) {
        // 800KB to be safe
        throw Exception(
            'Image too large. Please select a smaller image (max 800KB).');
      }

      // Convert to Base64
      final String base64Image = base64Encode(bytes);
      final String photoData = 'data:image/jpeg;base64,$base64Image';

      // Update user profile with Base64 photo data
      await updateUserProfile(photoUrl: photoData);

      return photoData;
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  /// Update profile photo with Base64 data directly
  Future<void> updateProfilePhotoBase64(String base64Data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Ensure the base64 data has the proper data URL prefix
      String photoData = base64Data;
      if (!base64Data.startsWith('data:image/')) {
        photoData = 'data:image/jpeg;base64,$base64Data';
      }

      await updateUserProfile(photoUrl: photoData);
    } catch (e) {
      throw Exception('Failed to update profile photo: $e');
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _firestore.collection(_usersCollection).doc(user.uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  /// Update user online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection(_usersCollection).doc(user.uid).update({
        'isOnline': isOnline,
        'lastActiveAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update online status: $e');
    }
  }

  /// Stream of current user's profile
  Stream<UserProfile?> getCurrentUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserProfile.fromJson({
          'uid': user.uid,
          ...doc.data()!,
        });
      }
      return null;
    });
  }

  /// Check if profile exists
  Future<bool> profileExists(String userId) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Update user verification status
  Future<void> updateVerificationStatus(String status, {String? reason}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _firestore.collection(_usersCollection).doc(user.uid).update({
        'verificationStatus.status': status,
        if (reason != null) 'verificationStatus.reason': reason,
        'verificationStatus.updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update verification status: $e');
    }
  }

  /// Update email verification status specifically
  Future<void> updateEmailVerificationStatus(bool isEmailVerified) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _firestore.collection(_usersCollection).doc(user.uid).update({
        'verificationStatus.emailVerified': isEmailVerified,
        'lastActiveAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update email verification status: $e');
    }
  }
}
