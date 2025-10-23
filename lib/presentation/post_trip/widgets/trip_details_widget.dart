import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../../core/app_export.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class TripDetailsWidget extends StatelessWidget {
  final TextEditingController notesController;
  final TransportMode? selectedTransportMode;
  final DateTime departureDate;
  final DateTime? arrivalDate;
  final bool isFlexibleRoute;
  final double? maxDetourKm;
  final Function(TransportMode) onTransportModeChanged;
  final VoidCallback onDepartureDateTap;
  final VoidCallback onArrivalDateTap;
  final Function(bool) onFlexibleRouteChanged;
  final Function(double?) onMaxDetourChanged;

  const TripDetailsWidget({
    Key? key,
    required this.notesController,
    required this.selectedTransportMode,
    required this.departureDate,
    this.arrivalDate,
    required this.isFlexibleRoute,
    this.maxDetourKm,
    required this.onTransportModeChanged,
    required this.onDepartureDateTap,
    required this.onArrivalDateTap,
    required this.onFlexibleRouteChanged,
    required this.onMaxDetourChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Transport Mode Selection
        _buildSectionTitle('Transportation Mode'),
        _buildTransportModeSelector(),

        SizedBox(height: 3.h),

        // Departure Date
        _buildSectionTitle('Travel Dates'),
        _buildDateSelector(
          title: 'post_trip.departure_date'.tr(),
          date: departureDate,
          onTap: onDepartureDateTap,
          icon: 'flight_takeoff',
        ),

        SizedBox(height: 2.h),

        // Arrival Date (Optional)
        _buildDateSelector(
          title: 'trip.arrival_date_optional'.tr(),
          date: arrivalDate,
          onTap: onArrivalDateTap,
          icon: 'flight_land',
          isOptional: true,
        ),

        SizedBox(height: 3.h),

        // Route Flexibility
        _buildSectionTitle('Route Options'),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
            ),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                value: isFlexibleRoute,
                onChanged: (value) => onFlexibleRouteChanged(value ?? false),
                title: Text('common.flexible_route'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'I can make small detours for package pickups/deliveries',
                  style: TextStyle(fontSize: 11.sp),
                ),
                secondary: CustomIconWidget(
                  iconName: 'detail.route'.tr(),
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (isFlexibleRoute) ...[
                SizedBox(height: 2.h),
                TextFormField(
                  initialValue: maxDetourKm?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'trip.max_detour_km'.tr(),
                    hintText: 'e.g., 15',
                    prefixIcon: Icon(Icons.alt_route),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    final detour = double.tryParse(value);
                    onMaxDetourChanged(detour);
                  },
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Notes/Additional Information
        _buildSectionTitle('Additional Notes'),
        TextFormField(
          controller: notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'travel.any_additional_information_about_your_trip_special'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.notes),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppTheme.lightTheme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTransportModeSelector() {
    final transportModes = [
      {'name': 'Flight', 'icon': 'flight', 'mode': TransportMode.flight},
      {'name': 'Train', 'icon': 'train', 'mode': TransportMode.train},
      {'name': 'Bus', 'icon': 'directions_bus', 'mode': TransportMode.bus},
      {'name': 'Car', 'icon': 'directions_car', 'mode': TransportMode.car},
      {
        'name': 'Motorcycle',
        'icon': 'motorcycle',
        'mode': TransportMode.motorcycle
      },
      {'name': 'Ship', 'icon': 'directions_boat', 'mode': TransportMode.ship},
    ];

    return Wrap(
      spacing: 2.w,
      runSpacing: 2.w,
      children: transportModes.map((mode) {
        final isSelected = selectedTransportMode == mode['mode'];

        return InkWell(
          onTap: () => onTransportModeChanged(mode['mode'] as TransportMode),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.outline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: mode['icon'] as String,
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                  size: 18,
                ),
                SizedBox(width: 2.w),
                Text(
                  mode['name'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppTheme.lightTheme.primaryColor
                        : AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
    required String icon,
    bool isOptional = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline,
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.primaryColor,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    date != null
                        ? DateFormat('EEEE, MMM dd, yyyy').format(date)
                        : isOptional
                            ? 'Not specified'
                            : 'Select date',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: date != null
                          ? AppTheme.lightTheme.primaryColor
                          : AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
