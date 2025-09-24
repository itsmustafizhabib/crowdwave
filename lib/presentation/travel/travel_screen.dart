import '../../widgets/liquid_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/smart_matching_controller.dart';
import '../../core/app_export.dart';
import '../../services/auth_state_service.dart';
import '../../widgets/trip_card_widget.dart';
import '../../utils/status_bar_utils.dart';

class TravelScreen extends StatefulWidget {
  const TravelScreen({Key? key}) : super(key: key);

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen>
    with WidgetsBindingObserver {
  late SmartMatchingController matchingController;
  final AuthStateService _authService = AuthStateService();

  bool _showOnlyMyTrips = false;

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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initializeStreams() {
    // Since we're now using SmartMatchingController's filtered results,
    // we just need to ensure the controller has loaded the data
    // The filtering will be applied automatically by the controller
  }

  // Method to force refresh data
  void _forceRefreshStreams() {
    if (mounted) {
      // Refresh the matching controller data
      matchingController.loadSmartSuggestions();
      matchingController.loadUserPackages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9E9E9), // Your light grey
      appBar: AppBar(
        backgroundColor: const Color(0xFF0046FF), // Your electric blue
        elevation: 0,
        systemOverlayStyle: StatusBarUtils.blueHeaderStyle,
        title: Text(
          _showOnlyMyTrips ? 'My Trips' : 'All Travellers',
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
        actions: [
          // Filter toggle button
          IconButton(
            icon: Icon(
              _showOnlyMyTrips ? Icons.person : Icons.public,
              color: Colors.white,
            ),
            tooltip: _showOnlyMyTrips ? 'Show All Trips' : 'Show My Trips',
            onPressed: () {
              setState(() {
                _showOnlyMyTrips = !_showOnlyMyTrips;
                // The filtering will be handled by the GetX controller automatically
              });
            },
          ),

          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list, color: Colors.white),
                GetX<SmartMatchingController>(
                  builder: (controller) {
                    final hasActiveFilters =
                        controller.selectedTransportMode.isNotEmpty ||
                            controller.maxPriceFilter > 0 ||
                            controller.minMatchPercentage > 50.0 ||
                            controller.verifiedOnlyFilter ||
                            controller.maxDaysFromNow < 30 ||
                            controller.routeSpecificFilter;

                    if (!hasActiveFilters) return const SizedBox.shrink();

                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF8040),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            onPressed: () => _showFilterSheet(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Status Indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _showOnlyMyTrips ? Colors.blue[50] : Colors.green[50],
            child: Row(
              children: [
                Icon(
                  _showOnlyMyTrips ? Icons.person : Icons.public,
                  size: 16,
                  color:
                      _showOnlyMyTrips ? Colors.blue[700] : Colors.green[700],
                ),
                const SizedBox(width: 8),
                Text(
                  _showOnlyMyTrips
                      ? 'Showing your trips only'
                      : 'Showing all available trips',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _showOnlyMyTrips ? Colors.blue[700] : Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showOnlyMyTrips = !_showOnlyMyTrips;
                      // The filtering will be handled automatically
                    });
                  },
                  child: Text(
                    _showOnlyMyTrips ? 'Show All' : 'Show Mine',
                    style: TextStyle(
                      fontSize: 12,
                      color: _showOnlyMyTrips
                          ? Colors.blue[700]
                          : Colors.green[700],
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Location Filter Toggle
          GetX<SmartMatchingController>(
            builder: (controller) {
              // Calculate counts based on whether showing all trips or just user's trips
              final currentUserId = _authService.currentUser?.uid ?? '';

              // Use the already filtered trips but exclude location filter for counting
              List<TravelTrip> tripsToCount;
              if (_showOnlyMyTrips) {
                // Get filtered trips excluding location filter, then filter by current user
                tripsToCount = controller.suggestedTrips
                    .where((trip) => trip.travelerId == currentUserId)
                    .toList();
              } else {
                // Get filtered trips excluding location filter, then exclude current user's trips
                tripsToCount = controller.suggestedTrips
                    .where((trip) =>
                        trip.travelerId != currentUserId &&
                        trip.status == TripStatus.active)
                    .toList();
              }

              // For nearby count, we need to apply location filtering manually
              int nearbyCount = 0;
              if (controller.userLocation != null) {
                for (final trip in tripsToCount) {
                  try {
                    final distance = Geolocator.distanceBetween(
                      controller.userLocation!.latitude,
                      controller.userLocation!.longitude,
                      trip.departureLocation.latitude,
                      trip.departureLocation.longitude,
                    );
                    final distanceKm = distance / 1000;
                    if (distanceKm <= controller.proximityRadiusKm) {
                      nearbyCount++;
                    }
                  } catch (e) {
                    // If calculation fails, include the trip in nearby count
                    nearbyCount++;
                  }
                }
              }

              final totalCount = tripsToCount.length;
              final isLocationBased = controller.locationBasedFilter;
              final locationDisplay = controller.getLocationDisplayText();

              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color:
                          isLocationBased ? Colors.blue[700] : Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isLocationBased
                            ? '$locationDisplay (${nearbyCount} trips)'
                            : 'All locations ($totalCount trips)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isLocationBased
                              ? Colors.blue[700]
                              : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _buildLocationToggleChip(
                          '📍 Near Me',
                          nearbyCount,
                          isLocationBased,
                          () => controller.setLocationBasedFilter(true),
                        ),
                        const SizedBox(width: 8),
                        _buildLocationToggleChip(
                          '🌍 Anywhere',
                          totalCount,
                          !isLocationBased,
                          () => controller.setLocationBasedFilter(false),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Active Filters Summary
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

                  if (_showOnlyMyTrips) {
                    // For "My Trips" mode, start with filtered results then filter by current user
                    // This ensures smart filters apply to user's own trips too
                    allTrips = controller.suggestedTrips
                        .where((trip) => trip.travelerId == currentUserId)
                        .toList();
                  } else {
                    // For discovery mode, use the controller's filtered results
                    // which already apply location and other filters
                    allTrips = controller.suggestedTrips
                        .where((trip) =>
                            trip.travelerId != currentUserId &&
                            trip.status == TripStatus.active)
                        .toList();
                  }

                  // Show loading state if controller is loading
                  if (controller.isLoading && allTrips.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0046FF),
                      ),
                    );
                  }

                  if (allTrips.isEmpty) {
                    // Check if there are unfiltered trips to show appropriate message
                    final hasUnfilteredTrips = _showOnlyMyTrips
                        ? controller.allSuggestedTrips
                            .any((trip) => trip.travelerId == currentUserId)
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
                                ? 'No trips match your filters'
                                : (_showOnlyMyTrips
                                    ? 'No trips yet'
                                    : 'No travelers found'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasUnfilteredTrips
                                ? 'Try adjusting your filters or clear them'
                                : (_showOnlyMyTrips
                                    ? 'Post a trip to get started'
                                    : 'Check back later or try different filters'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (hasUnfilteredTrips) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => controller.clearAllFilters(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0046FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Clear All Filters'),
                            ),
                          ],
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
      activeFilters.add('Verified only');
    }
    if (controller.maxDaysFromNow < 30) {
      activeFilters.add('Within ${controller.maxDaysFromNow} days');
    }
    if (controller.routeSpecificFilter) {
      activeFilters.add('Route-specific');
    }
    if (controller.locationBasedFilter) {
      activeFilters.add('Near ${controller.getLocationDisplayText()}');
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
                color: Color(0xFF0046FF),
              ),
              const SizedBox(width: 4),
              Text(
                'Active Filters (${controller.suggestedTrips.length} results):',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0046FF),
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
                child: const Text(
                  'Clear All',
                  style: TextStyle(
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
                        color: const Color(0xFF0046FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF0046FF).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0046FF),
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
                  color: const Color(0xFF0046FF).withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Smart Filters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0046FF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${controller.suggestedTrips.length} results found',
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
                          child: const Text(
                            'Clear All',
                            style: TextStyle(
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
                        title: 'Location Filtering',
                        child: Column(
                          children: [
                            // Location toggle
                            SwitchListTile(
                              title: const Text(
                                'Filter by proximity',
                                style: TextStyle(fontSize: 16),
                              ),
                              subtitle: Text(
                                controller.locationBasedFilter
                                    ? 'Showing trips near ${controller.getLocationDisplayText()}'
                                    : 'Showing trips from all locations',
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
                              activeThumbColor: const Color(0xFF0046FF),
                              contentPadding: EdgeInsets.zero,
                            ),

                            if (controller.locationBasedFilter) ...[
                              const SizedBox(height: 16),

                              // Proximity radius slider
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Search Radius',
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
                                    activeColor: const Color(0xFF0046FF),
                                    onChanged: (value) =>
                                        controller.setProximityRadius(value),
                                  ),
                                  Text(
                                    '${controller.proximityRadiusKm.toInt()} km radius',
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
                                    'Reference Location',
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
                                          ? '📍 Current Location'
                                          : '🌍 Anywhere';

                                      return FilterChip(
                                        label: Text(label),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          if (selected) {
                                            controller.setLocationMode(mode);
                                          }
                                        },
                                        selectedColor: const Color(0xFF0046FF)
                                            .withOpacity(0.2),
                                        checkmarkColor: const Color(0xFF0046FF),
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
                        title: 'Minimum Match Percentage',
                        child: Column(
                          children: [
                            Slider(
                              value: controller.minMatchPercentage,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              activeColor: const Color(0xFF0046FF),
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
                        title: 'Transport Mode',
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
                                  const Color(0xFF0046FF).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF0046FF),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Price Range Filter
                      _buildFilterSection(
                        title: 'Maximum Price',
                        child: Column(
                          children: [
                            Slider(
                              value: controller.maxPriceFilter == 0
                                  ? controller.getPriceRange()['max']!
                                  : controller.maxPriceFilter,
                              min: controller.getPriceRange()['min']!,
                              max: controller.getPriceRange()['max']!,
                              activeColor: const Color(0xFFFF8040),
                              onChanged: (value) =>
                                  controller.setMaxPriceFilter(value),
                            ),
                            Text(
                              controller.maxPriceFilter == 0
                                  ? 'Any price'
                                  : '\$${controller.maxPriceFilter.toStringAsFixed(0)} or less',
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
                        title: 'Departure Within',
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
                              '${controller.maxDaysFromNow} days from now',
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
                        title: 'Traveler Status',
                        child: SwitchListTile(
                          title: const Text(
                            'Verified travelers only',
                            style: TextStyle(fontSize: 16),
                          ),
                          subtitle: const Text(
                            'Show only verified and trusted travelers',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          value: controller.verifiedOnlyFilter,
                          onChanged: (value) =>
                              controller.setVerifiedOnlyFilter(value),
                          activeThumbColor: const Color(0xFF0046FF),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Route-Specific Filter
                      _buildFilterSection(
                        title: 'Route Matching',
                        child: SwitchListTile(
                          title: const Text(
                            'Show route-specific travelers only',
                            style: TextStyle(fontSize: 16),
                          ),
                          subtitle: Text(
                            controller.userPackages.isNotEmpty
                                ? 'Match travelers to your package destinations (${controller.getRouteSpecificCount()} matches)'
                                : 'Add packages to enable route-specific filtering',
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
                            backgroundColor: const Color(0xFF0046FF),
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
                          child: const Text(
                            'Clear All Filters',
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

  // Helper method to build location toggle chips
  Widget _buildLocationToggleChip(
    String label,
    int count,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0046FF) : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0046FF) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.pushNamed(context, AppRoutes.postTrip);
        // Refresh data when returning from post screen (result is the tripId if successful)
        if (result != null && mounted) {
          _forceRefreshStreams();
          // Show confirmation message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Trip posted!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      backgroundColor: Color(0xFF0046FF),
      foregroundColor: Colors.white,
      elevation: 6,
      icon: Icon(Icons.flight_takeoff),
      label: Text(
        'Post Trip',
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
    // Get the standard centerFloat position
    final Offset standardOffset =
        FloatingActionButtonLocation.centerFloat.getOffset(scaffoldGeometry);

    // Adjust the Y position to be higher to avoid the bottom navigation bar
    // Move the FAB up by approximately 100 pixels to clear the bottom navigation bar
    final double adjustedY = standardOffset.dy - 100;

    return Offset(standardOffset.dx, adjustedY);
  }
}
