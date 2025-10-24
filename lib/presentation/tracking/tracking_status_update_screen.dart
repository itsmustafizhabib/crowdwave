import 'package:flutter/material.dart';
import '../../widgets/liquid_loading_indicator.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:sizer/sizer.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/models/delivery_tracking.dart';
import '../../services/tracking_service.dart';
import '../../services/location_service.dart';
import '../../services/geocoding_service.dart';
import '../../routes/tracking_route_handler.dart';
import '../../utils/toast_utils.dart';

class TrackingStatusUpdateScreen extends StatefulWidget {
  final String trackingId;
  final DeliveryTracking tracking;

  const TrackingStatusUpdateScreen({
    Key? key,
    required this.trackingId,
    required this.tracking,
  }) : super(key: key);

  @override
  State<TrackingStatusUpdateScreen> createState() =>
      _TrackingStatusUpdateScreenState();
}

class _TrackingStatusUpdateScreenState
    extends State<TrackingStatusUpdateScreen> {
  final TrackingService _trackingService = Get.find<TrackingService>();
  final LocationService _locationService = Get.find<LocationService>();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _notesController = TextEditingController();

  DeliveryStatus? _selectedStatus;
  File? _selectedImage;
  bool _isLoading = false;
  bool _includeLocation = true;
  String? _currentLocationText;

  @override
  void initState() {
    super.initState();
    _selectedStatus = _getNextStatus();
    _loadCurrentLocation();
  }

  DeliveryStatus? _getNextStatus() {
    switch (widget.tracking.status) {
      case DeliveryStatus.pending:
        return DeliveryStatus.picked_up;
      case DeliveryStatus.picked_up:
        return DeliveryStatus.in_transit;
      case DeliveryStatus.in_transit:
        return DeliveryStatus.delivered;
      default:
        return null;
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        // Fetch human-readable address
        final geocodingService = Get.find<GeocodingService>();
        final address = await geocodingService.getAddressFromCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        setState(() {
          _currentLocationText = address;
        });
      }
    } catch (e) {
      print('Error loading location: $e');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('tracking.update_status'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status
            _buildCurrentStatusCard(),
            SizedBox(height: 3.h),

            // Status Selection
            _buildStatusSelection(),
            SizedBox(height: 3.h),

            // Photo Upload
            _buildPhotoSection(),
            SizedBox(height: 3.h),

            // Location Section
            _buildLocationSection(),
            SizedBox(height: 3.h),

            // Notes Section
            _buildNotesSection(),
            SizedBox(height: 5.h),

            // Update Button
            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
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
          Text('tracking.current_status'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: TrackingService.getStatusColor(widget.tracking.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  TrackingService.getStatusIcon(widget.tracking.status),
                  color: Colors.white,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                TrackingService.getStatusText(widget.tracking.status),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelection() {
    if (_selectedStatus == null) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            SizedBox(width: 3.w),
            Expanded(
              child: Text('post_package.package_is_already_delivered_or_cancelled'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
      );
    }

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
          Text('common.update_to_status'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: TrackingService.getStatusColor(_selectedStatus!)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: TrackingService.getStatusColor(_selectedStatus!)
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: TrackingService.getStatusColor(_selectedStatus!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    TrackingService.getStatusIcon(_selectedStatus!),
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
                        TrackingService.getStatusText(_selectedStatus!),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        _getStatusDescription(_selectedStatus!),
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
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
          Row(
            children: [
              Text('common.photo_evidence'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text('common.required'.tr(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '📸 Take a clear photo to verify status update',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 2.h),
          if (_selectedImage != null) ...[
            Container(
              height: 20.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.refresh),
                    label: Text('tracking.change_photo'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF008080),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: const Icon(Icons.delete),
                    label: Text('profile.remove'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 15.h,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: Colors.grey[500],
                        size: 8.w,
                      ),
                      SizedBox(height: 1.h),
                      Text('common.tap_to_add_photo'.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
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
          Row(
            children: [
              Expanded(
                child: Text('common.include_location'.tr(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Switch(
                value: _includeLocation,
                onChanged: (value) => setState(() => _includeLocation = value),
                activeThumbColor: Colors.green,
              ),
            ],
          ),
          if (_includeLocation) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Color(0xFF008080),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Color(0xFF008080),
                    size: 5.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      _currentLocationText ?? 'Loading location...',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Color(0xFF008080),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
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
          Text('common.additional_notes'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'common.add_any_additional_information_about_this_update'.tr(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF008080)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    final canUpdate = _selectedImage != null && _selectedStatus != null;

    return Column(
      children: [
        // Validation messages
        if (_selectedStatus != null && _selectedImage == null)
          Container(
            padding: EdgeInsets.all(3.w),
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700], size: 5.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    '⚠️ Photo required to prevent fraud and verify delivery',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Padding(
          padding: EdgeInsets.only(bottom: 5.h),
          child: SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: canUpdate && !_isLoading ? _updateStatus : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canUpdate
                    ? TrackingService.getStatusColor(_selectedStatus!)
                    : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
              ),
              child: _isLoading
                  ? SmallLiquidLoading()
                  : Text(
                      _selectedStatus != null && canUpdate
                          ? 'Update to ${TrackingService.getStatusText(_selectedStatus!)}'
                          : _selectedStatus != null
                              ? '📸 Add Photo to Continue'
                              : 'Status Already Final',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusDescription(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.picked_up:
        return 'Package has been collected and pickup confirmed';
      case DeliveryStatus.in_transit:
        return 'Package is currently being transported';
      case DeliveryStatus.delivered:
        return 'Package has been successfully delivered';
      default:
        return '';
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to capture image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;

    setState(() => _isLoading = true);

    try {
      // Update the delivery status
      await _trackingService.updateDeliveryStatus(
        trackingId: widget.trackingId,
        status: _selectedStatus!,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        updateLocation: _includeLocation,
      );

      // If there's an image, handle it (for now just show success)
      if (_selectedImage != null) {
        // Here you could upload the image to Firebase Storage
        // and associate it with the tracking update
      }

      ToastUtils.show('tracking.updated'.tr());

      // Navigate to the package tracking screen
      TrackingRouteHandler.navigateToPackageTracking(
        trackingId: widget.trackingId,
        packageRequestId: null,
      );
    } catch (e) {
      Get.snackbar(
        'Update Failed',
        'Failed to update status: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
