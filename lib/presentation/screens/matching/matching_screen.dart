import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
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
        title: Text('Smart Matching'),
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
                Tab(text: 'Auto Matches', icon: Icon(Icons.auto_awesome)),
                Tab(text: 'Browse Trips', icon: Icon(Icons.explore)),
                Tab(text: 'Nearby Packages', icon: Icon(Icons.location_on)),
                Tab(text: 'Nearby Trips', icon: Icon(Icons.directions_car)),
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
        tooltip: 'Find Nearby',
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
                'Auto-Matching',
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
          'No Auto-Matches Found',
          'We couldn\'t find any automatic matches for your package. Try adjusting your filters or browse trips manually.',
          Icons.auto_awesome_motion,
          () => _triggerAutoMatch(controller),
          'Find Matches',
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
          'No Trips Available',
          'There are no trips matching your criteria at the moment. Try adjusting your filters or check back later.',
          Icons.explore_off,
          () => _loadPotentialTrips(controller),
          'Search Trips',
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
          'No Nearby Packages',
          'No packages found in your area. Enable location services and try again.',
          Icons.location_off,
          () => _loadNearbyPackages(controller),
          'Find Nearby',
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
          'No Nearby Trips',
          'No trips found in your area. Enable location services and try again.',
          Icons.location_off,
          () => _loadNearbyTrips(controller),
          'Find Nearby',
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
                      ? Colors.blue.shade100
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
                      child: Text('Accept'),
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
                      child: Text('Reject'),
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
                  '\$${trip.suggestedReward}',
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
              child: Text('Contact Traveler'),
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
              ? Colors.blue.shade100
              : Colors.green.shade100,
          child: Icon(
            suggestion.type == 'package'
                ? Icons.inventory
                : Icons.directions_car,
            color: suggestion.type == 'package' ? Colors.blue : Colors.green,
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
        backgroundColor: Colors.blue.shade100,
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
        return Colors.blue;
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
      Get.snackbar('Error', 'No package selected for matching');
    }
  }

  void _loadPotentialTrips(MatchingController controller) {
    if (packageRequest != null) {
      controller.findPotentialTrips(packageRequest!);
    } else {
      Get.snackbar('Error', 'No package request provided');
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
    Get.snackbar('Contact', 'Opening chat with ${trip.travelerName}');
  }

  void _viewSuggestionDetails(NearbySuggestion suggestion) {
    // Navigate to detailed view
    Get.snackbar('Details', 'Viewing details for ${suggestion.title}');
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
        title: Text('Accept Match'),
        content: Text(
            'Do you want to accept this match? You can negotiate the price if needed.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.acceptMatch(match.id);
            },
            child: Text('Accept'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _showPriceNegotiationDialog(match, controller);
            },
            child: Text('Negotiate Price'),
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
        title: Text('Reject Match'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Why are you rejecting this match?'),
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
            child: Text('Cancel'),
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
            child: Text('Reject'),
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
        title: Text('Negotiate Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your preferred price for this delivery:'),
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
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              if (price != null && price > 0) {
                Get.back();
                controller.acceptMatch(match.id, negotiatedPrice: price);
              } else {
                Get.snackbar('Error', 'Please enter a valid price');
              }
            },
            child: Text('Accept with Price'),
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
        title: Text('Find Nearby'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.inventory),
              title: Text('Nearby Packages'),
              onTap: () {
                Get.back();
                _loadNearbyPackages(controller);
              },
            ),
            ListTile(
              leading: Icon(Icons.directions_car),
              title: Text('Nearby Trips'),
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
      title: Text('Filter Matches'),
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
                labelText: 'Min Traveler Rating',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<TransportMode>(
              initialValue: _selectedTransportMode,
              decoration: InputDecoration(
                labelText: 'Transport Mode',
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
                labelText: 'Max Package Size',
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
              title: Text('Verified Travelers Only'),
              value: _verifiedOnly,
              onChanged: (value) => setState(() => _verifiedOnly = value),
            ),
            SwitchListTile(
              title: Text('Urgent Packages Only'),
              value: _urgentOnly,
              onChanged: (value) => setState(() => _urgentOnly = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.controller.resetCriteria();
            Get.back();
          },
          child: Text('Reset'),
        ),
        TextButton(
          onPressed: () {
            _applyFilters();
            Get.back();
          },
          child: Text('Apply'),
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
