class UserProfile {
  final String uid;
  final String email;
  final String fullName;
  final String? username;
  final String? phoneNumber;
  final String? photoUrl;
  final DateTime dateOfBirth;
  final UserRole role;
  final VerificationStatus verificationStatus;
  final UserRatings ratings;
  final UserStats stats;
  final UserPreferences preferences;
  final List<String> verificationDocuments;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isOnline;
  final String? stripeAccountId;
  final bool isBlocked;
  final String? address;
  final String? city;
  final String? country;

  UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.dateOfBirth,
    required this.role,
    required this.verificationStatus,
    required this.ratings,
    required this.stats,
    required this.preferences,
    required this.createdAt,
    required this.lastActiveAt,
    this.username,
    this.phoneNumber,
    this.photoUrl,
    this.verificationDocuments = const [],
    this.isOnline = false,
    this.stripeAccountId,
    this.isBlocked = false,
    this.address,
    this.city,
    this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'username': username,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'role': role.name,
      'verificationStatus': verificationStatus.toJson(),
      'ratings': ratings.toJson(),
      'stats': stats.toJson(),
      'preferences': preferences.toJson(),
      'verificationDocuments': verificationDocuments,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'isOnline': isOnline,
      'stripeAccountId': stripeAccountId,
      'isBlocked': isBlocked,
      'address': address,
      'city': city,
      'country': country,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'],
      email: json['email'],
      fullName: json['fullName'],
      username: json['username'],
      phoneNumber: json['phoneNumber'],
      photoUrl: json['photoUrl'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      verificationStatus:
          VerificationStatus.fromJson(json['verificationStatus']),
      ratings: UserRatings.fromJson(json['ratings']),
      stats: UserStats.fromJson(json['stats']),
      preferences: UserPreferences.fromJson(json['preferences']),
      verificationDocuments:
          List<String>.from(json['verificationDocuments'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      lastActiveAt: DateTime.parse(json['lastActiveAt']),
      isOnline: json['isOnline'] ?? false,
      stripeAccountId: json['stripeAccountId'],
      isBlocked: json['isBlocked'] ?? false,
      address: json['address'],
      city: json['city'],
      country: json['country'],
    );
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? username,
    String? phoneNumber,
    String? photoUrl,
    DateTime? dateOfBirth,
    UserRole? role,
    VerificationStatus? verificationStatus,
    UserRatings? ratings,
    UserStats? stats,
    UserPreferences? preferences,
    List<String>? verificationDocuments,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isOnline,
    String? stripeAccountId,
    bool? isBlocked,
    String? address,
    String? city,
    String? country,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      ratings: ratings ?? this.ratings,
      stats: stats ?? this.stats,
      preferences: preferences ?? this.preferences,
      verificationDocuments:
          verificationDocuments ?? this.verificationDocuments,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isOnline: isOnline ?? this.isOnline,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      isBlocked: isBlocked ?? this.isBlocked,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }
}

class VerificationStatus {
  final bool emailVerified;
  final bool phoneVerified;
  final bool identityVerified;
  final DateTime? identitySubmittedAt;
  final DateTime? identityVerifiedAt;
  final String? rejectionReason;
  final List<String> submittedDocuments;

  VerificationStatus({
    this.emailVerified = false,
    this.phoneVerified = false,
    this.identityVerified = false,
    this.identitySubmittedAt,
    this.identityVerifiedAt,
    this.rejectionReason,
    this.submittedDocuments = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'identityVerified': identityVerified,
      'identitySubmittedAt': identitySubmittedAt?.toIso8601String(),
      'identityVerifiedAt': identityVerifiedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'submittedDocuments': submittedDocuments,
    };
  }

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      emailVerified: json['emailVerified'] ?? false,
      phoneVerified: json['phoneVerified'] ?? false,
      identityVerified: json['identityVerified'] ?? false,
      identitySubmittedAt: json['identitySubmittedAt'] != null
          ? DateTime.parse(json['identitySubmittedAt'])
          : null,
      identityVerifiedAt: json['identityVerifiedAt'] != null
          ? DateTime.parse(json['identityVerifiedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
      submittedDocuments: List<String>.from(json['submittedDocuments'] ?? []),
    );
  }
}

class UserRatings {
  final double averageRating;
  final int totalRatings;
  final int fiveStars;
  final int fourStars;
  final int threeStars;
  final int twoStars;
  final int oneStar;
  final List<UserReview> recentReviews;

  UserRatings({
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.fiveStars = 0,
    this.fourStars = 0,
    this.threeStars = 0,
    this.twoStars = 0,
    this.oneStar = 0,
    this.recentReviews = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'fiveStars': fiveStars,
      'fourStars': fourStars,
      'threeStars': threeStars,
      'twoStars': twoStars,
      'oneStar': oneStar,
      'recentReviews': recentReviews.map((e) => e.toJson()).toList(),
    };
  }

  factory UserRatings.fromJson(Map<String, dynamic> json) {
    return UserRatings(
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      fiveStars: json['fiveStars'] ?? 0,
      fourStars: json['fourStars'] ?? 0,
      threeStars: json['threeStars'] ?? 0,
      twoStars: json['twoStars'] ?? 0,
      oneStar: json['oneStar'] ?? 0,
      recentReviews: (json['recentReviews'] as List?)
              ?.map((item) => UserReview.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class UserReview {
  final String reviewerId;
  final String reviewerName;
  final String reviewerPhotoUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? transactionId;

  UserReview({
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.transactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhotoUrl': reviewerPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'transactionId': transactionId,
    };
  }

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      reviewerId: json['reviewerId'],
      reviewerName: json['reviewerName'],
      reviewerPhotoUrl: json['reviewerPhotoUrl'],
      rating: json['rating'].toDouble(),
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      transactionId: json['transactionId'],
    );
  }
}

class UserStats {
  final int totalDeliveries;
  final int totalPackagesSent;
  final int completedTrips;
  final double totalEarnings;
  final double totalSpent;
  final double reliabilityScore;
  final int onTimeDeliveries;
  final int lateDeliveries;
  final DateTime? lastDelivery;

  UserStats({
    this.totalDeliveries = 0,
    this.totalPackagesSent = 0,
    this.completedTrips = 0,
    this.totalEarnings = 0.0,
    this.totalSpent = 0.0,
    this.reliabilityScore = 100.0,
    this.onTimeDeliveries = 0,
    this.lateDeliveries = 0,
    this.lastDelivery,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalDeliveries': totalDeliveries,
      'totalPackagesSent': totalPackagesSent,
      'completedTrips': completedTrips,
      'totalEarnings': totalEarnings,
      'totalSpent': totalSpent,
      'reliabilityScore': reliabilityScore,
      'onTimeDeliveries': onTimeDeliveries,
      'lateDeliveries': lateDeliveries,
      'lastDelivery': lastDelivery?.toIso8601String(),
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalDeliveries: json['totalDeliveries'] ?? 0,
      totalPackagesSent: json['totalPackagesSent'] ?? 0,
      completedTrips: json['completedTrips'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
      reliabilityScore: (json['reliabilityScore'] ?? 100.0).toDouble(),
      onTimeDeliveries: json['onTimeDeliveries'] ?? 0,
      lateDeliveries: json['lateDeliveries'] ?? 0,
      lastDelivery: json['lastDelivery'] != null
          ? DateTime.parse(json['lastDelivery'])
          : null,
    );
  }
}

class UserPreferences {
  final bool allowsNotifications;
  final bool allowsEmailMarketing;
  final bool allowsSMSNotifications;
  final String preferredLanguage;
  final String preferredCurrency;
  final List<String> preferredTransportModes;
  final double maxDetourKm;
  final bool autoAcceptMatches;

  UserPreferences({
    this.allowsNotifications = true,
    this.allowsEmailMarketing = false,
    this.allowsSMSNotifications = true,
    this.preferredLanguage = 'en',
    this.preferredCurrency = 'USD',
    this.preferredTransportModes = const [],
    this.maxDetourKm = 10.0,
    this.autoAcceptMatches = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'allowsNotifications': allowsNotifications,
      'allowsEmailMarketing': allowsEmailMarketing,
      'allowsSMSNotifications': allowsSMSNotifications,
      'preferredLanguage': preferredLanguage,
      'preferredCurrency': preferredCurrency,
      'preferredTransportModes': preferredTransportModes,
      'maxDetourKm': maxDetourKm,
      'autoAcceptMatches': autoAcceptMatches,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      allowsNotifications: json['allowsNotifications'] ?? true,
      allowsEmailMarketing: json['allowsEmailMarketing'] ?? false,
      allowsSMSNotifications: json['allowsSMSNotifications'] ?? true,
      preferredLanguage: json['preferredLanguage'] ?? 'en',
      preferredCurrency: json['preferredCurrency'] ?? 'USD',
      preferredTransportModes:
          List<String>.from(json['preferredTransportModes'] ?? []),
      maxDetourKm: (json['maxDetourKm'] ?? 10.0).toDouble(),
      autoAcceptMatches: json['autoAcceptMatches'] ?? false,
    );
  }
}

enum UserRole { sender, traveler, both }
