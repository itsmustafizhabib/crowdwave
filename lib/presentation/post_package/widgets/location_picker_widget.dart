import 'package:flutter/material.dart';
import '../../../widgets/liquid_loading_indicator.dart';
import 'package:sizer/sizer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../../core/app_export.dart';
import 'package:easy_localization/easy_localization.dart';

class LocationPickerWidget extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Location? location;
  final Function(Location) onLocationSelected;
  final IconData? prefixIcon;
  final bool showMapPreview;
  final bool allowCurrentLocation;

  const LocationPickerWidget({
    Key? key,
    required this.title,
    this.subtitle,
    required this.location,
    required this.onLocationSelected,
    this.prefixIcon,
    this.showMapPreview = false,
    this.allowCurrentLocation = true,
  }) : super(key: key);

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and subtitle
          Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.prefixIcon != null) ...[
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.prefixIcon,
                          color: AppTheme.lightTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 3.w),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            SizedBox(height: 0.5.h),
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.lightTheme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Location selector
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: GestureDetector(
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) => _animationController.reverse(),
              onTapCancel: () => _animationController.reverse(),
              onTap: () => _showLocationOptions(),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.location != null
                        ? AppTheme.lightTheme.primaryColor
                            .withValues(alpha: 0.3)
                        : AppTheme.lightTheme.colorScheme.outline,
                    width: widget.location != null ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.lightTheme.colorScheme.shadow
                          .withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Location icon
                    Container(
                      padding: EdgeInsets.all(2.5.w),
                      decoration: BoxDecoration(
                        color: widget.location != null
                            ? AppTheme.lightTheme.primaryColor
                                .withValues(alpha: 0.1)
                            : AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomIconWidget(
                        iconName: 'location_on',
                        color: widget.location != null
                            ? AppTheme.lightTheme.primaryColor
                            : AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),

                    SizedBox(width: 3.w),

                    // Location text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.location?.address ??
                                'Tap to select location',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: widget.location != null
                                  ? AppTheme.lightTheme.colorScheme.onSurface
                                  : AppTheme.lightTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.location != null &&
                              widget.location!.city != null) ...[
                            SizedBox(height: 0.5.h),
                            Text(
                              '${widget.location!.city}, ${widget.location!.country}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppTheme.lightTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Arrow or loading
                    if (_isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.lightTheme.primaryColor,
                          ),
                        ),
                      )
                    else
                      CustomIconWidget(
                        iconName: 'arrow_forward_ios',
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.3),
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Map preview (if enabled and location selected)
          if (widget.showMapPreview && widget.location != null) ...[
            SizedBox(height: 2.h),
            _buildMapPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 20.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.location!.latitude,
              widget.location!.longitude,
            ),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: MarkerId('selected_location'),
              position: LatLng(
                widget.location!.latitude,
                widget.location!.longitude,
              ),
              infoWindow: InfoWindow(
                title: widget.title,
                snippet: widget.location!.address,
              ),
            ),
          },
          zoomGesturesEnabled: false,
          scrollGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  void _showLocationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildLocationBottomSheet(),
    );
  }

  Widget _buildLocationBottomSheet() {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 2.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select ${widget.title}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'common.close'.tr(),
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Options
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              children: [
                // Search location
                _buildLocationOption(
                  icon: Icons.search,
                  title: 'location.search_title'.tr(),
                  subtitle: 'location.search_subtitle'.tr(),
                  onTap: () => _showSearchDialog(),
                ),

                if (widget.allowCurrentLocation) ...[
                  SizedBox(height: 2.h),
                  _buildLocationOption(
                    icon: Icons.my_location,
                    title: 'location.use_current'.tr(),
                    subtitle: 'common.allow_location_access_to_use_your_current_position'.tr(),
                    onTap: () => _getCurrentLocation(),
                  ),
                ],

                SizedBox(height: 2.h),
                _buildLocationOption(
                  icon: Icons.map,
                  title: 'location.select_on_map'.tr(),
                  subtitle: 'location.select_on_map_subtitle'.tr(),
                  onTap: () => _showMapPicker(),
                ),

                // Recent locations (can be added later)
                SizedBox(height: 2.h),
                Text('common.recent_locations'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 1.h),
                // Add recent locations list here
                _buildRecentLocationCard('New York, NY', 'United States'),
                _buildRecentLocationCard('Los Angeles, CA', 'United States'),
                _buildRecentLocationCard('Chicago, IL', 'United States'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.lightTheme.primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLocationCard(String address, String country) {
    return InkWell(
      onTap: () {
        final location = Location(
          address: address,
          latitude: 40.7128, // Mock coordinates
          longitude: -74.0060,
          country: country,
        );
        widget.onLocationSelected(location);
        Navigator.pop(context);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 1.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'history',
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.5),
              size: 18,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    country,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
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

  void _showSearchDialog() {
    Navigator.pop(context); // Close bottom sheet
    showDialog(
      context: context,
      builder: (context) => LocationSearchDialog(
        onLocationSelected: widget.onLocationSelected,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    Navigator.pop(context); // Close bottom sheet
    setState(() => _isLoading = true);

    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final location = Location(
          address:
              '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}',
          latitude: position.latitude,
          longitude: position.longitude,
          city: placemark.locality,
          state: placemark.administrativeArea,
          country: placemark.country,
          postalCode: placemark.postalCode,
        );

        widget.onLocationSelected(location);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('location.get_current_failed'.tr(args: [e.toString()]))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMapPicker() {
    Navigator.pop(context); // Close bottom sheet
    // Navigate to full-screen map picker
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          title: widget.title,
          initialLocation: widget.location,
          onLocationSelected: widget.onLocationSelected,
        ),
      ),
    );
  }
}

// Full-screen map picker with Google Maps implementation
class MapPickerScreen extends StatefulWidget {
  final String title;
  final Location? initialLocation;
  final Function(Location) onLocationSelected;

  const MapPickerScreen({
    Key? key,
    required this.title,
    required this.onLocationSelected,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  String _selectedAddress = 'Tap on map to select location';
  bool _isLoadingAddress = false;

  // Default camera position (New York City)
  static const LatLng _defaultPosition = LatLng(40.7128, -74.0060);

  @override
  void initState() {
    super.initState();

    // Set initial position if provided
    if (widget.initialLocation != null) {
      _selectedPosition = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _selectedAddress = widget.initialLocation!.address;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _selectedPosition ??
                  (widget.initialLocation != null
                      ? LatLng(widget.initialLocation!.latitude,
                          widget.initialLocation!.longitude)
                      : _defaultPosition),
              zoom: 15.0,
            ),
            onTap: _onMapTapped,
            markers: _selectedPosition != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _selectedPosition!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue),
                      infoWindow: InfoWindow(
                        title: widget.title,
                        snippet: _selectedAddress,
                      ),
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 1.h,
                left: 4.w,
                right: 4.w,
                bottom: 2.h,
              ),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 18,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Select ${widget.title}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // My Location Button
          Positioned(
            right: 4.w,
            bottom: 25.h,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _goToCurrentLocation,
                icon: Icon(
                  Icons.my_location,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
            ),
          ),

          // Bottom Card with selected address and confirm button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 12.w,
                      height: 0.5.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Selected address
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.primaryColor
                            .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: AppTheme.lightTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('common.selected_location'.tr(),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.lightTheme.primaryColor,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                if (_isLoadingAddress)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppTheme.lightTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 2.w),
                                      Text('common.getting_address'.tr(),
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: AppTheme
                                              .lightTheme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    _selectedAddress,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: AppTheme
                                          .lightTheme.colorScheme.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3.h),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedPosition != null
                            ? _confirmSelection
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lightTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 3.5.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _selectedPosition != null
                              ? 'Confirm This Location'
                              : 'Select a Location',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position;
      _isLoadingAddress = true;
      _selectedAddress = 'Getting address...';
    });

    _getAddressFromLatLng(position);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        final address = _formatAddress(placemark);

        setState(() {
          _selectedAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress =
              'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
          _isLoadingAddress = false;
        });
      }
    }
  }

  String _formatAddress(geocoding.Placemark placemark) {
    final components = <String>[];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      components.add(placemark.street!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      components.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      components.add(placemark.administrativeArea!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      components.add(placemark.country!);
    }

    return components.join(', ').isNotEmpty
        ? components.join(', ')
        : 'Unknown location';
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.location_permission_denied'.tr()),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 16),
        ),
      );

      _onMapTapped(latLng);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('location.get_current_failed'.tr(args: [e.toString()])),
        ),
      );
    }
  }

  void _confirmSelection() {
    if (_selectedPosition == null) return;

    final location = Location(
      address: _selectedAddress,
      latitude: _selectedPosition!.latitude,
      longitude: _selectedPosition!.longitude,
      city: _extractCityFromAddress(_selectedAddress),
      country: _extractCountryFromAddress(_selectedAddress),
    );

    widget.onLocationSelected(location);
    Navigator.pop(context);
  }

  String? _extractCityFromAddress(String address) {
    final parts = address.split(', ');
    if (parts.length >= 2) {
      return parts[parts.length - 3].trim();
    }
    return null;
  }

  String? _extractCountryFromAddress(String address) {
    final parts = address.split(', ');
    if (parts.isNotEmpty) {
      return parts.last.trim();
    }
    return null;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// Location Search Dialog with Autocomplete
class LocationSearchDialog extends StatefulWidget {
  final Function(Location) onLocationSelected;

  const LocationSearchDialog({
    Key? key,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  final String _googleApiKey = 'AIzaSyC8gJgw5v3LQ2Y7IeTTfWP3ikey-P9xtqI';
  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || query.length < 2) {
      setState(() => _suggestions.clear());
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
          'input=${Uri.encodeComponent(query)}&'
          'key=$_googleApiKey&'
          'types=address&'
          'components=country:us|country:ca|country:gb|country:de|country:fr';

      print('Making request to: $url'); // Debug log

      final response = await http.get(Uri.parse(url));

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;

          setState(() {
            _suggestions = predictions
                .map((pred) => PlaceSuggestion.fromJson(pred))
                .toList();
          });

          print('Found ${_suggestions.length} suggestions'); // Debug log
        } else {
          print(
              'API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          // Show specific error to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'API Error: ${data['status']}\n${data['error_message'] ?? 'Check Google Cloud Console for API setup'}'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error.network'.tr(args: [response.statusCode.toString()])),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error searching places: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error.generic'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectPlace(PlaceSuggestion suggestion) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://maps.googleapis.com/maps/api/place/details/json?'
            'place_id=${suggestion.placeId}&'
            'fields=geometry,formatted_address,address_components&'
            'key=$_googleApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        final geometry = result['geometry']['location'];
        final addressComponents = result['address_components'] as List;

        // Extract city and country from address components
        String? city;
        String? country;
        String? state;
        String? postalCode;

        for (var component in addressComponents) {
          final types = component['types'] as List;
          if (types.contains('locality')) {
            city = component['long_name'];
          } else if (types.contains('administrative_area_level_1')) {
            state = component['long_name'];
          } else if (types.contains('country')) {
            country = component['long_name'];
          } else if (types.contains('postal_code')) {
            postalCode = component['long_name'];
          }
        }

        final location = Location(
          address: result['formatted_address'],
          latitude: geometry['lat'].toDouble(),
          longitude: geometry['lng'].toDouble(),
          city: city,
          state: state,
          country: country,
          postalCode: postalCode,
          placeId: suggestion.placeId,
        );

        widget.onLocationSelected(location);
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('location.select_failed'.tr(args: [e.toString()]))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: 70.h,
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text('common.search_location'.tr(),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Search Field
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'location.enter_address_hint'.tr(),
                prefixIcon: Icon(Icons.search),
                suffixIcon: _isLoading
                    ? Padding(
                        padding: EdgeInsets.all(3.w),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: LiquidLoadingIndicator(size: 20),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.lightTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                // Cancel previous timer
                _debounceTimer?.cancel();

                // Start new timer
                _debounceTimer = Timer(Duration(milliseconds: 300), () {
                  if (mounted && _controller.text == value) {
                    _searchPlaces(value);
                  }
                });
              },
              autofocus: true,
            ),
            SizedBox(height: 2.h),

            // Results
            Expanded(
              child: _suggestions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 2.h),
                          Text('common.start_typing_to_search'.tr(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: AppTheme.lightTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            suggestion.mainText,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            suggestion.secondaryText,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          onTap: () => _selectPlace(suggestion),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// PlaceSuggestion model
class PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullText;

  PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] ?? {};
    return PlaceSuggestion(
      placeId: json['place_id'],
      mainText: structuredFormatting['main_text'] ?? '',
      secondaryText: structuredFormatting['secondary_text'] ?? '',
      fullText: json['description'] ?? '',
    );
  }
}
