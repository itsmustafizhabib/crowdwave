import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/models.dart';
import '../core/repositories/package_repository.dart';
import '../core/repositories/trip_repository.dart';
import 'admin_service.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PackageRepository _packageRepository = PackageRepository();
  final TripRepository _tripRepository = TripRepository();
  final AdminService _adminService = AdminService();

  // Get current authenticated user ID
  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  static const String _matchesCollection = 'matches';
  static const String _preferencesCollection = 'userMatchingPreferences';

  // Auto-matching algorithm
  Future<List<MatchResult>> findMatches({
    required String packageRequestId,
    MatchingCriteria? criteria,
    int maxResults = 10,
  }) async {
    try {
      // Get the package request details
      final packageRequest =
          await _packageRepository.getPackageRequest(packageRequestId);
      if (packageRequest == null) {
        throw Exception('Package request not found');
      }

      // Find potential trips
      final trips = await _findPotentialTrips(packageRequest, criteria);

      // Calculate match scores and create match results
      final matches = <MatchResult>[];

      for (final trip in trips) {
        final matchScore = await _calculateMatchScore(packageRequest, trip);

        // Only include matches with a minimum score
        if (matchScore >= 30.0) {
          final matchResult = MatchResult(
            id: _generateMatchId(),
            packageRequestId: packageRequestId,
            tripId: trip.id,
            senderId: packageRequest.senderId,
            travelerId: trip.travelerId,
            matchScore: matchScore,
            matchingType: MatchingType.auto,
            matchingFactors: await _getMatchingFactors(packageRequest, trip),
            status: MatchStatus.pending,
            createdAt: DateTime.now(),
          );

          matches.add(matchResult);
        }
      }

      // Sort by match score (highest first)
      matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      // Limit results
      final limitedMatches = matches.take(maxResults).toList();

      // Save matches to Firestore
      for (final match in limitedMatches) {
        await _saveMatch(match);
      }

      // Log matching activity
      await _adminService.logSystemEvent(
        eventType: 'AUTO_MATCHING_COMPLETED',
        description:
            'Auto-matching found ${limitedMatches.length} matches for package $packageRequestId',
        metadata: {
          'packageId': packageRequestId,
          'matchesFound': limitedMatches.length,
          'topScore':
              limitedMatches.isNotEmpty ? limitedMatches.first.matchScore : 0,
        },
        userId: packageRequest.senderId,
      );

      return limitedMatches;
    } catch (e) {
      throw Exception('Failed to find matches: $e');
    }
  }

  // Manual matching - get all potential trips with basic filtering
  Future<List<TravelTrip>> findPotentialTrips({
    required PackageRequest packageRequest,
    MatchingCriteria? criteria,
  }) async {
    return await _findPotentialTrips(packageRequest, criteria);
  }

  // Find trips based on package requirements using repository
  Future<List<TravelTrip>> _findPotentialTrips(
      PackageRequest packageRequest, MatchingCriteria? criteria) async {
    try {
      // Use existing TripRepository to get available trips (excluding sender's own trips)
      final tripStream = _tripRepository.getAvailableTrips(
        excludeTravelerId: packageRequest.senderId,
        status: TripStatus.active,
      );

      // Convert stream to future for this operation
      final allTrips = await tripStream.first;

      // Apply date filters if provided
      List<TravelTrip> filteredTrips = allTrips;

      if (criteria?.startDate != null || criteria?.endDate != null) {
        filteredTrips = allTrips.where((trip) {
          if (criteria?.startDate != null &&
              trip.departureDate.isBefore(criteria!.startDate!)) {
            return false;
          }
          if (criteria?.endDate != null &&
              trip.departureDate.isAfter(criteria!.endDate!)) {
            return false;
          }
          return true;
        }).toList();
      }

      // Apply additional filtering using existing logic
      return filteredTrips
          .where((trip) => _isValidTripMatch(packageRequest, trip, criteria))
          .toList();
    } catch (e) {
      throw Exception('Failed to find potential trips: $e');
    }
  }

  // Check if a trip is a valid match for a package
  bool _isValidTripMatch(PackageRequest packageRequest, TravelTrip trip,
      MatchingCriteria? criteria) {
    // Basic validations
    if (trip.travelerId == packageRequest.senderId) return false; // Same user
    if (trip.status != TripStatus.active) return false;

    // Check available space (total packages vs capacity)
    if (trip.acceptedPackageIds.length >= trip.capacity.maxPackages)
      return false;

    // Check package size compatibility
    final maxAcceptedSize = trip.capacity.acceptedSizes.isNotEmpty
        ? trip.capacity.acceptedSizes.reduce((a, b) =>
            PackageSize.values.indexOf(a) > PackageSize.values.indexOf(b)
                ? a
                : b)
        : PackageSize.small; // default to small if none specified

    if (!_isPackageSizeCompatible(
        packageRequest.packageDetails.size, maxAcceptedSize)) {
      return false;
    }

    // Check weight compatibility
    if (packageRequest.packageDetails.weightKg > trip.capacity.maxWeightKg)
      return false;

    // Check location proximity (simplified - in production use proper geo queries)
    final pickupDistance = _calculateDistance(
      packageRequest.pickupLocation.latitude,
      packageRequest.pickupLocation.longitude,
      trip.departureLocation.latitude,
      trip.departureLocation.longitude,
    );

    final deliveryDistance = _calculateDistance(
      packageRequest.destinationLocation.latitude,
      packageRequest.destinationLocation.longitude,
      trip.destinationLocation.latitude,
      trip.destinationLocation.longitude,
    );

    // Must be within reasonable distance (default 50km)
    final maxDistance = criteria?.maxDistance ?? 50.0;
    if (pickupDistance > maxDistance || deliveryDistance > maxDistance)
      return false;

    // Check package type acceptance
    if (trip.acceptedItemTypes.isNotEmpty &&
        !trip.acceptedItemTypes.contains(packageRequest.packageDetails.type)) {
      return false;
    }

    // Check transport mode preference
    if (criteria?.preferredTransportMode != null &&
        trip.transportMode != criteria!.preferredTransportMode) {
      return false;
    }

    return true;
  }

  // Get user profile for rating information (integrate with real user data)
  Future<UserProfile?> _getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        return UserProfile.fromJson(userDoc.data()!);
      }
      return null;
    } catch (e) {
      // Return null if user profile not found, use defaults
      return null;
    }
  }

  // Calculate match score between package and trip (0-100) with real user ratings
  Future<double> _calculateMatchScore(
      PackageRequest packageRequest, TravelTrip trip) async {
    double score = 0.0;

    // Distance factor (40% weight)
    final pickupDistance = _calculateDistance(
      packageRequest.pickupLocation.latitude,
      packageRequest.pickupLocation.longitude,
      trip.departureLocation.latitude,
      trip.departureLocation.longitude,
    );

    final deliveryDistance = _calculateDistance(
      packageRequest.destinationLocation.latitude,
      packageRequest.destinationLocation.longitude,
      trip.destinationLocation.latitude,
      trip.destinationLocation.longitude,
    );

    // Closer is better (max 40 points)
    final avgDistance = (pickupDistance + deliveryDistance) / 2;
    final distanceScore = math.max(0, 40 - (avgDistance * 0.8));
    score += distanceScore;

    // Date compatibility (20% weight)
    final dateDiff = trip.departureDate
        .difference(packageRequest.preferredDeliveryDate)
        .inDays
        .abs();
    final dateScore = math.max(0, 20 - (dateDiff * 2));
    score += dateScore;

    // Traveler rating (15% weight) - integrate with real user profile data
    double ratingScore = 10.0; // Default rating bonus
    try {
      final travelerProfile = await _getUserProfile(trip.travelerId);
      if (travelerProfile != null) {
        // Use actual rating from user profile
        final avgRating = travelerProfile.ratings.averageRating;
        final ratingCount = travelerProfile.ratings.totalRatings;

        // Rating score: 0-15 points based on average rating and count
        if (ratingCount > 0) {
          ratingScore =
              (avgRating / 5.0) * 13.0; // Scale 5-star rating to 13 points

          // Bonus for experienced travelers (more ratings = more reliable)
          if (ratingCount >= 10)
            ratingScore += 2.0;
          else if (ratingCount >= 5) ratingScore += 1.0;
        }
      }
    } catch (e) {
      // Use default if user profile fetch fails
    }
    score += ratingScore;

    // Package compatibility (15% weight)
    double compatibilityScore = 0;

    // Size compatibility - use the trip's accepted sizes
    final maxAcceptedSize = trip.capacity.acceptedSizes.isNotEmpty
        ? trip.capacity.acceptedSizes.reduce((a, b) =>
            PackageSize.values.indexOf(a) > PackageSize.values.indexOf(b)
                ? a
                : b)
        : PackageSize.small;

    if (_isPackageSizeCompatible(
        packageRequest.packageDetails.size, maxAcceptedSize)) {
      compatibilityScore += 7;
    }

    // Weight compatibility
    final weightRatio =
        packageRequest.packageDetails.weightKg / trip.capacity.maxWeightKg;
    if (weightRatio <= 1.0) {
      compatibilityScore += 8 * (1.0 - weightRatio);
    }

    score += compatibilityScore;

    // Price compatibility (10% weight) - use suggested reward as comparison
    if (packageRequest.compensationOffer >= trip.suggestedReward * 0.8) {
      // Allow 20% less than suggested
      final priceRatio = math.min(
          1.0, packageRequest.compensationOffer / trip.suggestedReward);
      score += priceRatio * 10;
    }

    return math.min(100.0, score);
  }

  // Get detailed matching factors for explanation with real user data
  Future<Map<String, dynamic>> _getMatchingFactors(
      PackageRequest packageRequest, TravelTrip trip) async {
    final pickupDistance = _calculateDistance(
      packageRequest.pickupLocation.latitude,
      packageRequest.pickupLocation.longitude,
      trip.departureLocation.latitude,
      trip.departureLocation.longitude,
    );

    final deliveryDistance = _calculateDistance(
      packageRequest.destinationLocation.latitude,
      packageRequest.destinationLocation.longitude,
      trip.destinationLocation.latitude,
      trip.destinationLocation.longitude,
    );

    // Get traveler profile for real rating data
    double travelerRating = 4.5; // Default
    int travelerTotalRatings = 0; // Default

    try {
      final travelerProfile = await _getUserProfile(trip.travelerId);
      if (travelerProfile != null) {
        travelerRating = travelerProfile.ratings.averageRating;
        travelerTotalRatings = travelerProfile.ratings.totalRatings;
      }
    } catch (e) {
      // Use defaults if profile fetch fails
    }

    final maxAcceptedSize = trip.capacity.acceptedSizes.isNotEmpty
        ? trip.capacity.acceptedSizes.reduce((a, b) =>
            PackageSize.values.indexOf(a) > PackageSize.values.indexOf(b)
                ? a
                : b)
        : PackageSize.small;

    return {
      'pickupDistance': pickupDistance,
      'deliveryDistance': deliveryDistance,
      'averageDistance': (pickupDistance + deliveryDistance) / 2,
      'dateDifference': trip.departureDate
          .difference(packageRequest.preferredDeliveryDate)
          .inDays,
      'travelerRating': travelerRating, // Real rating from user profile
      'travelerTotalRatings':
          travelerTotalRatings, // Real rating count from user profile
      'packageSizeCompatible': _isPackageSizeCompatible(
          packageRequest.packageDetails.size, maxAcceptedSize),
      'weightCompatible':
          packageRequest.packageDetails.weightKg <= trip.capacity.maxWeightKg,
      'priceOffered': packageRequest.compensationOffer,
      'suggestedReward': trip.suggestedReward,
      'transportMode': trip.transportMode.name,
      'availableSpace':
          trip.capacity.maxPackages - trip.acceptedPackageIds.length,
    };
  }

  // Check if package size is compatible with trip capacity
  bool _isPackageSizeCompatible(
      PackageSize packageSize, PackageSize maxTripSize) {
    final packageIndex = PackageSize.values.indexOf(packageSize);
    final maxTripIndex = PackageSize.values.indexOf(maxTripSize);
    return packageIndex <= maxTripIndex;
  }

  // Calculate distance between two points (Haversine formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Save match result to Firestore
  Future<void> _saveMatch(MatchResult match) async {
    await _firestore
        .collection(_matchesCollection)
        .doc(match.id)
        .set(match.toMap());
  }

  // Generate unique match ID
  String _generateMatchId() {
    return _firestore.collection(_matchesCollection).doc().id;
  }

  // Get matches for a package
  Stream<List<MatchResult>> getMatchesForPackage(String packageId) {
    return _firestore
        .collection(_matchesCollection)
        .where('packageRequestId', isEqualTo: packageId)
        .orderBy('matchScore', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchResult.fromMap(doc.data()))
            .toList());
  }

  // Get matches for a traveler
  Stream<List<MatchResult>> getMatchesForTraveler(String travelerId) {
    return _firestore
        .collection(_matchesCollection)
        .where('travelerId', isEqualTo: travelerId)
        .where('status', isEqualTo: MatchStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchResult.fromMap(doc.data()))
            .toList());
  }

  // Accept a match
  Future<void> acceptMatch(String matchId, {double? negotiatedPrice}) async {
    final updateData = {
      'status': MatchStatus.accepted.name,
      'acceptedAt': Timestamp.now(),
    };

    if (negotiatedPrice != null) {
      updateData['negotiatedPrice'] = negotiatedPrice;
    }

    await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .update(updateData);
  }

  // Reject a match
  Future<void> rejectMatch(String matchId, String reason) async {
    await _firestore.collection(_matchesCollection).doc(matchId).update({
      'status': MatchStatus.rejected.name,
      'rejectedAt': Timestamp.now(),
      'rejectionReason': reason,
    });
  }

  // User preferences management
  Future<void> saveUserMatchingPreferences(
      UserMatchingPreferences preferences) async {
    await _firestore
        .collection(_preferencesCollection)
        .doc(preferences.userId)
        .set(preferences.toMap());
  }

  Future<UserMatchingPreferences?> getUserMatchingPreferences(
      String userId) async {
    final doc =
        await _firestore.collection(_preferencesCollection).doc(userId).get();

    if (doc.exists && doc.data() != null) {
      return UserMatchingPreferences.fromMap(doc.data()!);
    }
    return null;
  }

  // Nearby suggestions
  Future<List<NearbySuggestion>> getNearbyPackages({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 20,
  }) async {
    try {
      // In production, use GeoFirestore for proper geo queries
      // This is a simplified implementation
      final packages =
          await _packageRepository.getRecentPackages(limit: 100).first;

      final nearbyPackages = <NearbySuggestion>[];

      for (final package in packages) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          package.pickupLocation.latitude,
          package.pickupLocation.longitude,
        );

        if (distance <= radiusKm) {
          nearbyPackages.add(NearbySuggestion(
            id: package.id,
            title:
                'Package to ${package.destinationLocation.city ?? "Unknown"}',
            description:
                '${package.packageDetails.type.name} • ${package.packageDetails.size.name} • \$${package.compensationOffer}',
            distance: distance,
            location: LocationPoint(
              latitude: package.pickupLocation.latitude,
              longitude: package.pickupLocation.longitude,
              address: package.pickupLocation.address,
            ),
            type: 'package',
            validUntil: package.preferredDeliveryDate,
            metadata: {
              'packageType': package.packageDetails.type.name,
              'compensation': package.compensationOffer,
              'urgent': package.isUrgent,
            },
          ));
        }
      }

      // Sort by distance
      nearbyPackages.sort((a, b) => a.distance.compareTo(b.distance));

      return nearbyPackages.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get nearby packages: $e');
    }
  }

  Future<List<NearbySuggestion>> getNearbyTrips({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 20,
  }) async {
    try {
      final currentUserId = _currentUserId;

      // Get active trips from trip repository (excluding current user's trips)
      final tripStream = _tripRepository.getAvailableTrips(
        excludeTravelerId: currentUserId.isNotEmpty ? currentUserId : null,
        status: TripStatus.active,
      );

      final trips = await tripStream.first;

      final nearbyTrips = <NearbySuggestion>[];

      for (final trip in trips) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          trip.departureLocation.latitude,
          trip.departureLocation.longitude,
        );

        final availableSpace =
            trip.capacity.maxPackages - trip.acceptedPackageIds.length;
        if (distance <= radiusKm && availableSpace > 0) {
          nearbyTrips.add(NearbySuggestion(
            id: trip.id,
            title: 'Trip to ${trip.destinationLocation.city ?? "Unknown"}',
            description:
                '${trip.transportMode.name} • $availableSpace spaces • \$${trip.suggestedReward}+',
            distance: distance,
            location: LocationPoint(
              latitude: trip.departureLocation.latitude,
              longitude: trip.departureLocation.longitude,
              address: trip.departureLocation.address,
            ),
            type: 'trip',
            validUntil: trip.departureDate,
            metadata: {
              'transportMode': trip.transportMode.name,
              'availableSpace': availableSpace,
              'suggestedReward': trip.suggestedReward,
            },
          ));
        }
      }

      // Sort by distance
      nearbyTrips.sort((a, b) => a.distance.compareTo(b.distance));

      return nearbyTrips.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get nearby trips: $e');
    }
  }
}
