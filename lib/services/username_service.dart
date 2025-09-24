import 'package:cloud_firestore/cloud_firestore.dart';

class UsernameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _usersCollection = 'users';
  static const String _usernamesCollection = 'usernames';

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final doc = await _firestore
          .collection(_usernamesCollection)
          .doc(username.toLowerCase())
          .get();

      return !doc.exists;
    } catch (e) {
      throw Exception('Failed to check username availability: $e');
    }
  }

  /// Reserve a username for a user
  Future<void> reserveUsername(String username, String userId) async {
    try {
      // Check if username is available first
      final isAvailable = await isUsernameAvailable(username);
      if (!isAvailable) {
        throw Exception('Username is already taken');
      }

      // Reserve the username
      await _firestore
          .collection(_usernamesCollection)
          .doc(username.toLowerCase())
          .set({
        'userId': userId,
        'originalUsername': username,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reserve username: $e');
    }
  }

  /// Find user ID by username
  Future<String?> getUserIdByUsername(String username) async {
    try {
      final doc = await _firestore
          .collection(_usernamesCollection)
          .doc(username.toLowerCase())
          .get();

      if (doc.exists) {
        return doc.data()?['userId'];
      }
      return null;
    } catch (e) {
      throw Exception('Failed to find user by username: $e');
    }
  }

  /// Get user email by username (for login purposes)
  Future<String?> getUserEmailByUsername(String username) async {
    try {
      final userId = await getUserIdByUsername(username);
      if (userId == null) return null;

      final userDoc =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (userDoc.exists) {
        return userDoc.data()?['email'];
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user email by username: $e');
    }
  }

  /// Release a username when user changes it or deletes account
  Future<void> releaseUsername(String username) async {
    try {
      await _firestore
          .collection(_usernamesCollection)
          .doc(username.toLowerCase())
          .delete();
    } catch (e) {
      throw Exception('Failed to release username: $e');
    }
  }
}
