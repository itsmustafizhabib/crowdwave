import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/forum/forum_post_model.dart';
import '../../models/forum/forum_comment_model.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new forum post
  Future<String> createPost({
    required String content,
    List<String> imageUrls = const [],
    String? category,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user details
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final post = ForumPost(
        id: '',
        userId: user.uid,
        userName: userData['displayName'] ?? user.displayName ?? 'Anonymous',
        userPhotoUrl: userData['photoURL'] ?? user.photoURL,
        content: content,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        category: category ?? 'general',
      );

      final docRef =
          await _firestore.collection('forum_posts').add(post.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  // Get all posts (real-time stream)
  Stream<List<ForumPost>> getPosts({String? category, int limit = 50}) {
    Query query = _firestore
        .collection('forum_posts')
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true);

    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumPost.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get a single post by ID
  Future<ForumPost?> getPost(String postId) async {
    try {
      final doc = await _firestore.collection('forum_posts').doc(postId).get();
      if (doc.exists) {
        return ForumPost.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }

  // Update a post
  Future<void> updatePost(String postId, String content,
      {List<String>? imageUrls}) async {
    try {
      final updateData = {
        'content': content,
        'updatedAt': Timestamp.now(),
      };

      if (imageUrls != null) {
        updateData['imageUrls'] = imageUrls;
      }

      await _firestore.collection('forum_posts').doc(postId).update(updateData);
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      // Delete all comments first
      final commentsSnapshot = await _firestore
          .collection('forum_comments')
          .where('postId', isEqualTo: postId)
          .get();

      final batch = _firestore.batch();
      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the post
      batch.delete(_firestore.collection('forum_posts').doc(postId));
      await batch.commit();
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  // Like/Unlike a post
  Future<void> toggleLikePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final postRef = _firestore.collection('forum_posts').doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) return;

      final likedBy = List<String>.from(postDoc.data()?['likedBy'] ?? []);
      final likesCount = postDoc.data()?['likesCount'] ?? 0;

      if (likedBy.contains(user.uid)) {
        // Unlike
        likedBy.remove(user.uid);
        await postRef.update({
          'likedBy': likedBy,
          'likesCount': likesCount > 0 ? likesCount - 1 : 0,
        });
      } else {
        // Like
        likedBy.add(user.uid);
        await postRef.update({
          'likedBy': likedBy,
          'likesCount': likesCount + 1,
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  // Add a comment to a post
  Future<String> addComment(String postId, String content) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user details
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final comment = ForumComment(
        id: '',
        postId: postId,
        userId: user.uid,
        userName: userData['displayName'] ?? user.displayName ?? 'Anonymous',
        userPhotoUrl: userData['photoURL'] ?? user.photoURL,
        content: content,
        createdAt: DateTime.now(),
      );

      final docRef =
          await _firestore.collection('forum_comments').add(comment.toMap());

      // Update comment count in post
      await _firestore.collection('forum_posts').doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  // Get comments for a post (real-time stream)
  Stream<List<ForumComment>> getComments(String postId) {
    return _firestore
        .collection('forum_comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumComment.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Delete a comment
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _firestore.collection('forum_comments').doc(commentId).delete();

      // Update comment count in post
      await _firestore.collection('forum_posts').doc(postId).update({
        'commentsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  // Like/Unlike a comment
  Future<void> toggleLikeComment(String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final commentRef = _firestore.collection('forum_comments').doc(commentId);
      final commentDoc = await commentRef.get();

      if (!commentDoc.exists) return;

      final likedBy = List<String>.from(commentDoc.data()?['likedBy'] ?? []);
      final likesCount = commentDoc.data()?['likesCount'] ?? 0;

      if (likedBy.contains(user.uid)) {
        // Unlike
        likedBy.remove(user.uid);
        await commentRef.update({
          'likedBy': likedBy,
          'likesCount': likesCount > 0 ? likesCount - 1 : 0,
        });
      } else {
        // Like
        likedBy.add(user.uid);
        await commentRef.update({
          'likedBy': likedBy,
          'likesCount': likesCount + 1,
        });
      }
    } catch (e) {
      print('Error toggling comment like: $e');
      rethrow;
    }
  }

  // Report a post
  Future<void> reportPost(String postId, String reason) async {
    try {
      await _firestore.collection('forum_reports').add({
        'postId': postId,
        'reportedBy': currentUserId,
        'reason': reason,
        'createdAt': Timestamp.now(),
        'type': 'post',
      });

      // Optionally mark the post as reported
      await _firestore.collection('forum_posts').doc(postId).update({
        'isReported': true,
      });
    } catch (e) {
      print('Error reporting post: $e');
      rethrow;
    }
  }

  // Pin/Unpin a post (admin only)
  Future<void> togglePinPost(String postId) async {
    try {
      final postRef = _firestore.collection('forum_posts').doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) return;

      final isPinned = postDoc.data()?['isPinned'] ?? false;
      await postRef.update({'isPinned': !isPinned});
    } catch (e) {
      print('Error toggling pin: $e');
      rethrow;
    }
  }

  // Search posts
  Future<List<ForumPost>> searchPosts(String query) async {
    try {
      // Note: This is a basic search. For better search functionality,
      // consider using Algolia or ElasticSearch
      final snapshot = await _firestore
          .collection('forum_posts')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final posts = snapshot.docs
          .map((doc) =>
              ForumPost.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((post) =>
              post.content.toLowerCase().contains(query.toLowerCase()) ||
              post.userName.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return posts;
    } catch (e) {
      print('Error searching posts: $e');
      return [];
    }
  }

  // Get user's posts
  Stream<List<ForumPost>> getUserPosts(String userId) {
    return _firestore
        .collection('forum_posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumPost.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
