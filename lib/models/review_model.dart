enum ReviewType { trip, package, traveler, sender }

enum ModerationStatus { pending, approved, rejected, flagged }

class Review {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerAvatar;
  final String targetId; // Trip ID or Package ID
  final ReviewType type;
  final double rating; // 1-5 stars
  final String? comment;
  final List<String>? photoUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final ModerationStatus moderationStatus;
  final List<ReviewComment> comments;
  final int helpfulCount;
  final List<String> helpfulUserIds;
  final bool isVerifiedBooking;

  Review({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerAvatar,
    required this.targetId,
    required this.type,
    required this.rating,
    this.comment,
    this.photoUrls,
    required this.createdAt,
    this.updatedAt,
    this.moderationStatus = ModerationStatus.pending,
    this.comments = const [],
    this.helpfulCount = 0,
    this.helpfulUserIds = const [],
    this.isVerifiedBooking = false,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      reviewerId: json['reviewerId'] ?? '',
      reviewerName: json['reviewerName'] ?? '',
      reviewerAvatar: json['reviewerAvatar'],
      targetId: json['targetId'] ?? '',
      type: ReviewType.values.firstWhere(
        (e) => e.toString() == 'ReviewType.${json['type']}',
        orElse: () => ReviewType.trip,
      ),
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'],
      photoUrls: json['photoUrls'] != null
          ? List<String>.from(json['photoUrls'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : null,
      moderationStatus: ModerationStatus.values.firstWhere(
        (e) => e.toString() == 'ModerationStatus.${json['moderationStatus']}',
        orElse: () => ModerationStatus.pending,
      ),
      comments: json['comments'] != null
          ? (json['comments'] as List)
              .map((c) => ReviewComment.fromJson(c))
              .toList()
          : [],
      helpfulCount: json['helpfulCount'] ?? 0,
      helpfulUserIds: json['helpfulUserIds'] != null
          ? List<String>.from(json['helpfulUserIds'])
          : [],
      isVerifiedBooking: json['isVerifiedBooking'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerAvatar': reviewerAvatar,
      'targetId': targetId,
      'type': type.toString().split('.').last,
      'rating': rating,
      'comment': comment,
      'photoUrls': photoUrls,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'moderationStatus': moderationStatus.toString().split('.').last,
      'comments': comments.map((c) => c.toJson()).toList(),
      'helpfulCount': helpfulCount,
      'helpfulUserIds': helpfulUserIds,
      'isVerifiedBooking': isVerifiedBooking,
    };
  }

  Review copyWith({
    String? id,
    String? reviewerId,
    String? reviewerName,
    String? reviewerAvatar,
    String? targetId,
    ReviewType? type,
    double? rating,
    String? comment,
    List<String>? photoUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    ModerationStatus? moderationStatus,
    List<ReviewComment>? comments,
    int? helpfulCount,
    List<String>? helpfulUserIds,
    bool? isVerifiedBooking,
  }) {
    return Review(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerAvatar: reviewerAvatar ?? this.reviewerAvatar,
      targetId: targetId ?? this.targetId,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      comments: comments ?? this.comments,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      helpfulUserIds: helpfulUserIds ?? this.helpfulUserIds,
      isVerifiedBooking: isVerifiedBooking ?? this.isVerifiedBooking,
    );
  }
}

class ReviewComment {
  final String id;
  final String commenterId;
  final String commenterName;
  final String? commenterAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final ModerationStatus moderationStatus;
  final String? replyToId; // For nested replies (max 2 levels)
  final List<ReviewComment> replies;
  final int likesCount;
  final List<String> likedByUserIds;

  ReviewComment({
    required this.id,
    required this.commenterId,
    required this.commenterName,
    this.commenterAvatar,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.moderationStatus = ModerationStatus.pending,
    this.replyToId,
    this.replies = const [],
    this.likesCount = 0,
    this.likedByUserIds = const [],
  });

  factory ReviewComment.fromJson(Map<String, dynamic> json) {
    return ReviewComment(
      id: json['id'] ?? '',
      commenterId: json['commenterId'] ?? '',
      commenterName: json['commenterName'] ?? '',
      commenterAvatar: json['commenterAvatar'],
      content: json['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : null,
      moderationStatus: ModerationStatus.values.firstWhere(
        (e) => e.toString() == 'ModerationStatus.${json['moderationStatus']}',
        orElse: () => ModerationStatus.pending,
      ),
      replyToId: json['replyToId'],
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((r) => ReviewComment.fromJson(r))
              .toList()
          : [],
      likesCount: json['likesCount'] ?? 0,
      likedByUserIds: json['likedByUserIds'] != null
          ? List<String>.from(json['likedByUserIds'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commenterId': commenterId,
      'commenterName': commenterName,
      'commenterAvatar': commenterAvatar,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'moderationStatus': moderationStatus.toString().split('.').last,
      'replyToId': replyToId,
      'replies': replies.map((r) => r.toJson()).toList(),
      'likesCount': likesCount,
      'likedByUserIds': likedByUserIds,
    };
  }

  bool get isReply => replyToId != null;

  bool get canHaveReplies =>
      replyToId == null; // Only top-level comments can have replies
}

class ReviewSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // star -> count
  final int verifiedReviewsCount;

  ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.verifiedReviewsCount,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    return ReviewSummary(
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ratingDistribution: json['ratingDistribution'] != null
          ? Map<int, int>.from(json['ratingDistribution'])
          : {},
      verifiedReviewsCount: json['verifiedReviewsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
      'verifiedReviewsCount': verifiedReviewsCount,
    };
  }
}

class ReviewFilter {
  final List<int>? starRatings; // Filter by specific star ratings
  final bool? verifiedOnly;
  final bool? withPhotos;
  final bool? withComments;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final ReviewSortBy sortBy;
  final bool ascending;

  ReviewFilter({
    this.starRatings,
    this.verifiedOnly,
    this.withPhotos,
    this.withComments,
    this.dateFrom,
    this.dateTo,
    this.sortBy = ReviewSortBy.newest,
    this.ascending = false,
  });
}

enum ReviewSortBy {
  newest,
  oldest,
  highestRated,
  lowestRated,
  mostHelpful,
}
