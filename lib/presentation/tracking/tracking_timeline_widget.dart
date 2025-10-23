import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sizer/sizer.dart';
import '../../core/models/delivery_tracking.dart';
import '../../core/models/travel_trip.dart';

class TrackingTimelineWidget extends StatelessWidget {
  final DeliveryTracking tracking;
  final TransportMode? transportMode;

  const TrackingTimelineWidget({
    Key? key,
    required this.tracking,
    this.transportMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: EdgeInsets.all(5.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('tracking.delivery_timeline'.tr(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 3.h),
          _buildTimelineSteps(),
          if (tracking.trackingPoints.isNotEmpty) ...[
            SizedBox(height: 3.h),
            _buildLocationHistory(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineSteps() {
    final steps = _getTimelineSteps();

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return _buildTimelineStep(
          step: step,
          isCompleted: step.isCompleted,
          isActive: step.isActive,
          isLast: isLast,
        );
      }).toList(),
    );
  }

  List<TimelineStep> _getTimelineSteps() {
    return [
      TimelineStep(
        title: 'tracking.package_confirmed'.tr(),
        subtitle: 'tracking.ready_for_pickup'.tr(),
        icon: Icons.check_circle_outline,
        isCompleted: true,
        isActive: false,
        timestamp: tracking.createdAt,
      ),
      TimelineStep(
        title: 'tracking.picked_up_label'.tr(),
        subtitle: 'tracking.collected_by_traveler'.tr(),
        imagePath: 'assets/thin.png',
        isCompleted: tracking.status.index >= DeliveryStatus.picked_up.index,
        isActive: tracking.status == DeliveryStatus.picked_up,
        timestamp: tracking.pickupTime,
      ),
      TimelineStep(
        title: 'tracking.in_transit'.tr(),
        subtitle: 'tracking.package_on_the_way'.tr(),
        icon: _getTransportIcon(),
        isCompleted: tracking.status.index >= DeliveryStatus.in_transit.index,
        isActive: tracking.status == DeliveryStatus.in_transit,
        timestamp: null, // Will be set when status changes
      ),
      TimelineStep(
        title: 'tracking.delivered_label'.tr(),
        subtitle: 'tracking.package_delivered_successfully'.tr(),
        icon: Icons.check_circle,
        isCompleted: tracking.status == DeliveryStatus.delivered,
        isActive: false,
        timestamp: tracking.deliveryTime,
      ),
    ];
  }

  IconData _getTransportIcon() {
    if (transportMode == null) {
      return Icons.local_shipping; // Default icon
    }

    switch (transportMode!) {
      case TransportMode.flight:
        return Icons.flight;
      case TransportMode.train:
        return Icons.train;
      case TransportMode.bus:
        return Icons.directions_bus;
      case TransportMode.car:
        return Icons.directions_car;
      case TransportMode.ship:
        return Icons.directions_boat;
      case TransportMode.motorcycle:
        return Icons.motorcycle;
      case TransportMode.bicycle:
        return Icons.directions_bike;
      case TransportMode.walking:
        return Icons.directions_walk;
    }
  }

  Widget _buildTimelineStep({
    required TimelineStep step,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    final color = isCompleted
        ? Colors.green
        : isActive
            ? Color(0xFF008080)
            : Colors.grey[400]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: isCompleted || isActive ? color : Colors.white,
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
              ),
              child: step.imagePath != null
                  ? Padding(
                      padding: EdgeInsets.all(2.w),
                      child: Image.asset(
                        step.imagePath!,
                        color: isCompleted || isActive ? Colors.white : color,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(
                      step.icon!,
                      color: isCompleted || isActive ? Colors.white : color,
                      size: 5.w,
                    ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 8.h,
                color: isCompleted ? Colors.green : Colors.grey[300],
              ),
          ],
        ),

        SizedBox(width: 4.w),

        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isCompleted || isActive
                        ? Colors.grey[800]
                        : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                  ),
                ),
                if (step.timestamp != null) ...[
                  SizedBox(height: 1.h),
                  Text(
                    _formatDateTime(step.timestamp!),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationHistory() {
    if (tracking.trackingPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.grey[300]),
        SizedBox(height: 2.h),
        Text('common.location_history'.tr(),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 2.h),
        ...tracking.trackingPoints
            .take(3)
            .map((point) => _buildLocationPoint(point)),
        if (tracking.trackingPoints.length > 3) ...[
          SizedBox(height: 1.h),
          Center(
            child: TextButton(
              onPressed: () => _showAllLocations(),
              child: Text(
                'View all ${tracking.trackingPoints.length} locations',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Color(0xFF008080),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationPoint(LocationPoint point) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Color(0xFF008080),
            size: 5.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.address,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
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
    );
  }

  void _showAllLocations() {
    // Navigate to detailed location history screen
    // This would show all tracking points on a map
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class TimelineStep {
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? imagePath;
  final bool isCompleted;
  final bool isActive;
  final DateTime? timestamp;

  TimelineStep({
    required this.title,
    required this.subtitle,
    this.icon,
    this.imagePath,
    required this.isCompleted,
    required this.isActive,
    this.timestamp,
  }) : assert(icon != null || imagePath != null,
            'Either icon or imagePath must be provided');
}
