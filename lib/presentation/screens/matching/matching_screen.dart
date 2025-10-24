import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../controllers/matching_controller.dart';
import '../../../core/models/models.dart';
import '../../../widgets/liquid_loading_indicator.dart';

class MatchingScreen extends StatelessWidget {
  final String? packageId;
  final String? travelerId;
  final PackageRequest? packageRequest;

  const MatchingScreen({
    Key? key,
    this.packageId,
    this.travelerId,
    this.packageRequest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MatchingController controller = Get.put(MatchingController());

    return Scaffold(
      appBar: AppBar(
        title: Text('matching.title'.tr()),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, controller),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _refreshMatches(controller),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            // Auto-matching toggle
            _buildAutoMatchToggle(controller),

            // Tab bar
            TabBar(
              tabs: [
                Tab(
                    text: 'matching.auto_matches_tab'.tr(),
                    icon: Icon(Icons.auto_awesome)),
                Tab(
                    text: 'matching.browse_trips_tab'.tr(),
                    icon: Icon(Icons.explore)),
                Tab(
                    text: 'matching.nearby_packages_tab'.tr(),
                    icon: Icon(Icons.location_on)),
                Tab(
                    text: 'matching.nearby_trips_tab'.tr(),
                    icon: Icon(Icons.directions_car)),
              ],
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  _buildAutoMatchesTab(controller),
                  _buildManualMatchingTab(controller),
                  _buildNearbyPackagesTab(controller),
                  _buildNearbyTripsTab(controller),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNearbySearchDialog(context, controller),
        child: Icon(Icons.near_me),
        tooltip: 'matching.find_nearby'.tr(),
      ),
    );
  }

  Widget _buildAutoMatchToggle(MatchingController controller) {
    return Obx(() => Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'matching.auto_matching'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: controller.isAutoMatchingEnabled,
                onChanged: controller.toggleAutoMatching,
                activeThumbColor: Theme.of(Get.context!).primaryColor,
              ),
            ],
          ),
        ));
  }

  Widget _buildAutoMatchesTab(MatchingController controller) {
    return Obx(() {
      if (controller.isLoading) {
        return const CenteredLiquidLoading();
      }

      if (controller.matches.isEmpty) {
        return _buildEmptyState(
          'matching.no_auto_matches_title'.tr(),
          'matching.no_auto_matches_desc'.tr(),
          Icons.auto_awesome_motion,
          () => _triggerAutoMatch(controller),
          'matching.find_matches'.tr(),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(2.w),
        itemCount: controller.matches.length,
        itemBuilder: (context, index) {
          final match = controller.matches[index];
          return _buildMatchCard(match, controller);
        },
      );
    });
  }

  Widget _buildManualMatchingTab(MatchingController controller) {
    return Obx(() {
      if (controller.isLoading) {
        return const CenteredLiquidLoading();
      }

      if (controller.potentialTrips.isEmpty) {
        return _buildEmptyState(
          'matching.no_trips_title'.tr(),
          'matching.no_trips_desc'.tr(),
          Icons.explore_off,
          () => _loadPotentialTrips(controller),
          'matching.search_trips'.tr(),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(2.w),
        itemCount: controller.potentialTrips.length,
        itemBuilder: (context, index) {
          final trip = controller.potentialTrips[index];
          return _buildTripCard(trip, controller);
        },
      );
    });
  }

  Widget _buildNearbyPackagesTab(MatchingController controller) {
    return Obx(() {
      if (controller.isLoading) {
        return const CenteredLiquidLoading();
      }

      if (controller.nearbyPackages.isEmpty) {
        return _buildEmptyState(
          'matching.no_nearby_packages_title'.tr(),
          'matching.no_nearby_packages_desc'.tr(),
          Icons.location_off,
          () => _loadNearbyPackages(controller),
          'matching.find_nearby'.tr(),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(2.w),
        itemCount: controller.nearbyPackages.length,
        itemBuilder: (context, index) {
          final suggestion = controller.nearbyPackages[index];
          return _buildSuggestionCard(suggestion);
        },
      );
    });
  }

  Widget _buildNearbyTripsTab(MatchingController controller) {
    return Obx(() {
      if (controller.isLoading) {
        return const CenteredLiquidLoading();
      }

      if (controller.nearbyTrips.isEmpty) {
        return _buildEmptyState(
          'matching.no_nearby_trips_title'.tr(),
          'matching.no_nearby_trips_desc'.tr(),
          Icons.location_off,
          () => _loadNearbyTrips(controller),
          'matching.find_nearby'.tr(),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(2.w),
        itemCount: controller.nearbyTrips.length,
        itemBuilder: (context, index) {
          final suggestion = controller.nearbyTrips[index];
          return _buildSuggestionCard(suggestion);
        },
      );
    });
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onAction,
    String actionText,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(60.w, 48),
                backgroundColor: Theme.of(Get.context!).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(MatchResult match, MatchingController controller) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match score and type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getScoreColor(match.matchScore),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${match.matchScore.toInt()}% Match',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    match.matchingType.name.toUpperCase(),
                    style: TextStyle(fontSize: 10.sp),
                  ),
                  backgroundColor: match.matchingType == MatchingType.auto
                      ? Color(0xFF008080)
                      : Colors.orange.shade100,
                ),
              ],
            ),

            SizedBox(height: 1.h),

            // Trip details
            Text(
              'Trip ID: ${match.tripId}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 0.5.h),

            // Traveler info
            Text(
              'Traveler: ${match.travelerId}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),

            SizedBox(height: 1.h),

            // Match factors
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: _buildMatchFactorChips(match.matchingFactors),
            ),

            SizedBox(height: 2.h),

            // Action buttons
            if (match.status == MatchStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _showAcceptMatchDialog(match, controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('matching.accept'.tr()),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _showRejectMatchDialog(match, controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('matching.reject'.tr()),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: _getStatusColor(match.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Status: ${match.status.name.toUpperCase()}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(TravelTrip trip, MatchingController controller) {
    final availableSpace =
        trip.capacity.maxPackages - trip.acceptedPackageIds.length;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip header
            Row(
              children: [
                Icon(
                  _getTransportIcon(trip.transportMode),
                  size: 6.w,
                  color: Theme.of(Get.context!).primaryColor,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trip.departureLocation.city ?? "Unknown"} → ${trip.destinationLocation.city ?? "Unknown"}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        trip.travelerName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 1.h),

            // Trip details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  '${trip.departureDate.day}/${trip.departureDate.month}',
                  Icons.calendar_today,
                ),
                _buildInfoChip(
                  '$availableSpace spaces',
                  Icons.inventory,
                ),
                _buildInfoChip(
                  '€${trip.suggestedReward}',
                  Icons.attach_money,
                ),
              ],
            ),

            SizedBox(height: 1.h),

            // Package capacity info
            Text(
              'Max Weight: ${trip.capacity.maxWeightKg}kg • Max Volume: ${trip.capacity.maxVolumeLiters}L',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
              ),
            ),

            SizedBox(height: 2.h),

            // Action button
            ElevatedButton(
              onPressed: () => _contactTraveler(trip),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                backgroundColor: Theme.of(Get.context!).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('matching.contact_traveler'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(NearbySuggestion suggestion) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: suggestion.type == 'package'
              ? Color(0xFF008080)
              : Colors.green.shade100,
          child: Icon(
            suggestion.type == 'package'
                ? Icons.inventory
                : Icons.directions_car,
            color:
                suggestion.type == 'package' ? Color(0xFF008080) : Colors.green,
          ),
        ),
        title: Text(
          suggestion.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(suggestion.description),
            SizedBox(height: 0.5.h),
            Text(
              '${suggestion.distance.toStringAsFixed(1)} km away',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () => _viewSuggestionDetails(suggestion),
      ),
    );
  }

  List<Widget> _buildMatchFactorChips(Map<String, dynamic> factors) {
    final chips = <Widget>[];

    if (factors['averageDistance'] != null) {
      chips.add(Chip(
        label: Text('${factors['averageDistance'].toStringAsFixed(1)}km'),
        avatar: Icon(Icons.location_on, size: 4.w),
        backgroundColor: Color(0xFF008080),
      ));
    }

    if (factors['travelerRating'] != null) {
      chips.add(Chip(
        label: Text('⭐ ${factors['travelerRating'].toStringAsFixed(1)}'),
        backgroundColor: Colors.orange.shade100,
      ));
    }

    if (factors['transportMode'] != null) {
      chips.add(Chip(
        label: Text(factors['transportMode']),
        backgroundColor: Colors.green.shade100,
      ));
    }

    return chips;
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.w, color: Colors.grey.shade600),
          SizedBox(width: 1.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.accepted:
        return Colors.green;
      case MatchStatus.rejected:
        return Colors.red;
      case MatchStatus.expired:
        return Colors.grey;
      case MatchStatus.cancelled:
        return Colors.orange;
      default:
        return Color(0xFF008080);
    }
  }

  IconData _getTransportIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.flight:
        return Icons.flight;
      case TransportMode.train:
        return Icons.train;
      case TransportMode.bus:
        return Icons.directions_bus;
      case TransportMode.car:
        return Icons.directions_car;
      case TransportMode.motorcycle:
        return Icons.motorcycle;
      case TransportMode.bicycle:
        return Icons.pedal_bike;
      case TransportMode.walking:
        return Icons.directions_walk;
      case TransportMode.ship:
        return Icons.directions_boat;
    }
  }

  // Action methods
  void _refreshMatches(MatchingController controller) {
    if (packageId != null) {
      controller.findAutoMatches(packageId!);
    }
    if (packageRequest != null) {
      controller.findPotentialTrips(packageRequest!);
    }
  }

  void _triggerAutoMatch(MatchingController controller) {
    if (packageId != null) {
      controller.findAutoMatches(packageId!);
    } else {
      Get.snackbar('error.title'.tr(), 'matching.no_package_selected'.tr());
    }
  }

  void _loadPotentialTrips(MatchingController controller) {
    if (packageRequest != null) {
      controller.findPotentialTrips(packageRequest!);
    } else {
      Get.snackbar('error.title'.tr(), 'matching.no_package_request'.tr());
    }
  }

  void _loadNearbyPackages(MatchingController controller) {
    // For demo purposes, using fixed coordinates
    // In production, get user's actual location
    controller.loadNearbyPackages(
      latitude: 37.7749,
      longitude: -122.4194,
    );
  }

  void _loadNearbyTrips(MatchingController controller) {
    // For demo purposes, using fixed coordinates
    // In production, get user's actual location
    controller.loadNearbyTrips(
      latitude: 37.7749,
      longitude: -122.4194,
    );
  }

  void _contactTraveler(TravelTrip trip) {
    // Navigate to chat or contact screen
    Get.snackbar('contact.title'.tr(), 'contact.opening_chat'.tr(args: [trip.travelerName]));
  }

  void _viewSuggestionDetails(NearbySuggestion suggestion) {
    // Navigate to detailed view
    Get.snackbar('details.title'.tr(), 'details.viewing'.tr(args: [suggestion.title]));
  }

  // Dialog methods
  void _showFilterDialog(BuildContext context, MatchingController controller) {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(controller: controller),
    );
  }

  void _showAcceptMatchDialog(
      MatchResult match, MatchingController controller) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text('matching.accept_match'.tr()),
        content: Text('common.do_you_want_to_accept_this_match_you_can_negotiate'.tr()),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.acceptMatch(match.id);
            },
            child: Text('matching.accept'.tr()),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _showPriceNegotiationDialog(match, controller);
            },
            child: Text('matching.negotiate_price'.tr()),
          ),
        ],
      ),
    );
  }

  void _showRejectMatchDialog(
      MatchResult match, MatchingController controller) {
    final reasonController = TextEditingController();

    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text('matching.reject_match'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('matching.reject_reason_prompt'.tr()),
            SizedBox(height: 2.h),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.rejectMatch(
                match.id,
                reasonController.text.isEmpty
                    ? 'No reason provided'
                    : reasonController.text,
              );
            },
            child: Text('matching.reject'.tr()),
          ),
        ],
      ),
    );
  }

  void _showPriceNegotiationDialog(
      MatchResult match, MatchingController controller) {
    final priceController = TextEditingController();

    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text('matching.negotiate_price'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('matching.enter_preferred_price'.tr()),
            SizedBox(height: 2.h),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Price (\$)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              if (price != null && price > 0) {
                Get.back();
                controller.acceptMatch(match.id, negotiatedPrice: price);
              } else {
                Get.snackbar('error.title'.tr(), 'validation.invalid_price'.tr());
              }
            },
            child: Text('matching.accept_with_price'.tr()),
          ),
        ],
      ),
    );
  }

  void _showNearbySearchDialog(
      BuildContext context, MatchingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('matching.find_nearby'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.inventory),
              title: Text('matching.nearby_packages'.tr()),
              onTap: () {
                Get.back();
                _loadNearbyPackages(controller);
              },
            ),
            ListTile(
              leading: Icon(Icons.directions_car),
              title: Text('matching.nearby_trips'.tr()),
              onTap: () {
                Get.back();
                _loadNearbyTrips(controller);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final MatchingController controller;

  const _FilterDialog({required this.controller});

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  final _maxDistanceController = TextEditingController();
  final _minRatingController = TextEditingController();

  TransportMode? _selectedTransportMode;
  PackageSize? _selectedMaxSize;
  bool _verifiedOnly = false;
  bool _urgentOnly = false;

  @override
  void initState() {
    super.initState();
    final criteria = widget.controller.currentCriteria;
    _maxDistanceController.text = criteria.maxDistance?.toString() ?? '';
    _minRatingController.text = criteria.minTravelerRating?.toString() ?? '';
    _selectedTransportMode = criteria.preferredTransportMode;
    _selectedMaxSize = criteria.maxPackageSize;
    _verifiedOnly = criteria.verifiedTravelersOnly ?? false;
    _urgentOnly = criteria.urgentOnly ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('matching.filter_title'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _maxDistanceController,
              decoration: InputDecoration(
                labelText: 'Max Distance (km)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _minRatingController,
              decoration: InputDecoration(
                labelText: 'travel.min_traveler_rating'.tr(),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<TransportMode>(
              initialValue: _selectedTransportMode,
              decoration: InputDecoration(
                labelText: 'detail.transport_mode'.tr(),
                border: OutlineInputBorder(),
              ),
              items: TransportMode.values.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(mode.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (mode) =>
                  setState(() => _selectedTransportMode = mode),
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<PackageSize>(
              initialValue: _selectedMaxSize,
              decoration: InputDecoration(
                labelText: 'post_package.max_package_size'.tr(),
                border: OutlineInputBorder(),
              ),
              items: PackageSize.values.map((size) {
                return DropdownMenuItem(
                  value: size,
                  child: Text(size.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (size) => setState(() => _selectedMaxSize = size),
            ),
            SizedBox(height: 2.h),
            SwitchListTile(
              title: Text('matching.verified_only'.tr()),
              value: _verifiedOnly,
              onChanged: (value) => setState(() => _verifiedOnly = value),
            ),
            SwitchListTile(
              title: Text('matching.urgent_only'.tr()),
              value: _urgentOnly,
              onChanged: (value) => setState(() => _urgentOnly = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('common.cancel'.tr()),
        ),
        TextButton(
          onPressed: () {
            widget.controller.resetCriteria();
            Get.back();
          },
          child: Text('matching.reset'.tr()),
        ),
        TextButton(
          onPressed: () {
            _applyFilters();
            Get.back();
          },
          child: Text('matching.apply'.tr()),
        ),
      ],
    );
  }

  void _applyFilters() {
    final criteria = MatchingCriteria(
      maxDistance: double.tryParse(_maxDistanceController.text),
      minTravelerRating: double.tryParse(_minRatingController.text),
      preferredTransportMode: _selectedTransportMode,
      maxPackageSize: _selectedMaxSize,
      verifiedTravelersOnly: _verifiedOnly,
      urgentOnly: _urgentOnly,
    );

    widget.controller.updateMatchingCriteria(criteria);
  }

  @override
  void dispose() {
    _maxDistanceController.dispose();
    _minRatingController.dispose();
    super.dispose();
  }
}
