import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/kyc_data_model.dart';
import 'image_storage_service.dart';

class KycService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageStorageService _imageStorage = ImageStorageService();

  // Collections
  static const String kUsers = 'users';
  static const String kKycApplications = 'kyc_applications';

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
      final now = DateTime.now();
      final docRef = _firestore.collection(kKycApplications).doc(user.uid);

      // Create structured KYC application
      final personalInfo = PersonalInfo(
        fullName: fullName,
        dateOfBirth: dateOfBirth.toIso8601String(),
        address: AddressInfo(
          line1: addressLine,
          city: city,
          postalCode: postalCode,
          country: country,
        ),
      );

      final documentImages = DocumentImages(
        front: documentFrontBase64,
        back: documentBackBase64,
        selfie: selfieBase64,
      );

      final documentInfo = DocumentInfo(
        type: documentType,
        number: documentNumber,
        issuingCountry: issuingCountry,
        expiryDate: expiryDate?.toIso8601String(),
        images: documentImages,
      );

      final audit = KycAudit(
        submittedAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      );

      final kycApplication = KycApplication(
        userId: user.uid,
        status: 'submitted',
        personalInfo: personalInfo,
        document: documentInfo,
        audit: audit,
      );

      // Save to kyc_applications collection
      await docRef.set(kycApplication.toFirestore(), SetOptions(merge: true));

      // Create verification status for users collection
      final verificationStatus = UserVerificationStatus(
        identityVerified: false,
        identitySubmittedAt: now.toIso8601String(),
        submittedDocuments: [
          'documentFront',
          if (documentBackBase64 != null) 'documentBack',
          'selfie',
        ],
      );

      // Mirror to users collection
      await _firestore.collection(kUsers).doc(user.uid).set({
        'verificationStatus': verificationStatus.toFirestore(),
      }, SetOptions(merge: true));

      return docRef.id;
    } catch (e) {
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

  // Check if user has submitted KYC
  Future<bool> hasSubmittedKyc(String userId) async {
    try {
      final doc =
          await _firestore.collection(kKycApplications).doc(userId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check KYC submission status: $e');
    }
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
