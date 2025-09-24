import 'package:cloud_firestore/cloud_firestore.dart';

class KycApplication {
  final String userId;
  final String status; // submitted | under_review | approved | rejected
  final PersonalInfo personalInfo;
  final DocumentInfo document;
  final KycAudit audit;
  final KycReview? review;

  KycApplication({
    required this.userId,
    required this.status,
    required this.personalInfo,
    required this.document,
    required this.audit,
    this.review,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'status': status,
      'personalInfo': personalInfo.toFirestore(),
      'document': document.toFirestore(),
      'audit': audit.toFirestore(),
      if (review != null) 'review': review!.toFirestore(),
    };
  }

  factory KycApplication.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    return KycApplication(
      userId: data['userId'],
      status: data['status'],
      personalInfo: PersonalInfo.fromMap(data['personalInfo']),
      document: DocumentInfo.fromMap(data['document']),
      audit: KycAudit.fromMap(data['audit']),
      review: data['review'] != null ? KycReview.fromMap(data['review']) : null,
    );
  }
}

class PersonalInfo {
  final String fullName;
  final String dateOfBirth; // ISO string format
  final AddressInfo address;

  PersonalInfo({
    required this.fullName,
    required this.dateOfBirth,
    required this.address,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'address': address.toFirestore(),
    };
  }

  factory PersonalInfo.fromMap(Map<String, dynamic> map) {
    return PersonalInfo(
      fullName: map['fullName'],
      dateOfBirth: map['dateOfBirth'],
      address: AddressInfo.fromMap(map['address']),
    );
  }
}

class AddressInfo {
  final String line1;
  final String city;
  final String postalCode;
  final String country;

  AddressInfo({
    required this.line1,
    required this.city,
    required this.postalCode,
    required this.country,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'line1': line1,
      'city': city,
      'postalCode': postalCode,
      'country': country,
    };
  }

  factory AddressInfo.fromMap(Map<String, dynamic> map) {
    return AddressInfo(
      line1: map['line1'],
      city: map['city'],
      postalCode: map['postalCode'],
      country: map['country'],
    );
  }
}

class DocumentInfo {
  final String type; // Passport | National ID | Driver's License
  final String? number;
  final String? issuingCountry;
  final String? expiryDate; // ISO string format
  final DocumentImages images;

  DocumentInfo({
    required this.type,
    this.number,
    this.issuingCountry,
    this.expiryDate,
    required this.images,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      if (number != null) 'number': number,
      if (issuingCountry != null) 'issuingCountry': issuingCountry,
      if (expiryDate != null) 'expiryDate': expiryDate,
      'images': images.toFirestore(),
    };
  }

  factory DocumentInfo.fromMap(Map<String, dynamic> map) {
    return DocumentInfo(
      type: map['type'],
      number: map['number'],
      issuingCountry: map['issuingCountry'],
      expiryDate: map['expiryDate'],
      images: DocumentImages.fromMap(map['images']),
    );
  }
}

class DocumentImages {
  final String front;
  final String? back;
  final String selfie;

  DocumentImages({
    required this.front,
    this.back,
    required this.selfie,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'front': front,
      if (back != null) 'back': back,
      'selfie': selfie,
    };
  }

  factory DocumentImages.fromMap(Map<String, dynamic> map) {
    return DocumentImages(
      front: map['front'],
      back: map['back'],
      selfie: map['selfie'],
    );
  }
}

class KycAudit {
  final String submittedAt; // ISO string format
  final String updatedAt; // ISO string format

  KycAudit({
    required this.submittedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'submittedAt': submittedAt,
      'updatedAt': updatedAt,
    };
  }

  factory KycAudit.fromMap(Map<String, dynamic> map) {
    return KycAudit(
      submittedAt: map['submittedAt'],
      updatedAt: map['updatedAt'],
    );
  }
}

class KycReview {
  final String? reviewerId;
  final String? note;
  final String reviewedAt; // ISO string format

  KycReview({
    this.reviewerId,
    this.note,
    required this.reviewedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      if (reviewerId != null) 'reviewerId': reviewerId,
      if (note != null) 'note': note,
      'reviewedAt': reviewedAt,
    };
  }

  factory KycReview.fromMap(Map<String, dynamic> map) {
    return KycReview(
      reviewerId: map['reviewerId'],
      note: map['note'],
      reviewedAt: map['reviewedAt'],
    );
  }
}

// User verification status model for mirroring to users collection
class UserVerificationStatus {
  final bool identityVerified;
  final String? identitySubmittedAt;
  final String? identityVerifiedAt;
  final String? rejectionReason;
  final List<String> submittedDocuments;

  UserVerificationStatus({
    this.identityVerified = false,
    this.identitySubmittedAt,
    this.identityVerifiedAt,
    this.rejectionReason,
    this.submittedDocuments = const [],
  });

  Map<String, dynamic> toFirestore() {
    return {
      'identityVerified': identityVerified,
      if (identitySubmittedAt != null)
        'identitySubmittedAt': identitySubmittedAt,
      if (identityVerifiedAt != null) 'identityVerifiedAt': identityVerifiedAt,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'submittedDocuments': submittedDocuments,
    };
  }

  factory UserVerificationStatus.fromMap(Map<String, dynamic> map) {
    return UserVerificationStatus(
      identityVerified: map['identityVerified'] ?? false,
      identitySubmittedAt: map['identitySubmittedAt'],
      identityVerifiedAt: map['identityVerifiedAt'],
      rejectionReason: map['rejectionReason'],
      submittedDocuments: List<String>.from(map['submittedDocuments'] ?? []),
    );
  }
}
