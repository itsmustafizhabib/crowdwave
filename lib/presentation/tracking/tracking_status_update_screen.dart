import 'package:flutter/material.dart';
import '../../widgets/liquid_loading_indicator.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/models/delivery_tracking.dart';
import '../../services/tracking_service.dart';
import '../../services/location_service.dart';

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
        setState(() {
          _currentLocationText =
              'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
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
        title: const Text('Update Status'),
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
          Text(
            'Current Status',
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
              child: Text(
                'Package is already delivered or cancelled',
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
          Text(
            'Update to Status',
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
          Text(
            'Photo Evidence',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Add a photo to document the status update',
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
                    label: const Text('Change Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
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
                      Text(
                        'Tap to add photo',
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
                child: Text(
                  'Include Location',
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
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.blue[600],
                    size: 5.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      _currentLocationText ?? 'Loading location...',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.blue[700],
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
          Text(
            'Additional Notes',
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
              hintText: 'Add any additional information about this update...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed:
            _selectedStatus != null && !_isLoading ? _updateStatus : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedStatus != null
              ? TrackingService.getStatusColor(_selectedStatus!)
              : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SmallLiquidLoading()
            : Text(
                _selectedStatus != null
                    ? 'Update to ${TrackingService.getStatusText(_selectedStatus!)}'
                    : 'Status Already Final',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
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

      Get.snackbar(
        'Status Updated',
        'Delivery status has been updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      // Navigate back to tracking screen
      Get.back(result: true);
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
