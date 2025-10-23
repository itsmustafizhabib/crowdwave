import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/kyc_data_model.dart';
import 'image_storage_service.dart';

// Cache entry for KYC status
class _KycStatusCache {
  final String? status;
  final bool isApproved;
  final DateTime timestamp;

  _KycStatusCache({
    required this.status,
    required this.isApproved,
    required this.timestamp,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > const Duration(minutes: 5);
  }
}

class KycService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageStorageService _imageStorage = ImageStorageService();

  // Collections
  static const String kUsers = 'users';
  static const String kKycApplications = 'kyc_applications';

  // Cache for KYC status to prevent flickering
  static final Map<String, _KycStatusCache> _kycStatusCache = {};

  // Convert file to base64 string (no Firebase Storage needed!)
  Future<String> uploadKycFile({
    required File file,
    required String userId,
    required String type, // e.g., 'documentFront', 'documentBack', 'selfie'
  }) async {
    try {
      print('🖼️ Converting KYC file to base64...');

      // Use the global image storage service
      final base64String = await _imageStorage.fileToBase64(file);

      print(
          '✅ KYC file converted to base64 (${base64String.length} characters)');
      return base64String;
    } catch (e) {
      print('❌ Error converting KYC file: $e');
      throw Exception('Failed to process KYC file: $e');
    }
  }

  // Create or update a KYC application document
  Future<String> submitKyc({
    // Personal info
    required String fullName,
    required DateTime dateOfBirth,
    required String addressLine,
    required String city,
    required String postalCode,
    required String country,
    // Document info
    required String documentType, // Passport | National ID | Driver's License
    String? documentNumber,
    String? issuingCountry,
    DateTime? expiryDate,
    // Base64 encoded images (no Firebase Storage needed!)
    required String documentFrontBase64,
    String? documentBackBase64,
    required String selfieBase64,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    try {
      print('📝 KycService: Starting KYC submission...');

      // Validate inputs
      if (fullName.trim().isEmpty) {
        throw Exception('Full name is required');
      }
      if (addressLine.trim().isEmpty) {
        throw Exception('Address line is required');
      }
      if (city.trim().isEmpty) {
        throw Exception('City is required');
      }
      if (postalCode.trim().isEmpty) {
        throw Exception('Postal code is required');
      }
      if (country.trim().isEmpty) {
        throw Exception('Country is required');
      }
      if (documentFrontBase64.trim().isEmpty) {
        throw Exception('Document front image is required');
      }
      if (selfieBase64.trim().isEmpty) {
        throw Exception('Selfie image is required');
      }

      final now = DateTime.now();
      final docRef = _firestore.collection(kKycApplications).doc(user.uid);

      print('📝 Creating PersonalInfo object...');
      // Create structured KYC application
      final personalInfo = PersonalInfo(
        fullName: fullName.trim(),
        dateOfBirth: dateOfBirth.toIso8601String(),
        address: AddressInfo(
          line1: addressLine.trim(),
          city: city.trim(),
          postalCode: postalCode.trim(),
          country: country.trim(),
        ),
      );

      print('📝 Creating DocumentImages object...');
      print(
          '   Document front size: ${documentFrontBase64.length} characters (~${(documentFrontBase64.length / 1024).toStringAsFixed(2)} KB)');
      if (documentBackBase64 != null) {
        print(
            '   Document back size: ${documentBackBase64.length} characters (~${(documentBackBase64.length / 1024).toStringAsFixed(2)} KB)');
      }
      print(
          '   Selfie size: ${selfieBase64.length} characters (~${(selfieBase64.length / 1024).toStringAsFixed(2)} KB)');

      // Check if any image is too large (Firestore has 1MB document limit)
      final totalSize = documentFrontBase64.length +
          (documentBackBase64?.length ?? 0) +
          selfieBase64.length;
      final totalSizeKB = totalSize / 1024;
      print(
          '   Total images size: $totalSize characters (~${totalSizeKB.toStringAsFixed(2)} KB)');

      // Firestore document limit is 1MB (1,048,576 bytes)
      // Base64 encoding adds ~33% overhead, so we need to be conservative
      // Allow max 700KB (716,800 bytes) for images to leave room for other data
      if (totalSize > 700000) {
        throw Exception(
            'Images are too large (${totalSizeKB.toStringAsFixed(2)} KB). '
            'Maximum allowed is 700 KB. Please retake photos - they will be '
            'automatically compressed. If the issue persists, contact support.');
      }

      print(
          '✅ Image size check passed (${totalSizeKB.toStringAsFixed(2)} KB / 700 KB limit)');

      final documentImages = DocumentImages(
        front: documentFrontBase64.trim(),
        back: documentBackBase64?.trim(),
        selfie: selfieBase64.trim(),
      );

      print('📝 Creating DocumentInfo object...');
      final documentInfo = DocumentInfo(
        type: documentType.trim(),
        number: documentNumber?.trim(),
        issuingCountry: issuingCountry?.trim(),
        expiryDate: expiryDate?.toIso8601String(),
        images: documentImages,
      );

      print('📝 Creating KycAudit object...');
      final audit = KycAudit(
        submittedAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      );

      print('📝 Creating KycApplication object...');
      final kycApplication = KycApplication(
        userId: user.uid,
        status: 'submitted',
        personalInfo: personalInfo,
        document: documentInfo,
        audit: audit,
      );

      print('📤 Converting to Firestore format...');
      final firestoreData = kycApplication.toFirestore();

      // Log data structure (without base64 content for brevity)
      print('📊 Firestore data structure:');
      print('   userId: ${firestoreData['userId']}');
      print('   status: ${firestoreData['status']}');
      print(
          '   personalInfo keys: ${(firestoreData['personalInfo'] as Map).keys}');
      print('   document keys: ${(firestoreData['document'] as Map).keys}');
      print('   audit keys: ${(firestoreData['audit'] as Map).keys}');

      // Save to kyc_applications collection
      print('💾 Saving to Firestore kyc_applications collection...');
      try {
        await docRef.set(firestoreData);
        print('✅ Saved to kyc_applications collection');
      } catch (e) {
        print('❌ Firestore set error: $e');
        // Try without merge option
        print('🔄 Retrying without merge option...');
        await docRef.set(firestoreData, SetOptions(merge: false));
        print('✅ Saved to kyc_applications collection (without merge)');
      }

      // Create verification status for users collection
      print('📝 Creating verification status...');
      final verificationStatus = UserVerificationStatus(
        identityVerified: false,
        identitySubmittedAt: now.toIso8601String(),
        submittedDocuments: [
          'documentFront',
          if (documentBackBase64 != null &&
              documentBackBase64.trim().isNotEmpty)
            'documentBack',
          'selfie',
        ],
      );

      // Mirror to users collection
      print('💾 Mirroring to users collection...');
      await _firestore.collection(kUsers).doc(user.uid).set({
        'verificationStatus': verificationStatus.toFirestore(),
      }, SetOptions(merge: true));
      print('✅ Mirrored to users collection');

      print('✅ KycService: KYC submission completed successfully!');

      // Clear cache to force refresh on next check
      clearKycCache(user.uid);

      return docRef.id;
    } catch (e, stackTrace) {
      print('❌ KycService: Failed to submit KYC');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to submit KYC: $e');
    }
  }

  // Update application review status (admin/backoffice flow)
  Future<void> updateKycReviewStatus({
    required String userId,
    required String status, // under_review | approved | rejected
    String? reviewerId,
    String? note,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = _firestore.collection(kKycApplications).doc(userId);

      final review = KycReview(
        reviewerId: reviewerId,
        note: note,
        reviewedAt: now.toIso8601String(),
      );

      await docRef.set({
        'status': status,
        'review': review.toFirestore(),
        'audit': {
          'updatedAt': now.toIso8601String(),
        }
      }, SetOptions(merge: true));

      // Mirror to users collection
      final verificationStatusUpdate = <String, dynamic>{
        'identityVerified': status == 'approved',
      };

      if (status == 'approved') {
        verificationStatusUpdate['identityVerifiedAt'] = now.toIso8601String();
        verificationStatusUpdate['rejectionReason'] = null;
      } else if (status == 'rejected') {
        verificationStatusUpdate['rejectionReason'] =
            note ?? 'KYC application rejected';
      }

      await _firestore.collection(kUsers).doc(userId).set({
        'verificationStatus': verificationStatusUpdate,
      }, SetOptions(merge: true));

      // Clear cache to force refresh on next check
      clearKycCache(userId);
    } catch (e) {
      throw Exception('Failed to update KYC review status: $e');
    }
  }

  // Get KYC application status for a user
  Future<KycApplication?> getKycApplication(String userId) async {
    try {
      final doc =
          await _firestore.collection(kKycApplications).doc(userId).get();
      if (!doc.exists) {
        return null;
      }
      return KycApplication.fromFirestore(doc, null);
    } catch (e) {
      throw Exception('Failed to get KYC application: $e');
    }
  }

  // Check if user has submitted AND APPROVED KYC
  Future<bool> hasSubmittedKyc(String userId) async {
    try {
      // Check cache first
      final cached = _kycStatusCache[userId];
      if (cached != null && !cached.isExpired) {
        print(
            '✨ Using cached KYC approval status for $userId: ${cached.isApproved}');
        return cached.isApproved;
      }

      final doc =
          await _firestore.collection(kKycApplications).doc(userId).get();

      if (!doc.exists) {
        // Cache the "not submitted" status
        _kycStatusCache[userId] = _KycStatusCache(
          status: null,
          isApproved: false,
          timestamp: DateTime.now(),
        );
        return false;
      }

      // Check if KYC status is 'approved'
      final data = doc.data();
      final status = data?['status'] as String?;
      final isApproved = status == 'approved';

      // Cache the result
      _kycStatusCache[userId] = _KycStatusCache(
        status: status,
        isApproved: isApproved,
        timestamp: DateTime.now(),
      );

      print('🔍 KYC Status for user $userId: $status (cached)');

      // Only return true if status is 'approved'
      return isApproved;
    } catch (e) {
      print('❌ Error checking KYC status: $e');
      throw Exception('Failed to check KYC submission status: $e');
    }
  }

  // Get KYC status (pending, approved, rejected, or null if not submitted)
  Future<String?> getKycStatus(String userId) async {
    try {
      // Check cache first
      final cached = _kycStatusCache[userId];
      if (cached != null && !cached.isExpired) {
        print('✨ Using cached KYC status for $userId: ${cached.status}');
        return cached.status;
      }

      final doc =
          await _firestore.collection(kKycApplications).doc(userId).get();

      if (!doc.exists) {
        // Cache the "not submitted" status
        _kycStatusCache[userId] = _KycStatusCache(
          status: null,
          isApproved: false,
          timestamp: DateTime.now(),
        );
        return null; // No KYC submitted
      }

      final data = doc.data();
      final status = data?['status'] as String?;

      // Cache the result
      _kycStatusCache[userId] = _KycStatusCache(
        status: status,
        isApproved: status == 'approved',
        timestamp: DateTime.now(),
      );

      print('🔍 KYC Status check for user $userId: $status (cached)');

      return status; // Returns: 'pending', 'submitted', 'approved', 'rejected', or null
    } catch (e) {
      print('❌ Error getting KYC status: $e');
      throw Exception('Failed to get KYC status: $e');
    }
  }

  // Clear cache for a specific user (call this after KYC submission or status update)
  static void clearKycCache(String userId) {
    _kycStatusCache.remove(userId);
    print('🗑️ Cleared KYC cache for user $userId');
  }

  // Clear all KYC cache
  static void clearAllKycCache() {
    _kycStatusCache.clear();
    print('🗑️ Cleared all KYC cache');
  }

  // Get user verification status
  Future<UserVerificationStatus?> getUserVerificationStatus(
      String userId) async {
    try {
      final doc = await _firestore.collection(kUsers).doc(userId).get();
      final data = doc.data();
      if (data == null || data['verificationStatus'] == null) {
        return null;
      }
      return UserVerificationStatus.fromMap(data['verificationStatus']);
    } catch (e) {
      throw Exception('Failed to get user verification status: $e');
    }
  }
}
