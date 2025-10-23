import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:sizer/sizer.dart';
import '../../core/models/delivery_tracking.dart';
import '../../core/models/package_request.dart';
import '../../services/tracking_service.dart';
import '../../services/auth_state_service.dart';
import '../tracking/tracking_timeline_widget.dart';
import '../tracking/tracking_status_card.dart';
import '../tracking/tracking_location_widget_simple.dart';
import '../../widgets/liquid_loading_indicator.dart';
import '../../widgets/liquid_refresh_indicator.dart';

class PackageTrackingScreen extends StatefulWidget {
  final String trackingId;
  final String? packageRequestId;

  const PackageTrackingScreen({
    Key? key,
    required this.trackingId,
    this.packageRequestId,
  }) : super(key: key);

  @override
  State<PackageTrackingScreen> createState() => _PackageTrackingScreenState();
}

class _PackageTrackingScreenState extends State<PackageTrackingScreen>
    with TickerProviderStateMixin {
  final TrackingService _trackingService = Get.find<TrackingService>();
  final AuthStateService _authService = Get.find<AuthStateService>();

  late AnimationController _statusAnimationController;
  late AnimationController _mapAnimationController;
  late Animation<double> _statusFadeAnimation;
  late Animation<double> _mapScaleAnimation;

  DeliveryTracking? _currentTracking;
  PackageRequest? _packageRequest;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadTrackingData();
  }

  void _setupAnimations() {
    _statusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _mapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _statusFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statusAnimationController,
      curve: Curves.easeInOut,
    ));

    _mapScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mapAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _loadTrackingData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load tracking data
      final tracking = await _trackingService.getTracking(widget.trackingId);
      if (tracking == null) {
        setState(() {
          _error = 'Tracking information not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _currentTracking = tracking;
        _isLoading = false;
      });

      // Start animations
      _statusAnimationController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _mapAnimationController.forward();
    } catch (e) {
      setState(() {
        _error = 'Failed to load tracking data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshTracking() async {
    await _loadTrackingData();
  }

  bool get _isUserTraveler {
    final currentUserId = _authService.currentUser?.uid;
    return currentUserId == _currentTracking?.travelerId;
  }

  @override
  void dispose() {
    _statusAnimationController.dispose();
    _mapAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('post_package.package_tracking'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTracking,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LiquidLoadingIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_currentTracking == null) {
      return _buildNotFoundState();
    }

    return LiquidRefreshIndicator(
      onRefresh: _refreshTracking,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            FadeTransition(
              opacity: _statusFadeAnimation,
              child: TrackingStatusCard(
                tracking: _currentTracking!,
                packageRequest: _packageRequest,
              ),
            ),
            SizedBox(height: 3.h),

            // Current Location (if in progress)
            if (_currentTracking!.isInProgress &&
                _currentTracking!.currentLocation != null)
              ScaleTransition(
                scale: _mapScaleAnimation,
                child: TrackingLocationWidget(
                  currentLocation: _currentTracking!.currentLocation!,
                  tracking: _currentTracking!,
                ),
              ),

            if (_currentTracking!.isInProgress &&
                _currentTracking!.currentLocation != null)
              SizedBox(height: 3.h),

            // Timeline
            FadeTransition(
              opacity: _statusFadeAnimation,
              child: TrackingTimelineWidget(
                tracking: _currentTracking!,
              ),
            ),

            // Traveler Actions (if user is the traveler)
            if (_isUserTraveler && _currentTracking!.isInProgress) ...[
              SizedBox(height: 3.h),
              _buildTravelerActions(),
            ],

            // Contact Information
            SizedBox(height: 3.h),
            _buildContactSection(),

            SizedBox(height: 10.h), // Bottom padding
          ],
        ),
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
              'error_messages.something_went_wrong'.tr(),
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
                        label: Text(
                          'common.back'.tr(),
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
                        onPressed: _refreshTracking,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(
                          'common.refresh'.tr(),
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

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 15.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 2.h),
            Text('tracking.tracking_not_found'.tr(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 1.h),
            Text('post_package.the_tracking_information_for_this_package_could_no'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back),
              label: Text('common.go_back'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelerActions() {
    return Container(
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
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('travel.traveler_actions'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showUpdateStatusDialog,
                  icon: const Icon(Icons.update, size: 18),
                  label: Text('tracking.update_status'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addLocationCheckpoint,
                  icon: const Icon(Icons.location_on, size: 18),
                  label: Text('tracking.add_checkpoint'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
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
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('common.need_help'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _contactSupport,
                  icon: const Icon(Icons.support_agent, size: 18),
                  label: Text('booking.contact_support'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reportIssue,
                  icon: const Icon(Icons.report_problem, size: 18),
                  label: Text('tracking.report_issue'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('tracking.update_delivery_status'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentTracking!.status == DeliveryStatus.pending)
              _buildStatusButton('Mark as Picked Up', DeliveryStatus.picked_up),
            if (_currentTracking!.status == DeliveryStatus.picked_up)
              _buildStatusButton(
                  'Mark as In Transit', DeliveryStatus.in_transit),
            if (_currentTracking!.status == DeliveryStatus.in_transit)
              _buildStatusButton('Mark as Delivered', DeliveryStatus.delivered),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String title, DeliveryStatus status) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 1.h),
      child: ElevatedButton(
        onPressed: () => _updateStatus(status),
        style: ElevatedButton.styleFrom(
          backgroundColor: TrackingService.getStatusColor(status),
          foregroundColor: Colors.white,
        ),
        child: Text(title),
      ),
    );
  }

  void _updateStatus(DeliveryStatus status) async {
    try {
      Get.back(); // Close dialog

      await _trackingService.updateDeliveryStatus(
        trackingId: widget.trackingId,
        status: status,
      );

      Get.snackbar(
        'Status Updated',
        'Delivery status has been updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      _refreshTracking();
    } catch (e) {
      Get.snackbar(
        'Update Failed',
        'Failed to update status: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _addLocationCheckpoint() async {
    try {
      await _trackingService.addLocationCheckpoint(
        trackingId: widget.trackingId,
        notes: 'Location checkpoint added',
      );

      Get.snackbar(
        'Checkpoint Added',
        'Location checkpoint has been recorded',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      _refreshTracking();
    } catch (e) {
      Get.snackbar(
        'Checkpoint Failed',
        'Failed to add checkpoint: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _contactSupport() {
    // Navigate to support chat or contact screen
    Get.snackbar(
      'Support',
      'Contacting support...',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _reportIssue() {
    // Navigate to issue reporting screen
    Get.snackbar(
      'Report Issue',
      'Opening issue report...',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }
}
