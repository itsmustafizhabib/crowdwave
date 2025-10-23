import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sizer/sizer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../core/models/delivery_tracking.dart';
import '../../core/models/package_request.dart';

/// Widget showing live tracking map with animated route
class TrackingLocationWidget extends StatefulWidget {
  final LocationPoint currentLocation;
  final DeliveryTracking tracking;
  final PackageRequest? packageRequest;

  const TrackingLocationWidget({
    Key? key,
    required this.currentLocation,
    required this.tracking,
    this.packageRequest,
  }) : super(key: key);

  @override
  State<TrackingLocationWidget> createState() => _TrackingLocationWidgetState();
}

class _TrackingLocationWidgetState extends State<TrackingLocationWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    print('🗺️ TrackingLocationWidget initState');
    print('   - packageRequest is null: ${widget.packageRequest == null}');
    print(
        '   - currentLocation: ${widget.currentLocation.latitude}, ${widget.currentLocation.longitude}');
    _setupMapData();
  }

  @override
  void didUpdateWidget(TrackingLocationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update when courier location changes
    if (oldWidget.currentLocation != widget.currentLocation) {
      _setupMapData();
    }
  }

  void _setupMapData() {
    print('🗺️ _setupMapData called');
    print('   - widget.packageRequest: ${widget.packageRequest}');

    if (widget.packageRequest == null) {
      print('   ❌ packageRequest is NULL - Map will not load!');
      return;
    }

    print('   ✅ packageRequest is NOT null');
    print('   - pickup: ${widget.packageRequest!.pickupLocation.address}');
    print(
        '   - destination: ${widget.packageRequest!.destinationLocation.address}');

    final markers = <Marker>{};
    final polylines = <Polyline>{};

    // Get locations
    final pickup = widget.packageRequest!.pickupLocation;
    final destination = widget.packageRequest!.destinationLocation;
    final courier = widget.currentLocation;

    // Pickup marker (Orange - Source/Origin)
    markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: LatLng(pickup.latitude, pickup.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: InfoWindow(
        title: '� Pickup Location',
        snippet: pickup.address,
      ),
    ));

    // Destination marker (Violet/Purple - Final destination)
    markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: LatLng(destination.latitude, destination.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      infoWindow: InfoWindow(
        title: '� Destination',
        snippet: destination.address,
      ),
    ));

    // Courier position marker (Cyan - Current location)
    markers.add(Marker(
      markerId: const MarkerId('courier'),
      position: LatLng(courier.latitude, courier.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      infoWindow: InfoWindow (
        title: 'tracking.package_location_icon'.tr(),
        snippet: 'Currently here',
      ),
      anchor: const Offset(0.5, 0.5),
    ));

    // Create route lines
    final pickupPoint = LatLng(pickup.latitude, pickup.longitude);
    final courierPoint = LatLng(courier.latitude, courier.longitude);
    final destinationPoint =
        LatLng(destination.latitude, destination.longitude);

    // Traveled path (Pickup -> Courier) - Blue solid line
    polylines.add(Polyline(
      polylineId: const PolylineId('traveled'),
      points: [pickupPoint, courierPoint],
      color: Color(0xFF008080),
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    ));

    // Remaining path (Courier -> Destination) - Gray dashed line
    polylines.add(Polyline(
      polylineId: const PolylineId('remaining'),
      points: [courierPoint, destinationPoint],
      color: Colors.grey.shade400,
      width: 4,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    ));

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    // Auto-adjust camera to show all markers
    if (_isMapReady && _mapController != null) {
      _fitMapToRoute();
    }
  }

  Future<void> _fitMapToRoute() async {
    if (_mapController == null || widget.packageRequest == null) return;

    final pickup = widget.packageRequest!.pickupLocation;
    final destination = widget.packageRequest!.destinationLocation;
    final courier = widget.currentLocation;

    // Calculate bounds
    double minLat = pickup.latitude;
    double maxLat = pickup.latitude;
    double minLng = pickup.longitude;
    double maxLng = pickup.longitude;

    final lats = [pickup.latitude, destination.latitude, courier.latitude];
    final lngs = [pickup.longitude, destination.longitude, courier.longitude];

    for (var lat in lats) {
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
    }

    for (var lng in lngs) {
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    } catch (e) {
      print('Camera animation error: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() => _isMapReady = true);
    _fitMapToRoute();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _expandMap() {
    // Open fullscreen map dialog for better interaction
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Scaffold(
          appBar: AppBar(
            title: Text('travel.package_location'.tr()),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.currentLocation.latitude,
                widget.currentLocation.longitude,
              ),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: true,
            compassEnabled: true,
            trafficEnabled: false,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),
        ),
      ),
    );
  }

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
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFF008080), size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Text('tracking.live_tracking'.tr(),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              // Live indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radio_button_checked,
                        color: Colors.white, size: 3.w),
                    SizedBox(width: 1.w),
                    Text('common.live'.tr(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Current location info
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Color(0xFF008080).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF008080).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentLocation.address,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Icon(Icons.my_location, color: Colors.grey[600], size: 3.w),
                    SizedBox(width: 1.w),
                    Text(
                      '${widget.currentLocation.latitude.toStringAsFixed(4)}, ${widget.currentLocation.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Google Map - Tap to expand for better interaction
          GestureDetector(
            onTap: _expandMap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 30.h,
                child: Stack(
                  children: [
                    if (widget.packageRequest != null)
                      AbsorbPointer(
                        absorbing: false, // Allow map interactions
                        child: GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              widget.currentLocation.latitude,
                              widget.currentLocation.longitude,
                            ),
                            zoom: 12,
                          ),
                          markers: _markers,
                          polylines: _polylines,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: true,
                          compassEnabled: true,
                          trafficEnabled: false,
                          rotateGesturesEnabled: true,
                          scrollGesturesEnabled: true,
                          tiltGesturesEnabled: true,
                          zoomGesturesEnabled: true,
                        ),
                      )
                    else
                      Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Text('common.map_data_loading'.tr(),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),

                    // Hint overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_full,
                                color: Colors.white, size: 4.w),
                            SizedBox(width: 1.w),
                            Text('common.tap_to_expand'.tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Map legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('📍 Pickup', Colors.green),
              _buildLegendItem('🚚 Package', Color(0xFF008080)),
              _buildLegendItem('🎯 Destination', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
