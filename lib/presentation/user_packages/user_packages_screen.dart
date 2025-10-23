import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_export.dart';
import '../../services/firebase_auth_service.dart';
import '../package_detail/package_detail_screen.dart';
import '../trip_detail/trip_detail_screen.dart';
import '../../widgets/liquid_refresh_indicator.dart';
import '../../widgets/liquid_loading_indicator.dart';

// NOTE: User packages/trips are now primarily accessed via the home screen filter toggle
// This screen provides a more detailed view of user's own items
class UserPackagesScreen extends StatefulWidget {
  const UserPackagesScreen({Key? key}) : super(key: key);

  @override
  State<UserPackagesScreen> createState() => _UserPackagesScreenState();
}

class _UserPackagesScreenState extends State<UserPackagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PackageRepository _packageRepository = PackageRepository();
  final TripRepository _tripRepository = TripRepository();

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9E9E9),
      appBar: AppBar(
        title: Text('common.my_posts'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF215C5C),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Icon(Icons.local_shipping),
              text: 'home.my_packages'.tr(),
            ),
            Tab(
              icon: Icon(Icons.flight_takeoff),
              text: 'travel.my_trips'.tr(),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyPackagesTab(),
          _buildMyTripsTab(),
        ],
      ),
    );
  }

  Widget _buildMyPackagesTab() {
    if (_currentUserId.isEmpty) {
      return _buildNotLoggedInWidget();
    }

    return StreamBuilder<List<PackageRequest>>(
      stream: _packageRepository.getPackagesBySender(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: LiquidLoadingIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading packages: ${snapshot.error}');
        }

        final packages = snapshot.data ?? [];

        if (packages.isEmpty) {
          return _buildEmptyStateWidget(
            'No Packages Posted',
            'You haven\'t posted any packages yet.',
            Icons.inventory,
            'Post Package',
            () => Navigator.pushNamed(context, '/postPackage'),
          );
        }

        return LiquidRefreshIndicator(
          onRefresh: () async {
            // The stream will automatically refresh
            await Future.delayed(Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              return _buildPackageCard(packages[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildMyTripsTab() {
    if (_currentUserId.isEmpty) {
      return _buildNotLoggedInWidget();
    }

    return StreamBuilder<List<TravelTrip>>(
      stream: _tripRepository.getTripsByTraveler(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: LiquidLoadingIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading trips: ${snapshot.error}');
        }

        final trips = snapshot.data ?? [];

        if (trips.isEmpty) {
          return _buildEmptyStateWidget(
            'No Trips Posted',
            'You haven\'t posted any trips yet.',
            Icons.route,
            'Post Trip',
            () => Navigator.pushNamed(context, '/postTrip'),
          );
        }

        return LiquidRefreshIndicator(
          onRefresh: () async {
            // The stream will automatically refresh
            await Future.delayed(Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              return _buildTripCard(trips[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildPackageCard(PackageRequest package) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PackageDetailScreen(package: package),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(package.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPackageTypeIcon(package.packageDetails.type),
                      color: _getStatusColor(package.status),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      package.packageDetails.description,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(package.status),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${package.pickupLocation.city ?? package.pickupLocation.address} → ${package.destinationLocation.city ?? package.destinationLocation.address}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.grey[600], size: 16),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(package.preferredDeliveryDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '€${package.compensationOffer.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Color(0xFF215C5C),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (package.isUrgent) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.priority_high, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text('status.urgent'.tr(),
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(TravelTrip trip) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripDetailScreen(trip: trip),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTripStatusColor(trip.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTransportModeIcon(trip.transportMode),
                      color: _getTripStatusColor(trip.status),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${trip.departureLocation.city} → ${trip.destinationLocation.city}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildTripStatusChip(trip.status),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.grey[600], size: 16),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(trip.departureDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '€${trip.suggestedReward.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Color(0xFF215C5C),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.inventory, color: Colors.grey[600], size: 16),
                  SizedBox(width: 4),
                  Text(
                    '${trip.acceptedPackageIds.length}/${trip.capacity.maxPackages} packages',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(PackageStatus status) {
    Color color = _getStatusColor(status);
    String text = _getStatusText(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTripStatusChip(TripStatus status) {
    Color color = _getTripStatusColor(status);
    String text = _getTripStatusText(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotLoggedInWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text('common.please_log_in_to_view_your_posts'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget(
    String title,
    String subtitle,
    IconData icon,
    String buttonText,
    VoidCallback onPressed,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF215C5C),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              buttonText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(PackageStatus status) {
    switch (status) {
      case PackageStatus.pending:
        return Colors.orange;
      case PackageStatus.matched:
        return Color(0xFF008080);
      case PackageStatus.confirmed:
        return Colors.green;
      case PackageStatus.pickedUp:
        return Colors.purple;
      case PackageStatus.inTransit:
        return Colors.indigo;
      case PackageStatus.delivered:
        return Colors.green[700]!;
      case PackageStatus.cancelled:
        return Colors.red;
      case PackageStatus.disputed:
        return Colors.red[800]!;
    }
  }

  String _getStatusText(PackageStatus status) {
    switch (status) {
      case PackageStatus.pending:
        return 'Pending';
      case PackageStatus.matched:
        return 'Matched';
      case PackageStatus.confirmed:
        return 'Confirmed';
      case PackageStatus.pickedUp:
        return 'Picked Up';
      case PackageStatus.inTransit:
        return 'In Transit';
      case PackageStatus.delivered:
        return 'Delivered';
      case PackageStatus.cancelled:
        return 'Cancelled';
      case PackageStatus.disputed:
        return 'Disputed';
    }
  }

  Color _getTripStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.active:
        return Colors.green;
      case TripStatus.full:
        return Colors.orange;
      case TripStatus.inProgress:
        return Color(0xFF008080);
      case TripStatus.completed:
        return Colors.green[700]!;
      case TripStatus.cancelled:
        return Colors.red;
    }
  }

  String _getTripStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.active:
        return 'Active';
      case TripStatus.full:
        return 'Full';
      case TripStatus.inProgress:
        return 'In Progress';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }

  IconData _getPackageTypeIcon(PackageType type) {
    switch (type) {
      case PackageType.documents:
        return Icons.description;
      case PackageType.electronics:
        return Icons.devices;
      case PackageType.clothing:
        return Icons.checkroom;
      case PackageType.food:
        return Icons.restaurant;
      case PackageType.books:
        return Icons.menu_book;
      case PackageType.gifts:
        return Icons.card_giftcard;
      case PackageType.medicine:
        return Icons.medical_services;
      case PackageType.cosmetics:
        return Icons.face;
      case PackageType.other:
        return Icons.inventory;
    }
  }

  IconData _getTransportModeIcon(TransportMode mode) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays == -1) {
      return 'Yesterday';
    } else if (difference.inDays > 1) {
      return 'In ${difference.inDays} days';
    } else {
      return '${-difference.inDays} days ago';
    }
  }
}
