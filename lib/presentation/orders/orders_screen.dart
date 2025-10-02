import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/models/delivery_tracking.dart';
import '../../core/models/booking.dart';
import '../../services/tracking_service.dart';
import '../../services/booking_service.dart';
import '../../widgets/liquid_refresh_indicator.dart';
import '../../widgets/liquid_loading_indicator.dart';
import '../../presentation/booking/payment_method_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TrackingService _trackingService = TrackingService();
  final BookingService _bookingService = BookingService();

  List<DeliveryTracking> _allTrackings = [];
  List<Booking> _pendingPaymentBookings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 5, vsync: this); // Increased from 4 to 5
    _loadTrackings();
  }

  void _loadTrackings() async {
    print('📱 OrdersScreen: Loading trackings and pending payments...');
    if (!mounted) return; // ✅ MOUNTED CHECK

    setState(() {
      _isLoading = true;
    });

    try {
      // Load both trackings and pending payment bookings
      final results = await Future.wait([
        _trackingService.getUserTrackingsComplete(),
        _bookingService.getAllPendingPaymentBookings(),
      ]);

      if (!mounted) return; // ✅ MOUNTED CHECK AFTER ASYNC OPERATION

      setState(() {
        _allTrackings = results[0] as List<DeliveryTracking>;
        _pendingPaymentBookings = results[1] as List<Booking>;
        _isLoading = false;
      });
      print(
          '✅ Loaded ${_allTrackings.length} trackings and ${_pendingPaymentBookings.length} pending payment bookings successfully');
    } catch (e) {
      print('❌ Error loading data: $e');

      if (!mounted) return; // ✅ MOUNTED CHECK AFTER ASYNC OPERATION

      setState(() {
        _allTrackings = [];
        _pendingPaymentBookings = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    print('🔄 OrdersScreen: Manual refresh triggered');
    _loadTrackings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF0046FF),
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
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Delivered'),
            Tab(text: 'Pending'),
            Tab(text: 'Payment Due'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTrackings(),
          _buildDeliveredTrackings(),
          _buildPendingTrackings(),
          _buildPendingPayments(),
          _buildAllTrackings(),
        ],
      ),
    );
  }

  Widget _buildActiveTrackings() {
    return _buildTrackingList(
      filter: (tracking) => tracking.isInProgress == true,
      emptyTitle: 'No active deliveries',
      emptyMessage: 'Your active deliveries will appear here',
    );
  }

  Widget _buildDeliveredTrackings() {
    return _buildTrackingList(
      filter: (tracking) => tracking.status == DeliveryStatus.delivered,
      emptyTitle: 'No delivered orders',
      emptyMessage: 'Your delivered orders will appear here',
    );
  }

  Widget _buildPendingTrackings() {
    return _buildTrackingList(
      filter: (tracking) => tracking.status == DeliveryStatus.pending,
      emptyTitle: 'No pending orders',
      emptyMessage: 'Your pending orders will appear here',
    );
  }

  Widget _buildPendingPayments() {
    return _buildPendingPaymentsList();
  }

  Widget _buildAllTrackings() {
    return _buildTrackingList(
      filter: null,
      emptyTitle: 'No orders yet',
      emptyMessage: 'Your orders will appear here',
    );
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LiquidLoadingIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading your orders...',
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
                    'Tracking #${tracking.id.substring(0, 8).toUpperCase()}',
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
                      'Created: ${_formatDate(tracking.createdAt)}',
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
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Package ID: ${tracking.packageRequestId.substring(0, 8).toUpperCase()}',
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
                        'Current: ${tracking.currentLocation}',
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
                    label: const Text(
                      'Refresh Orders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0046FF),
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LiquidLoadingIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading pending payments...',
                    style: TextStyle(
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
                  'Booking #${booking.id.substring(0, 8).toUpperCase()}',
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
                    'Payment Due',
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
                  'Amount: \$${booking.totalAmount.toStringAsFixed(2)}',
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
                  'Created: ${_formatDate(booking.createdAt)}',
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
                label: const Text(
                  'Complete Payment',
                  style: TextStyle(
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
        return Colors.blue;
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
        return 'Pending';
      case DeliveryStatus.picked_up:
        return 'Picked Up';
      case DeliveryStatus.in_transit:
        return 'In Transit';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToTrackingDetails(DeliveryTracking tracking) {
    Get.toNamed('/tracking/${tracking.id}');
  }
}
