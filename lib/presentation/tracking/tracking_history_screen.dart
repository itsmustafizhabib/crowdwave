import '../../widgets/liquid_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import '../../core/models/delivery_tracking.dart';
import '../../services/tracking_service.dart';

class TrackingHistoryScreen extends StatefulWidget {
  const TrackingHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TrackingHistoryScreen> createState() => _TrackingHistoryScreenState();
}

class _TrackingHistoryScreenState extends State<TrackingHistoryScreen>
    with TickerProviderStateMixin {
  final TrackingService _trackingService = Get.find<TrackingService>();

  late TabController _tabController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  List<DeliveryTracking> _allTrackings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _setupAnimations();
    _loadTrackingHistory();
  }

  void _setupAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadTrackingHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Set up a timeout to prevent infinite loading
      final timeoutDuration = const Duration(seconds: 10);

      // For now, we'll use a static method. In real implementation,
      // this would stream from the TrackingService
      _trackingService.streamUserTrackings().timeout(timeoutDuration).listen(
        (trackings) {
          if (mounted) {
            setState(() {
              _allTrackings = trackings;
              _isLoading = false;
            });
            _fadeAnimationController.forward();
          }
        },
        onError: (error) {
          print('❌ Error loading tracking history: $error');
          if (mounted) {
            setState(() {
              _error =
                  'Failed to load tracking history. Please check your connection and try again.';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      print('❌ Exception in _loadTrackingHistory: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load tracking history: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<DeliveryTracking> _getTrackingsByStatus(DeliveryStatus status) {
    return _allTrackings
        .where((tracking) => tracking.status == status)
        .toList();
  }

  List<DeliveryTracking> _getActiveTrackings() {
    return _allTrackings.where((tracking) => tracking.isInProgress).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Delivery History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          labelStyle: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Delivered'),
            Tab(text: 'Pending'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_allTrackings.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildTrackingList(_getActiveTrackings()),
          _buildTrackingList(_getTrackingsByStatus(DeliveryStatus.delivered)),
          _buildTrackingList(_getTrackingsByStatus(DeliveryStatus.pending)),
          _buildTrackingList(_allTrackings),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sad Face Icon
            Icon(
              Icons.sentiment_dissatisfied,
              size: 20.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 3.h),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'We encountered an unexpected error while\nprocessing your request.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),
            SizedBox(height: 4.h),
            // Button Row with proper spacing
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Row(
                children: [
                  // Back Button
                  Expanded(
                    child: Container(
                      height: 6.h,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  // Refresh Button
                  Expanded(
                    child: Container(
                      height: 6.h,
                      child: ElevatedButton.icon(
                        onPressed: _loadTrackingHistory,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text(
                          'Refresh',
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
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 15.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 2.h),
            Text(
              'No Delivery History',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Your delivery tracking history will appear here once you start making deliveries.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.add),
              label: const Text('Start Delivering'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingList(List<DeliveryTracking> trackings) {
    if (trackings.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 12.w,
                color: Colors.grey[400],
              ),
              SizedBox(height: 2.h),
              Text(
                'No items in this category',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LiquidRefreshIndicator(
      onRefresh: _loadTrackingHistory,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: trackings.length,
        itemBuilder: (context, index) {
          final tracking = trackings[index];
          return _buildTrackingCard(tracking, index);
        },
      ),
    );
  }

  Widget _buildTrackingCard(DeliveryTracking tracking, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
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
        onTap: () => _viewTrackingDetails(tracking),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: TrackingService.getStatusColor(tracking.status),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      TrackingService.getStatusIcon(tracking.status),
                      color: Colors.white,
                      size: 5.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TrackingService.getStatusText(tracking.status),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          'ID: ${tracking.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 6.w,
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Progress Bar (if applicable)
              if (tracking.progressPercentage != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${tracking.progressPercentage!.toInt()}%',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: TrackingService.getStatusColor(tracking.status),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                LinearProgressIndicator(
                  value: tracking.progressPercentage! / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    TrackingService.getStatusColor(tracking.status),
                  ),
                  minHeight: 6,
                ),
                SizedBox(height: 2.h),
              ],

              // Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailColumn(
                      'Created',
                      _formatDate(tracking.createdAt),
                      Icons.schedule,
                    ),
                  ),
                  if (tracking.pickupTime != null)
                    Expanded(
                      child: _buildDetailColumn(
                        'Picked Up',
                        _formatDate(tracking.pickupTime!),
                        Icons.flight_takeoff,
                      ),
                    ),
                  if (tracking.deliveryTime != null)
                    Expanded(
                      child: _buildDetailColumn(
                        'Delivered',
                        _formatDate(tracking.deliveryTime!),
                        Icons.check_circle,
                      ),
                    ),
                ],
              ),

              // Location Points Count
              if (tracking.trackingPoints.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_history,
                        color: Colors.blue[600],
                        size: 4.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${tracking.trackingPoints.length} location points',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Notes (if any)
              if (tracking.notes != null && tracking.notes!.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        color: Colors.grey[600],
                        size: 4.w,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          tracking.notes!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[500],
              size: 4.w,
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  void _viewTrackingDetails(DeliveryTracking tracking) {
    Get.toNamed('/tracking/${tracking.id}');
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
