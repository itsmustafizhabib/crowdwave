import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../services/matching_service.dart';
import '../services/firebase_auth_service.dart';
import '../core/models/models.dart';
import '../core/repositories/package_repository.dart';
import '../core/repositories/trip_repository.dart';

class SmartMatchingController extends GetxController {
  final MatchingService _matchingService = MatchingService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final PackageRepository _packageRepository = PackageRepository();
  final TripRepository _tripRepository = TripRepository();

  final RxList<MatchResult> _relevantMatches = <MatchResult>[].obs;
  final RxList<TravelTrip> _suggestedTrips = <TravelTrip>[].obs;
  final RxList<PackageRequest> _suggestedPackages = <PackageRequest>[].obs;
  final RxList<PackageRequest> _userPackages = <PackageRequest>[].obs;
  final RxBool _isLoading = false.obs;

  // Smart filtering properties
  final RxString _selectedTransportMode = ''.obs;
  final RxDouble _maxPriceFilter = 0.0.obs;
  final RxDouble _minMatchPercentage = 50.0.obs;
  final RxBool _verifiedOnlyFilter = false.obs;
  final RxInt _maxDaysFromNow = 30.obs;

  // Route-specific filtering
  final RxBool _routeSpecificFilter = false.obs;
  final RxDouble _maxRouteDistanceKm = 50.0.obs;

  // Location-based filtering
  final RxBool _locationBasedFilter = true.obs; // Default to location-aware
  final RxDouble _proximityRadiusKm = 50.0.obs; // Default 50km radius
  final Rx<Location?> _userLocation = Rx<Location?>(null);
  final RxString _locationMode =
      'current'.obs; // 'current', 'home', 'work', 'custom', 'anywhere'
  final Rx<Location?> _customSearchLocation = Rx<Location?>(null);

  // Original unfiltered data
  final RxList<TravelTrip> _allSuggestedTrips = <TravelTrip>[].obs;

  // Getters
  List<MatchResult> get relevantMatches => _relevantMatches;
  List<TravelTrip> get suggestedTrips => _suggestedTrips;
  List<PackageRequest> get suggestedPackages => _suggestedPackages;
  List<PackageRequest> get userPackages => _userPackages;
  bool get isLoading => _isLoading.value;

  // Filter getters
  String get selectedTransportMode => _selectedTransportMode.value;
  double get maxPriceFilter => _maxPriceFilter.value;
  double get minMatchPercentage => _minMatchPercentage.value;
  bool get verifiedOnlyFilter => _verifiedOnlyFilter.value;
  int get maxDaysFromNow => _maxDaysFromNow.value;
  List<TravelTrip> get allSuggestedTrips => _allSuggestedTrips;

  // Route-specific filter getters
  bool get routeSpecificFilter => _routeSpecificFilter.value;
  double get maxRouteDistanceKm => _maxRouteDistanceKm.value;

  // Location-based filter getters
  bool get locationBasedFilter => _locationBasedFilter.value;
  double get proximityRadiusKm => _proximityRadiusKm.value;
  Location? get userLocation => _userLocation.value;
  String get locationMode => _locationMode.value;
  Location? get customSearchLocation => _customSearchLocation.value;

  String get currentUserId => _authService.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    // Get current location for location-based filtering
    if (_locationBasedFilter.value && _locationMode.value == 'current') {
      getCurrentLocation();
    }
    loadSmartSuggestions();
    loadUserPackages();
  }

  // Load smart suggestions based on user's role and history
  Future<void> loadSmartSuggestions() async {
    if (currentUserId.isEmpty) return;

    _isLoading.value = true;

    try {
      // For now, load some general suggestions
      // In the future, this will be based on user's location, history, etc.

      // Load suggested trips for senders (people looking for travelers)
      await loadSuggestedTrips();

      // Load suggested packages for travelers (people looking for packages to deliver)
      await loadSuggestedPackages();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load suggestions: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Load trips that might interest package senders
  Future<void> loadSuggestedTrips() async {
    try {
      // Get available trips from repository
      final tripStream = _tripRepository.getAvailableTrips(
        excludeTravelerId: currentUserId.isNotEmpty ? currentUserId : null,
        status: TripStatus.active,
      );

      final trips = await tripStream.first;

      // Calculate match percentages for each trip
      final tripsWithMatches = <TravelTrip>[];
      for (final trip in trips.take(20)) {
        // Get more trips for better filtering
        // Calculate match percentage based on user's packages
        trip.matchPercentage = _calculateMatchPercentage(trip);
        tripsWithMatches.add(trip);
      }

      // Store unfiltered data
      _allSuggestedTrips.value = tripsWithMatches;

      // Apply current filters
      _applyFilters();
    } catch (e) {
      print('Error loading suggested trips: $e');
    }
  }

  // Load packages that might interest travelers
  Future<void> loadSuggestedPackages() async {
    try {
      // Get recent packages from repository
      final packageStream = _packageRepository.getRecentPackages(limit: 10);
      final packages = await packageStream.first;

      // Filter out current user's packages
      final filteredPackages =
          packages.where((pkg) => pkg.senderId != currentUserId).toList();

      _suggestedPackages.value = filteredPackages;
    } catch (e) {
      print('Error loading suggested packages: $e');
    }
  }

  // Load current user's packages to show their destinations
  Future<void> loadUserPackages() async {
    if (currentUserId.isEmpty) return;

    try {
      // Get current user's packages from repository
      final packageStream =
          _packageRepository.getPackagesBySender(currentUserId);
      final packages = await packageStream.first;

      _userPackages.value = packages;
    } catch (e) {
      print('Error loading user packages: $e');
    }
  }

  // Find matches for a specific package
  Future<void> findMatchesForPackage(String packageId) async {
    try {
      _isLoading.value = true;

      final matches = await _matchingService.findMatches(
        packageRequestId: packageId,
        maxResults: 5,
      );

      _relevantMatches.value = matches;

      if (matches.isNotEmpty) {
        Get.snackbar(
          'Matches Found!',
          'Found ${matches.length} potential travelers for your package',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to find matches: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Navigate to full matching screen
  void openMatchingScreen() {
    // For now, just show a message
    Get.snackbar(
      'Smart Matching',
      'Advanced matching features coming soon!',
      backgroundColor: Colors.blue.withOpacity(0.8),
      colorText: Colors.white,
    );
  }

  // Get nearby suggestions based on location (simplified)
  Future<void> loadNearbyItems({
    required double latitude,
    required double longitude,
    required String type, // 'packages' or 'trips'
  }) async {
    try {
      if (type == 'packages') {
        await _matchingService.getNearbyPackages(
          latitude: latitude,
          longitude: longitude,
          radiusKm: 20.0,
          limit: 10,
        );
        // Results would be processed here
      } else if (type == 'trips') {
        await _matchingService.getNearbyTrips(
          latitude: latitude,
          longitude: longitude,
          radiusKm: 20.0,
          limit: 10,
        );
        // Results would be processed here
      }
    } catch (e) {
      print('Error loading nearby items: $e');
    }
  }

  // Calculate match percentage between user packages and a trip
  double _calculateMatchPercentage(TravelTrip trip) {
    if (_userPackages.isEmpty) {
      return 50.0; // Base score if no user packages to compare
    }

    double totalScore = 0.0;
    int scoredPackages = 0;

    for (final package in _userPackages) {
      double packageScore = 0.0;

      // 1. Route Match (40% weight)
      double routeScore = _calculateRouteMatch(package, trip);
      packageScore += routeScore * 0.4;

      // 2. Date Match (25% weight)
      double dateScore = _calculateDateMatch(package, trip);
      packageScore += dateScore * 0.25;

      // 3. Capacity Match (20% weight)
      double capacityScore = _calculateCapacityMatch(package, trip);
      packageScore += capacityScore * 0.2;

      // 4. Package Type Match (10% weight)
      double typeScore = _calculateTypeMatch(package, trip);
      packageScore += typeScore * 0.1;

      // 5. Price Match (5% weight)
      double priceScore = _calculatePriceMatch(package, trip);
      packageScore += priceScore * 0.05;

      totalScore += packageScore;
      scoredPackages++;
    }

    return scoredPackages > 0 ? (totalScore / scoredPackages) * 100 : 50.0;
  }

  // Calculate route matching score (0.0 to 1.0)
  double _calculateRouteMatch(PackageRequest package, TravelTrip trip) {
    try {
      // Check if pickup location matches trip departure
      bool pickupMatch = _locationsMatch(
        package.pickupLocation,
        trip.departureLocation,
      );

      // Check if destination matches trip destination
      bool destinationMatch = _locationsMatch(
        package.destinationLocation,
        trip.destinationLocation,
      );

      if (pickupMatch && destinationMatch) return 1.0;
      if (pickupMatch || destinationMatch) return 0.7;

      // Check route stops for partial matches
      if (trip.routeStops.isNotEmpty) {
        for (final stop in trip.routeStops) {
          if (_locationMatchesString(package.pickupLocation, stop) ||
              _locationMatchesString(package.destinationLocation, stop)) {
            return 0.5;
          }
        }
      }

      return 0.2; // Minimum score
    } catch (e) {
      return 0.2;
    }
  }

  // Calculate date matching score (0.0 to 1.0)
  double _calculateDateMatch(PackageRequest package, TravelTrip trip) {
    try {
      final packageDate = package.preferredDeliveryDate;
      final tripDate = trip.departureDate;

      final daysDifference = tripDate.difference(packageDate).inDays.abs();

      if (daysDifference == 0) return 1.0;
      if (daysDifference <= 3) return 0.8;
      if (daysDifference <= 7) return 0.6;
      if (daysDifference <= 14) return 0.4;
      return 0.2;
    } catch (e) {
      return 0.5;
    }
  }

  // Calculate capacity matching score (0.0 to 1.0)
  double _calculateCapacityMatch(PackageRequest package, TravelTrip trip) {
    try {
      final packageWeight = package.packageDetails.weightKg;
      final tripCapacity = trip.capacity.maxWeightKg;

      if (packageWeight <= tripCapacity * 0.1) return 1.0;
      if (packageWeight <= tripCapacity * 0.3) return 0.8;
      if (packageWeight <= tripCapacity * 0.5) return 0.6;
      if (packageWeight <= tripCapacity * 0.8) return 0.4;
      if (packageWeight <= tripCapacity) return 0.2;
      return 0.0; // Package too heavy
    } catch (e) {
      return 0.5;
    }
  }

  // Calculate package type matching score (0.0 to 1.0)
  double _calculateTypeMatch(PackageRequest package, TravelTrip trip) {
    try {
      if (trip.acceptedItemTypes.isEmpty)
        return 0.7; // Neutral if no restrictions

      if (trip.acceptedItemTypes.contains(package.packageDetails.type))
        return 1.0;

      // Check if package type is in accepted categories
      return 0.3; // Partial match
    } catch (e) {
      return 0.5;
    }
  }

  // Calculate price matching score (0.0 to 1.0)
  double _calculatePriceMatch(PackageRequest package, TravelTrip trip) {
    try {
      final packageBudget = package.compensationOffer;
      final tripPrice = trip.suggestedReward;

      if (packageBudget >= tripPrice) return 1.0;
      if (packageBudget >= tripPrice * 0.8) return 0.8;
      if (packageBudget >= tripPrice * 0.6) return 0.6;
      return 0.4;
    } catch (e) {
      return 0.5;
    }
  }

  // Location-based filtering helper methods

  // Get reference location based on current location mode
  Location? _getReferenceLocation() {
    switch (_locationMode.value) {
      case 'current':
        return _userLocation.value;
      case 'custom':
        return _customSearchLocation.value;
      case 'home':
      case 'work':
        // TODO: Get from user profile when implemented
        return _userLocation.value;
      case 'anywhere':
      default:
        return null;
    }
  }

  // Check if trip departure is within proximity radius
  bool _isWithinProximity(TravelTrip trip, Location referenceLocation) {
    try {
      final distance = Geolocator.distanceBetween(
        referenceLocation.latitude,
        referenceLocation.longitude,
        trip.departureLocation.latitude,
        trip.departureLocation.longitude,
      );

      // Convert meters to kilometers
      final distanceKm = distance / 1000;
      return distanceKm <= _proximityRadiusKm.value;
    } catch (e) {
      // If calculation fails, include the trip (don't filter out)
      return true;
    }
  }

  // Get current device location
  Future<void> getCurrentLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final location = Location(
          address:
              '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}',
          latitude: position.latitude,
          longitude: position.longitude,
          city: placemark.locality,
          state: placemark.administrativeArea,
          country: placemark.country,
          postalCode: placemark.postalCode,
        );

        _userLocation.value = location;
        if (_locationMode.value == 'current') {
          _applyFilters(); // Refresh filters with new location
        }
      }
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Failed to get current location: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Helper method to check if two locations match
  bool _locationsMatch(Location loc1, Location loc2) {
    // City match
    if (loc1.city != null && loc2.city != null) {
      if (loc1.city!.toLowerCase() == loc2.city!.toLowerCase()) return true;
    }

    // Country match
    if (loc1.country != null && loc2.country != null) {
      if (loc1.country!.toLowerCase() == loc2.country!.toLowerCase())
        return true;
    }

    return false;
  }

  // Helper method to check if location matches string
  bool _locationMatchesString(Location location, String locationString) {
    final lowerString = locationString.toLowerCase();

    if (location.city != null &&
        location.city!.toLowerCase().contains(lowerString)) return true;

    if (location.country != null &&
        location.country!.toLowerCase().contains(lowerString)) return true;

    return false;
  }

  // Apply intelligent filters to the trip list
  void _applyFilters() {
    // Start with all filters except location
    var filteredTrips = _applyAllFiltersExceptLocation();

    // Apply location-based proximity filtering last
    if (_locationBasedFilter.value && _locationMode.value != 'anywhere') {
      final referenceLocation = _getReferenceLocation();
      if (referenceLocation != null) {
        filteredTrips = filteredTrips
            .where((trip) => _isWithinProximity(trip, referenceLocation))
            .toList();
      }
    }

    // Sort by match percentage (highest first)
    filteredTrips.sort(
        (a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0));

    _suggestedTrips.value = filteredTrips;
  }

  // Helper method to apply all filters except location-based filtering
  List<TravelTrip> _applyAllFiltersExceptLocation() {
    var filteredTrips = List<TravelTrip>.from(_allSuggestedTrips);

    // Filter by transport mode
    if (_selectedTransportMode.value.isNotEmpty) {
      filteredTrips = filteredTrips
          .where((trip) =>
              trip.transportMode.name.toLowerCase() ==
              _selectedTransportMode.value.toLowerCase())
          .toList();
    }

    // Filter by maximum price
    if (_maxPriceFilter.value > 0) {
      filteredTrips = filteredTrips
          .where((trip) => trip.suggestedReward <= _maxPriceFilter.value)
          .toList();
    }

    // Filter by minimum match percentage
    filteredTrips = filteredTrips
        .where(
            (trip) => (trip.matchPercentage ?? 0) >= _minMatchPercentage.value)
        .toList();

    // Filter by verified status
    if (_verifiedOnlyFilter.value) {
      filteredTrips =
          filteredTrips.where((trip) => trip.isVerified == true).toList();
    }

    // Filter by departure date (within specified days from now)
    final maxDate = DateTime.now().add(Duration(days: _maxDaysFromNow.value));
    filteredTrips = filteredTrips
        .where((trip) => trip.departureDate.isBefore(maxDate))
        .toList();

    // Route-specific filtering
    if (_routeSpecificFilter.value && _userPackages.isNotEmpty) {
      filteredTrips =
          filteredTrips.where((trip) => _isRouteRelevant(trip)).toList();
    }

    // Note: We intentionally skip location-based filtering here
    // as this method is used for counting in different location modes

    return filteredTrips;
  }

  // Filter setter methods
  void setTransportModeFilter(String mode) {
    _selectedTransportMode.value = mode;
    _applyFilters();
  }

  void setMaxPriceFilter(double maxPrice) {
    _maxPriceFilter.value = maxPrice;
    _applyFilters();
  }

  void setMinMatchPercentageFilter(double minPercentage) {
    _minMatchPercentage.value = minPercentage;
    _applyFilters();
  }

  void setVerifiedOnlyFilter(bool verifiedOnly) {
    _verifiedOnlyFilter.value = verifiedOnly;
    _applyFilters();
  }

  void setMaxDaysFilter(int maxDays) {
    _maxDaysFromNow.value = maxDays;
    _applyFilters();
  }

  // Route-specific filter setters
  void setRouteSpecificFilter(bool routeSpecific) {
    _routeSpecificFilter.value = routeSpecific;
    _applyFilters();
  }

  void setMaxRouteDistanceFilter(double maxDistanceKm) {
    _maxRouteDistanceKm.value = maxDistanceKm;
    _applyFilters();
  }

  // Location-based filter setters
  void setLocationBasedFilter(bool enabled) {
    _locationBasedFilter.value = enabled;
    if (enabled &&
        _userLocation.value == null &&
        _locationMode.value == 'current') {
      getCurrentLocation(); // Auto-get location when enabled
    }
    _applyFilters();
  }

  void setProximityRadius(double radiusKm) {
    _proximityRadiusKm.value = radiusKm;
    _applyFilters();
  }

  void setLocationMode(String mode) {
    _locationMode.value = mode;
    if (mode == 'current' && _userLocation.value == null) {
      getCurrentLocation();
    }
    _applyFilters();
  }

  void setCustomSearchLocation(Location location) {
    _customSearchLocation.value = location;
    if (_locationMode.value == 'custom') {
      _applyFilters();
    }
  }

  void setUserLocation(Location location) {
    _userLocation.value = location;
    if (_locationMode.value == 'current') {
      _applyFilters();
    }
  }

  // Clear all filters
  void clearAllFilters() {
    _selectedTransportMode.value = '';
    _maxPriceFilter.value = 0.0;
    _minMatchPercentage.value = 50.0;
    _verifiedOnlyFilter.value = false;
    _maxDaysFromNow.value = 30;
    _routeSpecificFilter.value = false;
    _maxRouteDistanceKm.value = 50.0;
    // Keep location settings when clearing other filters
    // _locationBasedFilter.value = true;
    // _proximityRadiusKm.value = 50.0;
    // _locationMode.value = 'current';
    _applyFilters();
  }

  // Get available transport modes for filtering
  List<String> getAvailableTransportModes() {
    // Return predefined common transport modes instead of dynamic extraction
    // This ensures consistent filter options regardless of current trip data
    return ['flight', 'train', 'bus', 'car', 'motorcycle', 'ship'];
  }

  // Get price range for filtering
  Map<String, double> getPriceRange() {
    if (_allSuggestedTrips.isEmpty) return {'min': 0.0, 'max': 100.0};

    final prices =
        _allSuggestedTrips.map((trip) => trip.suggestedReward).toList();
    return {
      'min': prices.reduce((a, b) => a < b ? a : b),
      'max': prices.reduce((a, b) => a > b ? a : b),
    };
  } // Check if a trip's route is relevant to user's packages

  bool _isRouteRelevant(TravelTrip trip) {
    for (final package in _userPackages) {
      // Check if trip route matches or is close to package route
      if (_routeMatches(package, trip)) {
        return true;
      }
    }
    return false;
  }

  // Check if trip route matches package requirements within distance threshold
  bool _routeMatches(PackageRequest package, TravelTrip trip) {
    // Direct route match
    if (_locationsMatch(package.pickupLocation, trip.departureLocation) &&
        _locationsMatch(
            package.destinationLocation, trip.destinationLocation)) {
      return true;
    }

    // Check if trip passes through package pickup or destination
    if (trip.routeStops.isNotEmpty) {
      for (final stop in trip.routeStops) {
        if (_locationMatchesString(package.pickupLocation, stop) ||
            _locationMatchesString(package.destinationLocation, stop)) {
          return true;
        }
      }
    }

    // Check if locations are within acceptable distance (simplified city/country matching)
    if (_isWithinRouteDistance(package, trip)) {
      return true;
    }

    return false;
  }

  // Simplified distance checking based on city/country matching
  bool _isWithinRouteDistance(PackageRequest package, TravelTrip trip) {
    // If same city or country, consider it within range
    final pickupCity = package.pickupLocation.city?.toLowerCase();
    final pickupCountry = package.pickupLocation.country?.toLowerCase();
    final destCity = package.destinationLocation.city?.toLowerCase();
    final destCountry = package.destinationLocation.country?.toLowerCase();

    final tripFromCity = trip.departureLocation.city?.toLowerCase();
    final tripFromCountry = trip.departureLocation.country?.toLowerCase();
    final tripToCity = trip.destinationLocation.city?.toLowerCase();
    final tripToCountry = trip.destinationLocation.country?.toLowerCase();

    // Check if pickup locations are in same city or country
    bool pickupNearby = false;
    if (pickupCity != null && tripFromCity != null) {
      pickupNearby = pickupCity == tripFromCity;
    }
    if (!pickupNearby && pickupCountry != null && tripFromCountry != null) {
      pickupNearby = pickupCountry == tripFromCountry;
    }

    // Check if destination locations are in same city or country
    bool destNearby = false;
    if (destCity != null && tripToCity != null) {
      destNearby = destCity == tripToCity;
    }
    if (!destNearby && destCountry != null && tripToCountry != null) {
      destNearby = destCountry == tripToCountry;
    }

    return pickupNearby || destNearby;
  }

  // Get count of route-specific travelers
  int getRouteSpecificCount() {
    if (!_routeSpecificFilter.value || _userPackages.isEmpty) {
      return _allSuggestedTrips.length;
    }

    return _allSuggestedTrips.where((trip) => _isRouteRelevant(trip)).length;
  }

  // Get count of nearby trips (location-based)
  int getNearbyTripsCount() {
    final referenceLocation = _getReferenceLocation();
    if (referenceLocation == null) {
      return 0; // No location available, so no nearby trips
    }

    // Apply all filters except location-based filter, then apply location filter
    var filteredTrips = _applyAllFiltersExceptLocation();

    return filteredTrips
        .where((trip) => _isWithinProximity(trip, referenceLocation))
        .length;
  }

  // Get total trips count (for "Anywhere" mode)
  int getAllTripsCount() {
    // Apply all filters except location-based filter
    return _applyAllFiltersExceptLocation().length;
  }

  // Get location display text
  String getLocationDisplayText() {
    switch (_locationMode.value) {
      case 'current':
        if (_userLocation.value != null) {
          return _userLocation.value!.city ?? 'Current Location';
        }
        return 'Getting location...';
      case 'custom':
        if (_customSearchLocation.value != null) {
          return _customSearchLocation.value!.city ?? 'Custom Location';
        }
        return 'Select location';
      case 'home':
        return 'Home';
      case 'work':
        return 'Work';
      case 'anywhere':
      default:
        return 'Anywhere';
    }
  }

  // Check if location services are available
  bool get isLocationAvailable => _userLocation.value != null;

  // Get current filter summary for UI
  Map<String, dynamic> getFilterSummary() {
    return {
      'locationMode': _locationMode.value,
      'proximityRadius': _proximityRadiusKm.value,
      'locationBasedFilter': _locationBasedFilter.value,
      'nearbyCount': getNearbyTripsCount(),
      'totalCount': getAllTripsCount(),
      'locationDisplay': getLocationDisplayText(),
    };
  }
}
