import '../../widgets/liquid_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import '../../controllers/smart_matching_controller.dart';
import '../../core/app_export.dart';
import '../../services/auth_state_service.dart';
import '../../services/kyc_service.dart';
import '../../widgets/trip_card_widget.dart';
import '../../utils/status_bar_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TravelScreen extends StatefulWidget {
  const TravelScreen({Key? key}) : super(key: key);

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen>
    with WidgetsBindingObserver {
  late SmartMatchingController matchingController;
  final AuthStateService _authService = AuthStateService();
  final TripRepository _tripRepository = TripRepository();
  final KycService _kycService = KycService();

  bool _showOnlyMyTrips = false;
  bool _showLocalTripsOnly =
      false; // false = abroad/international, true = local/domestic

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // KYC status tracking
  bool _hasSubmittedKyc = false;
  String? _kycStatus; // null, 'submitted', 'pending', 'approved', 'rejected'
  bool _kycCheckComplete = false; // Track if initial KYC check is done

  // Real-time stream for trips
  Stream<List<TravelTrip>>? _tripsStream;
  StreamSubscription<List<TravelTrip>>? _streamSubscription;

  // Local state to hold stream data (for My Trips mode)
  List<TravelTrip> _streamTrips = [];

  @override
  void initState() {
    super.initState();

    // Add app lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Try to get existing controller, or create new one if not found
    try {
      matchingController = Get.find<SmartMatchingController>();
    } catch (e) {
      matchingController = Get.put(SmartMatchingController());
    }

    // Initialize real-time streams and load data
    _initializeStreams();
    // Load data into the controller to ensure we have trips to filter
    matchingController.loadSmartSuggestions();
    // Check KYC status on initialization
    _checkKycStatus();
  }

  Future<void> _checkKycStatus() async {
    // Use FirebaseAuth directly for more reliable user access
    final currentUser = FirebaseAuth.instance.currentUser;

    print('🔍 Checking KYC Status...');
    print('   Current User ID: ${currentUser?.uid ?? "NULL"}');

    if (currentUser == null) {
      print('❌ No authenticated user found');
      setState(() {
        _hasSubmittedKyc = false;
        _kycStatus = null;
        _kycCheckComplete = true;
      });
      return;
    }

    try {
      // Get the actual KYC status
      final status = await _kycService.getKycStatus(currentUser.uid);
      final hasSubmitted = await _kycService.hasSubmittedKyc(currentUser.uid);

      setState(() {
        _kycStatus = status;
        _hasSubmittedKyc = hasSubmitted;
        _kycCheckComplete = true;
      });

      print('🔍 Travel Screen KYC Check Results:');
      print('   Status from getKycStatus: $_kycStatus');
      print('   HasSubmitted from hasSubmittedKyc: $hasSubmitted');
      print('   Is Approved? ${_kycStatus == 'approved'}');
    } catch (e) {
      print('❌ Error checking KYC status: $e');
      setState(() {
        _hasSubmittedKyc = false;
        _kycStatus = null;
        _kycCheckComplete = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _forceRefreshStreams();
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initializeStreams() {
    // Cancel existing subscription to avoid duplicates
    _streamSubscription?.cancel();

    if (_showOnlyMyTrips) {
      // For "My Trips", get trips for current user
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId != null) {
        _tripsStream = _tripRepository.getTripsByTraveler(currentUserId);
      }
    } else {
      // For "All Trips", load all trips
      _tripsStream = _tripRepository.getRecentTrips(limit: 50);
    }

    // Listen to stream changes and update controller
    _streamSubscription = _tripsStream?.listen((trips) {
      if (mounted) {
        print(
            '🔄 Stream received ${trips.length} trips (My Trips mode: $_showOnlyMyTrips)');
        // Store trips in local state for My Trips mode
        _streamTrips = trips;
        // Trigger controller refresh when data changes (for All Trips mode)
        matchingController.loadSmartSuggestions();
        // Force UI rebuild
        setState(() {});
      }
    });
  }

  // Method to force refresh data
  void _forceRefreshStreams() {
    if (mounted) {
      print('🔄 Force refreshing streams (My Trips: $_showOnlyMyTrips)');
      setState(() {
        _initializeStreams();
      });
      // Refresh the matching controller data
      matchingController.loadSmartSuggestions();
      matchingController.loadUserPackages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFE9E9E9), // Your light grey
      appBar: AppBar(
        backgroundColor: const Color(0xFF215C5C), // Your electric blue
        elevation: 0,
        systemOverlayStyle: StatusBarUtils.blueHeaderStyle,
        title: Text(
          'travel.all_travellers'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar + Local/Abroad Buttons Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'travel.search_trips'.tr(),
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            onChanged: (value) {
                              setState(() {
                                // Trigger rebuild to apply search filter
                              });
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear,
                                color: Colors.grey[400], size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        const SizedBox(width: 8),
                        GetX<SmartMatchingController>(
                          builder: (controller) {
                            final hasActiveFilters =
                                controller.selectedTransportMode.isNotEmpty ||
                                    controller.maxPriceFilter > 0 ||
                                    controller.minMatchPercentage > 50.0 ||
                                    controller.verifiedOnlyFilter ||
                                    controller.maxDaysFromNow < 30 ||
                                    controller.routeSpecificFilter;

                            return InkWell(
                              onTap: () => _showFilterSheet(),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Stack(
                                  children: [
                                    Icon(
                                      Icons.tune,
                                      color: hasActiveFilters
                                          ? const Color(0xFF215C5C)
                                          : Colors.grey[600],
                                      size: 24,
                                    ),
                                    if (hasActiveFilters)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF2D7A6E),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Local Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _showLocalTripsOnly = true;
                    });
                  },
                  child: Container(
                    width: 90,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _showLocalTripsOnly
                          ? Colors.white
                          : const Color(0xFFE9E9E9),
                      borderRadius: BorderRadius.circular(8),
                      border: _showLocalTripsOnly
                          ? Border.all(color: const Color(0xFF215C5C), width: 2)
                          : null,
                      boxShadow: _showLocalTripsOnly
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_city,
                          size: 24,
                          color: _showLocalTripsOnly
                              ? const Color(0xFF215C5C)
                              : Colors.grey[600],
                        ),
                        const SizedBox(height: 4),
                        Text('common.local'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _showLocalTripsOnly
                                ? const Color(0xFF215C5C)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Abroad Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _showLocalTripsOnly = false;
                    });
                  },
                  child: Container(
                    width: 90,
                    height: 56,
                    decoration: BoxDecoration(
                      color: !_showLocalTripsOnly
                          ? Colors.white
                          : const Color(0xFFE9E9E9),
                      borderRadius: BorderRadius.circular(8),
                      border: !_showLocalTripsOnly
                          ? Border.all(color: const Color(0xFF215C5C), width: 2)
                          : null,
                      boxShadow: !_showLocalTripsOnly
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.public,
                          size: 24,
                          color: !_showLocalTripsOnly
                              ? const Color(0xFF215C5C)
                              : Colors.grey[600],
                        ),
                        const SizedBox(height: 4),
                        Text('common.abroad'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: !_showLocalTripsOnly
                                ? const Color(0xFF215C5C)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Filters Summary (Only show in "All Trips" mode)
          if (!_showOnlyMyTrips)
            GetX<SmartMatchingController>(
              builder: (controller) {
                return _buildActiveFiltersSummary(controller);
              },
            ),

          // Travellers List - Using SmartMatchingController filtered results
          Expanded(
            child: LiquidRefreshIndicator(
              onRefresh: () async {
                _forceRefreshStreams();
                matchingController.loadSmartSuggestions();
                await Future.delayed(Duration(
                    milliseconds: 500)); // Small delay for user feedback
              },
              child: GetX<SmartMatchingController>(
                builder: (controller) {
                  List<TravelTrip> allTrips;
                  final currentUserId = _authService.currentUser?.uid ?? '';
                  final searchText =
                      _searchController.text.toLowerCase().trim();

                  if (_showOnlyMyTrips) {
                    // For "My Trips" mode, use the stream data directly
                    // This ensures we see ALL user trips from the getTripsByTraveler stream
                    allTrips = _streamTrips;

                    print(
                        '📊 My Trips Display: Showing ${allTrips.length} trips from stream');
                  } else {
                    // For discovery mode, use the controller's filtered results
                    // which already apply location and other filters
                    allTrips = controller.suggestedTrips
                        .where((trip) =>
                            trip.travelerId != currentUserId &&
                            trip.status == TripStatus.active)
                        .toList();

                    // Apply Local/Abroad filtering
                    allTrips = allTrips.where((trip) {
                      final departureCountry =
                          trip.departureLocation.country?.toLowerCase().trim();
                      final destinationCountry = trip
                          .destinationLocation.country
                          ?.toLowerCase()
                          .trim();

                      // Check if both countries are available
                      if (departureCountry == null ||
                          destinationCountry == null) {
                        // If country info is missing, show in "Abroad" by default
                        return !_showLocalTripsOnly;
                      }

                      final isDomestic = departureCountry == destinationCountry;

                      return _showLocalTripsOnly ? isDomestic : !isDomestic;
                    }).toList();

                    print(
                        '📊 All Trips Display: Found ${allTrips.length} ${_showLocalTripsOnly ? "domestic" : "international"} trips (excluding current user)');
                  }

                  // Apply search filter if search text is provided
                  if (searchText.isNotEmpty) {
                    allTrips = allTrips.where((trip) {
                      final fromLocation =
                          trip.departureLocation.address.toLowerCase();
                      final toLocation =
                          trip.destinationLocation.address.toLowerCase();
                      final travelerName = trip.travelerName.toLowerCase();
                      final departureCity =
                          (trip.departureLocation.city ?? '').toLowerCase();
                      final destinationCity =
                          (trip.destinationLocation.city ?? '').toLowerCase();
                      final departureCountry =
                          (trip.departureLocation.country ?? '').toLowerCase();
                      final destinationCountry =
                          (trip.destinationLocation.country ?? '')
                              .toLowerCase();

                      return fromLocation.contains(searchText) ||
                          toLocation.contains(searchText) ||
                          travelerName.contains(searchText) ||
                          departureCity.contains(searchText) ||
                          destinationCity.contains(searchText) ||
                          departureCountry.contains(searchText) ||
                          destinationCountry.contains(searchText);
                    }).toList();
                  }

                  // Show loading state if controller is loading
                  if (controller.isLoading && allTrips.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF215C5C),
                      ),
                    );
                  }

                  if (allTrips.isEmpty) {
                    // Check if there are unfiltered trips to show appropriate message
                    final hasUnfilteredTrips = _showOnlyMyTrips
                        ? _streamTrips
                            .isNotEmpty // For My Trips, check stream data
                        : controller.allSuggestedTrips.any((trip) =>
                            trip.travelerId != currentUserId &&
                            trip.status == TripStatus.active);

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasUnfilteredTrips
                                ? Icons.filter_alt_outlined
                                : Icons.flight_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            hasUnfilteredTrips
                                ? 'travel.no_trips_match_filters'.tr()
                                : (_showOnlyMyTrips
                                    ? 'home.no_trips_yet'.tr()
                                    : 'travel.no_travelers_found'.tr()),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasUnfilteredTrips
                                ? 'travel.try_adjusting_filters'.tr()
                                : (_showOnlyMyTrips
                                    ? 'home.post_trip_to_start'.tr()
                                    : 'travel.check_back_later_or_filters'
                                        .tr()),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(context).viewPadding.bottom + 100,
                    ),
                    itemCount: allTrips.length,
                    itemBuilder: (context, index) {
                      final trip = allTrips[index];
                      return TripCardWidget(
                        trip: trip,
                        index: index,
                        showActions: true,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: _CustomFloatingActionButtonLocation(),
    );
  }

  // Build active filters summary
  Widget _buildActiveFiltersSummary(SmartMatchingController controller) {
    final activeFilters = <String>[];

    if (controller.selectedTransportMode.isNotEmpty) {
      activeFilters.add(
          controller.selectedTransportMode.substring(0, 1).toUpperCase() +
              controller.selectedTransportMode.substring(1));
    }
    if (controller.maxPriceFilter > 0) {
      activeFilters.add('Max \$${controller.maxPriceFilter.toInt()}');
    }
    if (controller.minMatchPercentage > 50) {
      activeFilters.add('≥${controller.minMatchPercentage.toInt()}% match');
    }
    if (controller.verifiedOnlyFilter) {
      activeFilters.add('travel.verified_only_short'.tr());
    }
    if (controller.maxDaysFromNow < 30) {
      activeFilters.add(
          '${'travel.within'.tr()} ${controller.maxDaysFromNow} ${'travel.days'.tr()}');
    }
    if (controller.routeSpecificFilter) {
      activeFilters.add('travel.route_specific'.tr());
    }
    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_alt,
                size: 16,
                color: Color(0xFF215C5C),
              ),
              const SizedBox(width: 4),
              Text(
                '${'travel.active_filters'.tr()} (${controller.suggestedTrips.length} ${'travel.results'.tr()}):',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF215C5C),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => controller.clearAllFilters(),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'travel.clear_all'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: activeFilters
                .map((filter) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF215C5C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF215C5C).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF215C5C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Show intelligent filter sheet
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: GetX<SmartMatchingController>(
          builder: (controller) => Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF215C5C).withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'travel.smart_filters'.tr(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF215C5C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${controller.suggestedTrips.length} ${'travel.results_found'.tr()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => controller.clearAllFilters(),
                          child: Text(
                            'travel.clear_all'.tr(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter Options
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    20 + MediaQuery.of(context).viewPadding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location-Based Filter
                      _buildFilterSection(
                        title: 'travel.location_filtering'.tr(),
                        child: Column(
                          children: [
                            // Location toggle
                            SwitchListTile(
                              title: Text(
                                'travel.filter_by_proximity'.tr(),
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: Text(
                                controller.locationBasedFilter
                                    ? '${'travel.showing_trips_near'.tr()} ${controller.getLocationDisplayText()}'
                                    : 'travel.showing_trips_all_locations'.tr(),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              value: controller.locationBasedFilter,
                              onChanged: (value) {
                                controller.setLocationBasedFilter(value);
                                if (value && !controller.isLocationAvailable) {
                                  controller.getCurrentLocation();
                                }
                              },
                              activeThumbColor: const Color(0xFF215C5C),
                              contentPadding: EdgeInsets.zero,
                            ),

                            if (controller.locationBasedFilter) ...[
                              const SizedBox(height: 16),

                              // Proximity radius slider
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'travel.search_radius'.tr(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Slider(
                                    value: controller.proximityRadiusKm,
                                    min: 5,
                                    max: 500,
                                    divisions: 99,
                                    activeColor: const Color(0xFF215C5C),
                                    onChanged: (value) =>
                                        controller.setProximityRadius(value),
                                  ),
                                  Text(
                                    '${controller.proximityRadiusKm.toInt()} ${'travel.km_radius'.tr()}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Location mode selector
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'travel.reference_location'.tr(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      'current',
                                      'anywhere',
                                    ].map((mode) {
                                      final isSelected =
                                          controller.locationMode == mode;
                                      final label = mode == 'current'
                                          ? 'travel.current_location'.tr()
                                          : 'travel.anywhere'.tr();

                                      return FilterChip(
                                        label: Text(label),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          if (selected) {
                                            controller.setLocationMode(mode);
                                          }
                                        },
                                        selectedColor: const Color(0xFF215C5C)
                                            .withOpacity(0.2),
                                        checkmarkColor: const Color(0xFF215C5C),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Match Percentage Filter
                      _buildFilterSection(
                        title: 'travel.minimum_match_percentage'.tr(),
                        child: Column(
                          children: [
                            Slider(
                              value: controller.minMatchPercentage,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              activeColor: const Color(0xFF215C5C),
                              onChanged: (value) =>
                                  controller.setMinMatchPercentageFilter(value),
                            ),
                            Text(
                              '${controller.minMatchPercentage.toInt()}% or higher',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Transport Mode Filter
                      _buildFilterSection(
                        title: 'travel.transport_mode'.tr(),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'All',
                            ...controller.getAvailableTransportModes()
                          ].map((mode) {
                            final isSelected = mode == 'All'
                                ? controller.selectedTransportMode.isEmpty
                                : controller.selectedTransportMode == mode;
                            return FilterChip(
                              label: Text(
                                mode.substring(0, 1).toUpperCase() +
                                    mode.substring(1),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                controller.setTransportModeFilter(
                                    mode == 'All' ? '' : mode);
                              },
                              selectedColor:
                                  const Color(0xFF215C5C).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF215C5C),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Price Range Filter
                      _buildFilterSection(
                        title: 'travel.maximum_price'.tr(),
                        child: Column(
                          children: [
                            Slider(
                              value: controller.maxPriceFilter == 0
                                  ? controller.getPriceRange()['max']!
                                  : controller.maxPriceFilter,
                              min: controller.getPriceRange()['min']!,
                              max: controller.getPriceRange()['max']!,
                              activeColor: const Color(0xFF2D7A6E),
                              onChanged: (value) =>
                                  controller.setMaxPriceFilter(value),
                            ),
                            Text(
                              controller.maxPriceFilter == 0
                                  ? 'travel.any_price'.tr()
                                  : '€${controller.maxPriceFilter.toStringAsFixed(0)} or less',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Days from now filter
                      _buildFilterSection(
                        title: 'travel.departure_within'.tr(),
                        child: Column(
                          children: [
                            Slider(
                              value: controller.maxDaysFromNow.toDouble(),
                              min: 1,
                              max: 90,
                              divisions: 89,
                              activeColor: Colors.green,
                              onChanged: (value) =>
                                  controller.setMaxDaysFilter(value.toInt()),
                            ),
                            Text(
                              '${controller.maxDaysFromNow} ${'travel.days'.tr()} from now',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Verified Only Filter
                      _buildFilterSection(
                        title: 'travel.traveler_status'.tr(),
                        child: SwitchListTile(
                          title: Text(
                            'travel.verified_only'.tr(),
                            style: const TextStyle(fontSize: 16),
                          ),
                          subtitle: Text(
                            'travel.all_travelers'.tr(),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          value: controller.verifiedOnlyFilter,
                          onChanged: (value) =>
                              controller.setVerifiedOnlyFilter(value),
                          activeThumbColor: const Color(0xFF215C5C),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Route-Specific Filter
                      _buildFilterSection(
                        title: 'travel.route_matching'.tr(),
                        child: SwitchListTile(
                          title: Text(
                            'travel.route_specific'.tr(),
                            style: const TextStyle(fontSize: 16),
                          ),
                          subtitle: Text(
                            controller.userPackages.isNotEmpty
                                ? '${'travel.match'.tr()} (${controller.getRouteSpecificCount()})'
                                : 'travel.all_routes'.tr(),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          value: controller.routeSpecificFilter &&
                              controller.userPackages.isNotEmpty,
                          onChanged: controller.userPackages.isEmpty
                              ? null
                              : (value) =>
                                  controller.setRouteSpecificFilter(value),
                          activeThumbColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Apply Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF215C5C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Apply Filters (${controller.suggestedTrips.length} results)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Reset to defaults button
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            controller.clearAllFilters();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('travel.clear_all_filters'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build filter sections
  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () async {
        // Check KYC status before allowing user to post a trip
        final currentUser = _authService.currentUser;
        if (currentUser == null) {
          // User not logged in, shouldn't happen but handle it
          return;
        }

        // Wait for initial KYC check to complete
        if (!_kycCheckComplete) {
          print('⏳ Waiting for initial KYC check to complete...');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('travel.checking_verification'.tr()),
                ],
              ),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF215C5C),
            ),
          );

          // Wait for the check to complete
          await Future.delayed(Duration(milliseconds: 1500));

          // Check again after delay
          if (!_kycCheckComplete) {
            print('❌ KYC check still not complete after delay');
            // Force refresh the KYC status
            await _checkKycStatus();
          }
        }

        // Debug: Log current state before checking
        print('🎯 POST TRIP BUTTON PRESSED - Current State:');
        print('   _kycCheckComplete: $_kycCheckComplete');
        print('   _kycStatus: $_kycStatus');
        print('   _hasSubmittedKyc: $_hasSubmittedKyc');

        // Check if KYC is approved (not just submitted)
        bool isKycApproved = _kycStatus == 'approved';
        print('   isKycApproved: $isKycApproved');

        if (!isKycApproved) {
          print('❌ KYC not approved, showing dialog');
          // Show friendly dialog prompting user to complete KYC
          final shouldNavigateToKyc = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF2D7A6E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.verified_user,
                        color: Color(0xFF2D7A6E),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'home.kyc_verification_required'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  _kycStatus == 'submitted' || _kycStatus == 'pending'
                      ? 'home.kyc_pending_message'.tr()
                      : _kycStatus == 'rejected'
                          ? 'home.kyc_rejected_message'.tr()
                          : 'travel.kyc_required_trip'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      _kycStatus == 'submitted' || _kycStatus == 'pending'
                          ? 'common.ok'.tr()
                          : 'home.later'.tr(),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (_kycStatus == null || _kycStatus == 'rejected')
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF215C5C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        _kycStatus == 'rejected'
                            ? 'home.resubmit_kyc'.tr()
                            : 'home.complete_kyc'.tr(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              );
            },
          );

          if (shouldNavigateToKyc == true) {
            // Navigate to KYC screen
            await Navigator.pushNamed(context, AppRoutes.kycCompletion);

            // Refresh KYC status after returning from KYC screen
            if (mounted) {
              print(
                  '🔄 Refreshing KYC status after returning from KYC screen...');
              await _checkKycStatus();

              // If KYC is now approved, allow posting trip
              if (_kycStatus == 'approved') {
                print('✅ KYC is now approved, proceeding to post trip...');
                // Don't return, continue to post trip
              } else {
                print('❌ KYC still not approved: $_kycStatus');
                return;
              }
            } else {
              return;
            }
          } else {
            return;
          }
        }

        // Re-check KYC status one more time before proceeding
        if (_kycStatus != 'approved') {
          print('⚠️ Final KYC check failed: $_kycStatus');
          return;
        }

        // User has completed KYC, proceed to post trip
        final result = await Navigator.pushNamed(context, AppRoutes.postTrip);
        // Refresh data when returning from post screen (result is the tripId if successful)
        if (result != null && mounted) {
          print('✅ Trip posted, refreshing streams...');
          _forceRefreshStreams();
          // Show confirmation message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('travel.trip_posted'.tr()),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      backgroundColor: Color(0xFF215C5C),
      foregroundColor: Colors.white,
      elevation: 6,
      label: Text(
        'travel.post_trip'.tr(),
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Calculate X position (centered)
    final double fabX = (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2;

    // Fixed Y position from bottom (not affected by keyboard)
    // Use scaffoldGeometry.contentBottom which represents the bottom of the content area
    final double fabY = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        115;

    return Offset(fabX, fabY);
  }
}
