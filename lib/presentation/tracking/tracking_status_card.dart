import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sizer/sizer.dart';
import '../../core/models/delivery_tracking.dart';
import '../../core/models/package_request.dart';
import '../../services/tracking_service.dart';

class TrackingStatusCard extends StatelessWidget {
  final DeliveryTracking tracking;
  final PackageRequest? packageRequest;

  const TrackingStatusCard({
    Key? key,
    required this.tracking,
    this.packageRequest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TrackingService.getStatusColor(tracking.status).withOpacity(0.1),
            TrackingService.getStatusColor(tracking.status).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              TrackingService.getStatusColor(tracking.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(5.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: TrackingService.getStatusColor(tracking.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  TrackingService.getStatusIcon(tracking.status),
                  color: Colors.white,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TrackingService.getStatusText(tracking.status),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Updated ${_formatTime(tracking.updatedAt)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Progress bar
          if (tracking.progressPercentage != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('common.progress'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${tracking.progressPercentage!.toInt()}%',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: TrackingService.getStatusColor(tracking.status),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: tracking.progressPercentage! / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                TrackingService.getStatusColor(tracking.status),
              ),
              minHeight: 8,
            ),
            SizedBox(height: 3.h),
          ],

          // Tracking details
          _buildDetailRow(
            icon: Icons.local_shipping,
            label: 'tracking.tracking_id'.tr(),
            value: tracking.id.substring(0, 8).toUpperCase(),
          ),

          if (tracking.pickupTime != null)
            _buildDetailRow(
              icon: Icons.flight_takeoff,
              label: 'tracking.picked_up_label'.tr(),
              value: _formatDateTime(tracking.pickupTime!),
            ),

          if (tracking.deliveryTime != null)
            _buildDetailRow(
              icon: Icons.check_circle,
              label: 'tracking.delivered_label'.tr(),
              value: _formatDateTime(tracking.deliveryTime!),
            ),

          if (tracking.currentLocation != null && tracking.isInProgress)
            _buildDetailRow(
              icon: Icons.location_on,
              label: 'tracking.current_location_label'.tr(),
              value: tracking.currentLocation!.address,
            ),

          if (tracking.notes != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note,
                    color: Colors.grey[600],
                    size: 5.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      tracking.notes!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: 5.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
