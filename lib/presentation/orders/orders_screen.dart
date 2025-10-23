import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/delivery_tracking.dart';
import '../../core/models/booking.dart';
import '../../core/models/package_request.dart';
import '../../core/models/travel_trip.dart';
import '../../services/tracking_service.dart';
import '../../services/booking_service.dart';
import '../../services/service_manager.dart';
import '../../services/deal_negotiation_service.dart';
import '../../core/repositories/package_repository.dart';
import '../../core/repositories/trip_repository.dart';
import '../../widgets/liquid_refresh_indicator.dart';
import '../../widgets/liquid_loading_indicator.dart';
import '../../presentation/booking/payment_method_screen.dart';
import '../../routes/tracking_route_handler.dart';
import '../package_detail/package_detail_screen.dart';
import '../trip_detail/trip_detail_screen.dart';
import '../offers/offers_tab_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TrackingService _trackingService;
  final BookingService _bookingService = BookingService();
  final DealNegotiationService _dealService = DealNegotiationService();

  List<DeliveryTracking> _allTrackings = [];
  List<Booking> _pendingPaymentBookings = [];
  bool _isLoading = false;
  int _unseenOffersCount = 0;

  // Stream subscriptions for real-time updates
  StreamSubscription<List<DeliveryTracking>>? _trackingSubscription;
  StreamSubscription<List<Booking>>? _bookingSubscription;
  StreamSubscription<int>? _offersCountSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 6,
        vsync:
            this); // 6 tabs: Active, Offers, Delivered, Pending, Payment Due, My Orders
    _initializeServices().then((_) {
      if (mounted) {
        _setupRealTimeStreams();
      }
    });
  }

  Future<void> _initializeServices() async {
    try {
      // Safely get or create TrackingService
      if (Get.isRegistered<TrackingService>()) {
        _trackingService = Get.find<TrackingService>();
      } else {
        // If not registered, try to initialize core services
        try {
          await ServiceManager.initializeCoreServices();
          _trackingService = Get.find<TrackingService>();
        } catch (e) {
          print('⚠️ Error initializing services, creating fallback: $e');
          _trackingService = TrackingService();
        }
      }
    } catch (e) {
      print('⚠️ Error getting TrackingService, creating new instance: $e');
      _trackingService = TrackingService();
    }
  }

  void _setupRealTimeStreams() {
    print('📱 OrdersScreen: Setting up real-time streams...');

    setState(() {
      _isLoading = true;
    });

    try {
      // Set up real-time tracking stream
      _trackingSubscription = _trackingService.streamUserTrackings().listen(
        (trackings) {
          if (mounted) {
            setState(() {
              _allTrackings = trackings;
              // Only stop loading if we have both tracking and booking data
              if (_pendingPaymentBookings.isNotEmpty || trackings.isNotEmpty) {
                _isLoading = false;
              }
            });
            print('✅ Received ${trackings.length} trackings via stream');
          }
        },
        onError: (error) {
          print('❌ Error in tracking stream: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );

      // Set up unseen offers count stream
      _offersCountSubscription = _dealService.streamUnseenOffersCount().listen(
        (count) {
          if (mounted) {
            setState(() {
              _unseenOffersCount = count;
            });
          }
        },
        onError: (error) {
          print('❌ Error in offers count stream: $error');
        },
      );

      // Set up real-time pending payments stream
      _bookingSubscription =
          _bookingService.getUserPendingPaymentBookings().listen(
        (bookings) {
          if (mounted) {
            setState(() {
              _pendingPaymentBookings = bookings;
              // Only stop loading if we have both tracking and booking data
              if (_allTrackings.isNotEmpty || bookings.isNotEmpty) {
                _isLoading = false;
              }
            });
            print(
                '✅ Received ${bookings.length} pending payment bookings via stream');
          }
        },
        onError: (error) {
          print('❌ Error in pending payments stream: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );

      // Set a timeout to stop loading if no data comes through
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('⚠️ Error setting up streams: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    print(
        '🔄 OrdersScreen: Manual refresh triggered - streams will auto-update');
    // With real-time streams, we don't need to manually reload data
    // The streams will automatically provide the latest data
    // This method is kept for compatibility with LiquidRefreshIndicator
    return Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _bookingSubscription?.cancel();
    _offersCountSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'orders.title'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF215C5C),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          tabs: [
            Tab(text: 'orders.active'.tr()),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('orders.offers'.tr()),
                  if (_unseenOffersCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D7A6E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _unseenOffersCount > 99
                            ? '99+'
                            : _unseenOffersCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'orders.delivered'.tr()),
            Tab(text: 'orders.pending'.tr()),
            Tab(text: 'orders.payment_due'.tr()),
            Tab(text: 'orders.title'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTrackings(),
          const OffersTabScreen(),
          _buildDeliveredTrackings(),
          _buildPendingTrackings(),
          _buildPendingPayments(),
          _buildMyOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildActiveTrackings() {
    return _buildTrackingList(
      filter: (tracking) => tracking.isInProgress == true,
      emptyTitle: 'orders.no_active_deliveries'.tr(),
      emptyMessage: 'orders.active_deliveries_message'.tr(),
    );
  }

  Widget _buildDeliveredTrackings() {
    return _buildTrackingList(
      filter: (tracking) => tracking.status == DeliveryStatus.delivered,
      emptyTitle: 'orders.no_delivered_orders'.tr(),
      emptyMessage: 'orders.delivered_orders_message'.tr(),
    );
  }

  Widget _buildPendingTrackings() {
    return _buildTrackingList(
      filter: (tracking) {
        print(
            '🔍 Checking tracking ${tracking.id}: status=${tracking.status.name}, isPending=${tracking.status == DeliveryStatus.pending}');
        return tracking.status == DeliveryStatus.pending;
      },
      emptyTitle: 'orders.no_pending_orders'.tr(),
      emptyMessage: 'orders.pending_orders_message'.tr(),
    );
  }

  Widget _buildPendingPayments() {
    return _buildPendingPaymentsList();
  }

  Widget _buildTrackingList({
    required bool Function(DeliveryTracking)? filter,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    return LiquidRefreshIndicator(
      onRefresh: _handleRefresh,
      child: Builder(
        builder: (context) {
          // Show loading state
          if (_isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LiquidLoadingIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'orders.loading_orders'.tr(),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final trackings = _allTrackings;
          print('📱 UI using ${trackings.length} trackings');

          // Apply filter if provided
          final filteredTrackings =
              filter != null ? trackings.where(filter).toList() : trackings;

          print('📱 After filter: ${filteredTrackings.length} trackings');

          // Show empty state
          if (filteredTrackings.isEmpty) {
            if (trackings.isEmpty) {
              // No orders at all
              return _buildEmptyState(emptyTitle, emptyMessage);
            } else {
              // Have orders but none match filter
              return _buildEmptyState(
                emptyTitle,
                'No orders match this filter. Try checking other tabs.',
              );
            }
          }

          // Show orders list
          return ListView.builder(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewPadding.bottom + 100,
            ),
            itemCount: filteredTrackings.length,
            itemBuilder: (context, index) {
              final tracking = filteredTrackings[index];
              return _buildTrackingCard(tracking);
            },
          );
        },
      ),
    );
  }

  Widget _buildTrackingCard(DeliveryTracking tracking) {
    return GestureDetector(
      onTap: () => _navigateToTrackingDetails(tracking),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'orders.tracking'.tr()} #${tracking.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(tracking.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(tracking.status),
                      style: TextStyle(
                        color: _getStatusColor(tracking.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${'orders.created'.tr()}: ${_formatDate(tracking.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.local_shipping,
                    color: Color(0xFF008080),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${'orders.package_id'.tr()}: ${tracking.packageRequestId.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              if (tracking.currentLocation != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${'orders.current'.tr()}: ${tracking.currentLocation}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildEmptyState(String title, String message) {
    return LiquidRefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      'orders.refresh_orders'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF215C5C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingPaymentsList() {
    return LiquidRefreshIndicator(
      onRefresh: _handleRefresh,
      child: Builder(
        builder: (context) {
          // Show loading state
          if (_isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LiquidLoadingIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'orders.loading_pending_payments'.tr(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final pendingBookings = _pendingPaymentBookings;
          print(
              '📱 UI using ${pendingBookings.length} pending payment bookings');

          // Show empty state
          if (pendingBookings.isEmpty) {
            return _buildEmptyState(
              'No pending payments',
              'Bookings that need payment completion will appear here',
            );
          }

          // Show list of pending payment bookings
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingBookings.length,
            itemBuilder: (context, index) {
              final booking = pendingBookings[index];
              return _buildPendingPaymentCard(booking);
            },
          );
        },
      ),
    );
  }

  Widget _buildPendingPaymentCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'orders.booking'.tr()} #${booking.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'orders.payment_due'.tr(),
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.payment,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${'orders.amount'.tr()}: €${booking.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${'orders.created'.tr()}: ${_formatDate(booking.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _completePendingPayment(booking),
                icon: const Icon(Icons.payment, size: 16),
                label: Text(
                  'orders.complete_payment'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _completePendingPayment(Booking booking) {
    // Navigate to payment method screen to complete the payment
    Get.to(() => PaymentMethodScreen(booking: booking));
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.picked_up:
        return Color(0xFF008080);
      case DeliveryStatus.in_transit:
        return Colors.purple;
      case DeliveryStatus.delivered:
        return Colors.green;
      case DeliveryStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'status.pending'.tr();
      case DeliveryStatus.picked_up:
        return 'status.picked_up'.tr();
      case DeliveryStatus.in_transit:
        return 'status.in_transit'.tr();
      case DeliveryStatus.delivered:
        return 'status.delivered'.tr();
      case DeliveryStatus.cancelled:
        return 'status.cancelled'.tr();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToTrackingDetails(DeliveryTracking tracking) {
    // Use TrackingRouteHandler for proper navigation with parameters
    TrackingRouteHandler.navigateToPackageTracking(
      trackingId: tracking.id,
      packageRequestId: tracking.packageRequestId,
    );
  }

  Widget _buildMyOrdersTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: const Color(0xFF215C5C),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF215C5C),
              tabs: [
                Tab(text: 'home.my_packages'.tr()),
                Tab(text: 'travel.my_trips'.tr()),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMyPackagesTab(),
                _buildMyTripsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPackagesTab() {
    // Use Firebase Auth directly as it's more reliable
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final packageRepository = PackageRepository();

    print('🔍 My Packages Tab - User ID: $currentUserId');

    // Debug: Also check all packages to see if the package exists
    packageRepository.getRecentPackages(limit: 100).listen((allPackages) {
      print('📊 Total packages in DB: ${allPackages.length}');
      final myPackages =
          allPackages.where((p) => p.senderId == currentUserId).toList();
      print('📊 My packages from all: ${myPackages.length}');
      if (myPackages.isNotEmpty) {
        print(
            '📊 My package sender IDs: ${myPackages.map((p) => p.senderId).toList()}');
      }
    });

    return StreamBuilder<List<PackageRequest>>(
      stream: packageRepository.getPackagesBySender(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LiquidLoadingIndicator(
              size: 80,
              color: Color(0xFF215C5C),
            ),
          );
        }

        if (snapshot.hasError) {
          print('❌ My Packages Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'home.error_loading_packages'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final packages = snapshot.data ?? [];
        print('📦 My Packages Count: ${packages.length}');
        if (packages.isNotEmpty) {
          print('📦 Package IDs: ${packages.map((p) => p.id).toList()}');
          print(
              '📦 Package Sender IDs: ${packages.map((p) => p.senderId).toList()}');
        }

        if (packages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'home.no_packages_yet'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'post_package.your_posted_packages_will_appear_here'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return LiquidRefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              return _buildPackageCard(package);
            },
          ),
        );
      },
    );
  }

  Widget _buildMyTripsTab() {
    // Use Firebase Auth directly as it's more reliable
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final tripRepository = TripRepository();

    print('🔍 My Trips Tab - User ID: $currentUserId');

    return StreamBuilder<List<TravelTrip>>(
      stream: tripRepository.getTripsByTraveler(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LiquidLoadingIndicator(
              size: 80,
              color: Color(0xFF215C5C),
            ),
          );
        }

        if (snapshot.hasError) {
          print('❌ My Trips Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'home.error_loading_trips'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final trips = snapshot.data ?? [];
        print('✈️ My Trips Count: ${trips.length}');

        if (trips.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flight_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'home.no_trips_yet'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'travel.your_posted_trips_will_appear_here'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return LiquidRefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return _buildTripCard(trip);
            },
          ),
        );
      },
    );
  }

  Widget _buildPackageCard(PackageRequest package) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF215C5C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Color(0xFF215C5C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.packageDetails.description,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${package.pickupLocation.city ?? package.pickupLocation.address} → ${package.destinationLocation.city ?? package.destinationLocation.address}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '€${package.compensationOffer.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF215C5C),
                    ),
                  ),
                  _buildPackageStatusBadge(package.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(TravelTrip trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF215C5C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.flight,
                      color: Color(0xFF215C5C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.departureLocation.city ?? trip.departureLocation.address} → ${trip.destinationLocation.city ?? trip.destinationLocation.address}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(trip.departureDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${trip.capacity.maxWeightKg} kg available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  _buildTripStatusBadge(trip.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageStatusBadge(PackageStatus status) {
    Color color;
    String text;

    switch (status) {
      case PackageStatus.pending:
        color = Colors.green;
        text = 'Pending';
        break;
      case PackageStatus.matched:
        color = Color(0xFF008080);
        text = 'Matched';
        break;
      case PackageStatus.confirmed:
        color = Colors.purple;
        text = 'Confirmed';
        break;
      case PackageStatus.pickedUp:
        color = Colors.orange;
        text = 'Picked Up';
        break;
      case PackageStatus.inTransit:
        color = Colors.orange;
        text = 'In Transit';
        break;
      case PackageStatus.delivered:
        color = Colors.green;
        text = 'Delivered';
        break;
      case PackageStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case PackageStatus.disputed:
        color = Colors.red;
        text = 'Disputed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTripStatusBadge(TripStatus status) {
    Color color;
    String text;

    switch (status) {
      case TripStatus.active:
        color = Colors.green;
        text = 'Active';
        break;
      case TripStatus.full:
        color = Colors.orange;
        text = 'Full';
        break;
      case TripStatus.inProgress:
        color = Color(0xFF008080);
        text = 'In Progress';
        break;
      case TripStatus.completed:
        color = Colors.purple;
        text = 'Completed';
        break;
      case TripStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
