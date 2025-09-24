import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/models/delivery_tracking.dart';

class TrackingLocationWidget extends StatelessWidget {
  final LocationPoint currentLocation;
  final DeliveryTracking tracking;

  const TrackingLocationWidget({
    Key? key,
    required this.currentLocation,
    required this.tracking,
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
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Icon(
                Icons.radio_button_checked,
                color: Colors.green,
                size: 5.w,
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Location details
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentLocation.address,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Icon(
                      Icons.my_location,
                      color: Colors.grey[600],
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${currentLocation.latitude.toStringAsFixed(6)}, ${currentLocation.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Map placeholder with action buttons
          Container(
            height: 20.h,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Map placeholder
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map,
                        color: Colors.grey[400],
                        size: 8.w,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Live Location Tracking',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Tap to view on map',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),

                // Overlay buttons
                Positioned(
                  top: 2.w,
                  right: 2.w,
                  child: Row(
                    children: [
                      _buildMapButton(
                        icon: Icons.directions,
                        onTap: _openDirections,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 2.w),
                      _buildMapButton(
                        icon: Icons.fullscreen,
                        onTap: _openFullMap,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),

                // Refresh indicator
                Positioned(
                  bottom: 2.w,
                  left: 2.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.green,
                          size: 4.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareLocation,
                  icon: Icon(Icons.share_location, size: 4.w),
                  label: const Text('Share Location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _refreshLocation,
                  icon: Icon(Icons.refresh, size: 4.w),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
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

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 4.w,
        ),
      ),
    );
  }

  void _openDirections() {
    // Open directions in maps app
    // Could use url_launcher to open Google Maps with directions
  }

  void _openFullMap() {
    // Navigate to full screen map view
    // Could show a detailed map with route and tracking history
  }

  void _shareLocation() {
    // Share current location via share dialog
    // Could generate a link to view location
  }

  void _refreshLocation() {
    // Trigger location refresh
    // Could call tracking service to update current location
  }
}
