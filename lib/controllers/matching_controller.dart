import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../core/models/models.dart';
import '../services/matching_service.dart';

class MatchingController extends GetxController {
  final MatchingService _matchingService = MatchingService();

  // Observable states
  final RxList<MatchResult> _matches = <MatchResult>[].obs;
  final RxList<TravelTrip> _potentialTrips = <TravelTrip>[].obs;
  final RxList<NearbySuggestion> _nearbyPackages = <NearbySuggestion>[].obs;
  final RxList<NearbySuggestion> _nearbyTrips = <NearbySuggestion>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isAutoMatchingEnabled = true.obs;
  final Rx<String?> _error = Rx<String?>(null);

  // Current user's matching preferences
  final Rx<UserMatchingPreferences?> _userPreferences =
      Rx<UserMatchingPreferences?>(null);
  final Rx<MatchingCriteria> _currentCriteria =
      Rx<MatchingCriteria>(const MatchingCriteria());

  // Getters
  List<MatchResult> get matches => _matches;
  List<TravelTrip> get potentialTrips => _potentialTrips;
  List<NearbySuggestion> get nearbyPackages => _nearbyPackages;
  List<NearbySuggestion> get nearbyTrips => _nearbyTrips;
  bool get isLoading => _isLoading.value;
  bool get isAutoMatchingEnabled => _isAutoMatchingEnabled.value;
  String? get error => _error.value;
  UserMatchingPreferences? get userPreferences => _userPreferences.value;
  MatchingCriteria get currentCriteria => _currentCriteria.value;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      // Load user preferences if user is logged in
      // For now, we'll skip this since we don't have user management yet
      debugPrint('Matching Controller initialized');
    } catch (e) {
      _setError('Failed to initialize matching: $e');
    }
  }

  // Auto-matching methods
  Future<void> findAutoMatches(String packageRequestId) async {
    try {
      _setLoading(true);
      _clearError();

      final results = await _matchingService.findMatches(
        packageRequestId: packageRequestId,
        criteria: _currentCriteria.value,
      );

      _matches.assignAll(results);

      if (results.isEmpty) {
        _setError('No matches found for your package');
      }
    } catch (e) {
      _setError('Failed to find matches: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Manual matching methods
  Future<void> findPotentialTrips(PackageRequest packageRequest) async {
    try {
      _setLoading(true);
      _clearError();

      final trips = await _matchingService.findPotentialTrips(
        packageRequest: packageRequest,
        criteria: _currentCriteria.value,
      );

      _potentialTrips.assignAll(trips);

      if (trips.isEmpty) {
        _setError('No potential trips found matching your criteria');
      }
    } catch (e) {
      _setError('Failed to find potential trips: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Match management
  Future<void> acceptMatch(String matchId, {double? negotiatedPrice}) async {
    try {
      _setLoading(true);
      _clearError();

      await _matchingService.acceptMatch(matchId,
          negotiatedPrice: negotiatedPrice);

      // Update the match in the local list
      final matchIndex = _matches.indexWhere((match) => match.id == matchId);
      if (matchIndex != -1) {
        final updatedMatch = _matches[matchIndex].copyWith(
          status: MatchStatus.accepted,
          acceptedAt: DateTime.now(),
          negotiatedPrice: negotiatedPrice,
        );
        _matches[matchIndex] = updatedMatch;
      }

      Get.snackbar(
        'Success',
        'Match accepted successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _setError('Failed to accept match: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectMatch(String matchId, String reason) async {
    try {
      _setLoading(true);
      _clearError();

      await _matchingService.rejectMatch(matchId, reason);

      // Update the match in the local list
      final matchIndex = _matches.indexWhere((match) => match.id == matchId);
      if (matchIndex != -1) {
        final updatedMatch = _matches[matchIndex].copyWith(
          status: MatchStatus.rejected,
          rejectedAt: DateTime.now(),
          rejectionReason: reason,
        );
        _matches[matchIndex] = updatedMatch;
      }

      Get.snackbar(
        'Match Rejected',
        'Match has been rejected',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _setError('Failed to reject match: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Nearby suggestions
  Future<void> loadNearbyPackages({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final packages = await _matchingService.getNearbyPackages(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      _nearbyPackages.assignAll(packages);
    } catch (e) {
      _setError('Failed to load nearby packages: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadNearbyTrips({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final trips = await _matchingService.getNearbyTrips(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      _nearbyTrips.assignAll(trips);
    } catch (e) {
      _setError('Failed to load nearby trips: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Filtering and criteria management
  void updateMatchingCriteria(MatchingCriteria criteria) {
    _currentCriteria.value = criteria;
    _clearError();
  }

  void resetCriteria() {
    _currentCriteria.value = const MatchingCriteria();
    _clearError();
  }

  // Filter methods for UI
  void filterByDate({DateTime? startDate, DateTime? endDate}) {
    final updatedCriteria = _currentCriteria.value.copyWith(
      startDate: startDate,
      endDate: endDate,
    );
    updateMatchingCriteria(updatedCriteria);
  }

  void filterByPackageSize(PackageSize maxSize) {
    final updatedCriteria = _currentCriteria.value.copyWith(
      maxPackageSize: maxSize,
    );
    updateMatchingCriteria(updatedCriteria);
  }

  void filterByDistance(double maxDistance) {
    final updatedCriteria = _currentCriteria.value.copyWith(
      maxDistance: maxDistance,
    );
    updateMatchingCriteria(updatedCriteria);
  }

  void filterByRating(double minRating) {
    final updatedCriteria = _currentCriteria.value.copyWith(
      minTravelerRating: minRating,
    );
    updateMatchingCriteria(updatedCriteria);
  }

  void filterByTransportMode(TransportMode mode) {
    final updatedCriteria = _currentCriteria.value.copyWith(
      preferredTransportMode: mode,
    );
    updateMatchingCriteria(updatedCriteria);
  }

  void filterByVerifiedTravelers(bool verifiedOnly) {
    final updatedCriteria = _currentCriteria.value.copyWith(
      verifiedTravelersOnly: verifiedOnly,
    );
    updateMatchingCriteria(updatedCriteria);
  }

  void filterByUrgent(bool urgentOnly) {
    final updatedCriteria = _currentCriteria.value.copyWith(
      urgentOnly: urgentOnly,
    );
    updateMatchingCriteria(updatedCriteria);
  }

  void filterByPrice({double? minPrice, double? maxPrice}) {
    final updatedCriteria = _currentCriteria.value.copyWith(
      minCompensation: minPrice,
      maxCompensation: maxPrice,
    );
    updateMatchingCriteria(updatedCriteria);
  }

  // Auto-matching toggle
  void toggleAutoMatching(bool enabled) {
    _isAutoMatchingEnabled.value = enabled;
    if (enabled) {
      Get.snackbar(
        'Auto-Matching Enabled',
        'You will receive automatic match suggestions',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Auto-Matching Disabled',
        'You will only see manual matches',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Stream methods for real-time updates
  void listenToMatches(String packageId) {
    _matchingService.getMatchesForPackage(packageId).listen(
      (matches) {
        _matches.assignAll(matches);
      },
      onError: (error) {
        _setError('Error listening to matches: $error');
      },
    );
  }

  void listenToTravelerMatches(String travelerId) {
    _matchingService.getMatchesForTraveler(travelerId).listen(
      (matches) {
        _matches.assignAll(matches);
      },
      onError: (error) {
        _setError('Error listening to traveler matches: $error');
      },
    );
  }

  // Utility methods
  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _setError(String errorMessage) {
    _error.value = errorMessage;
    Get.snackbar(
      'Error',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _clearError() {
    _error.value = null;
  }

  // Clear methods
  void clearMatches() {
    _matches.clear();
    _clearError();
  }

  void clearPotentialTrips() {
    _potentialTrips.clear();
    _clearError();
  }

  void clearNearbyPackages() {
    _nearbyPackages.clear();
  }

  void clearNearbyTrips() {
    _nearbyTrips.clear();
  }

  void clearAll() {
    clearMatches();
    clearPotentialTrips();
    clearNearbyPackages();
    clearNearbyTrips();
    resetCriteria();
  }

  // Get match statistics
  Map<String, dynamic> getMatchStatistics() {
    final totalMatches = _matches.length;
    final acceptedMatches =
        _matches.where((m) => m.status == MatchStatus.accepted).length;
    final pendingMatches =
        _matches.where((m) => m.status == MatchStatus.pending).length;
    final rejectedMatches =
        _matches.where((m) => m.status == MatchStatus.rejected).length;

    final averageScore = totalMatches > 0
        ? _matches.map((m) => m.matchScore).reduce((a, b) => a + b) /
            totalMatches
        : 0.0;

    return {
      'totalMatches': totalMatches,
      'acceptedMatches': acceptedMatches,
      'pendingMatches': pendingMatches,
      'rejectedMatches': rejectedMatches,
      'averageScore': averageScore,
      'hasHighQualityMatches': _matches.any((m) => m.matchScore > 80),
    };
  }

  @override
  void onClose() {
    // Clean up any streams or resources
    super.onClose();
  }
}

// Extension to add copyWith method to MatchResult (if not already present)
extension MatchResultExtension on MatchResult {
  MatchResult copyWith({
    String? id,
    String? packageRequestId,
    String? tripId,
    String? senderId,
    String? travelerId,
    double? matchScore,
    MatchingType? matchingType,
    Map<String, dynamic>? matchingFactors,
    MatchStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    double? negotiatedPrice,
  }) {
    return MatchResult(
      id: id ?? this.id,
      packageRequestId: packageRequestId ?? this.packageRequestId,
      tripId: tripId ?? this.tripId,
      senderId: senderId ?? this.senderId,
      travelerId: travelerId ?? this.travelerId,
      matchScore: matchScore ?? this.matchScore,
      matchingType: matchingType ?? this.matchingType,
      matchingFactors: matchingFactors ?? this.matchingFactors,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      negotiatedPrice: negotiatedPrice ?? this.negotiatedPrice,
    );
  }
}

// Extension to add copyWith method to MatchingCriteria
extension MatchingCriteriaExtension on MatchingCriteria {
  MatchingCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    PackageSize? maxPackageSize,
    double? maxWeight,
    List<PackageType>? acceptedPackageTypes,
    double? maxDistance,
    double? minTravelerRating,
    int? maxDeliveryDays,
    double? maxCompensation,
    double? minCompensation,
    bool? urgentOnly,
    bool? verifiedTravelersOnly,
    TransportMode? preferredTransportMode,
  }) {
    return MatchingCriteria(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxPackageSize: maxPackageSize ?? this.maxPackageSize,
      maxWeight: maxWeight ?? this.maxWeight,
      acceptedPackageTypes: acceptedPackageTypes ?? this.acceptedPackageTypes,
      maxDistance: maxDistance ?? this.maxDistance,
      minTravelerRating: minTravelerRating ?? this.minTravelerRating,
      maxDeliveryDays: maxDeliveryDays ?? this.maxDeliveryDays,
      maxCompensation: maxCompensation ?? this.maxCompensation,
      minCompensation: minCompensation ?? this.minCompensation,
      urgentOnly: urgentOnly ?? this.urgentOnly,
      verifiedTravelersOnly:
          verifiedTravelersOnly ?? this.verifiedTravelersOnly,
      preferredTransportMode:
          preferredTransportMode ?? this.preferredTransportMode,
    );
  }
}
