import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class TripCapacityWidget extends StatelessWidget {
  final double maxWeightKg;
  final double maxVolumeLiters;
  final int maxPackages;
  final List<PackageSize> acceptedSizes;
  final List<PackageType> acceptedItemTypes;
  final Function(double) onMaxWeightChanged;
  final Function(double) onMaxVolumeChanged;
  final Function(int) onMaxPackagesChanged;
  final Function(List<PackageSize>) onAcceptedSizesChanged;
  final Function(List<PackageType>) onAcceptedTypesChanged;

  const TripCapacityWidget({
    Key? key,
    required this.maxWeightKg,
    required this.maxVolumeLiters,
    required this.maxPackages,
    required this.acceptedSizes,
    required this.acceptedItemTypes,
    required this.onMaxWeightChanged,
    required this.onMaxVolumeChanged,
    required this.onMaxPackagesChanged,
    required this.onAcceptedSizesChanged,
    required this.onAcceptedTypesChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Capacity Limits
        _buildSectionTitle('Capacity Limits'),
        _buildCapacityInputs(),

        SizedBox(height: 3.h),

        // Accepted Package Sizes
        _buildSectionTitle('Accepted Package Sizes'),
        _buildPackageSizeSelector(),

        SizedBox(height: 3.h),

        // Accepted Item Types
        _buildSectionTitle('Accepted Item Types'),
        _buildItemTypeSelector(),
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

  Widget _buildCapacityInputs() {
    return Container(
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
          // Max Weight
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: maxWeightKg.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max Weight (kg)',
                    hintText: 'e.g., 25',
                    prefixIcon: Icon(Icons.fitness_center),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    final weight = double.tryParse(value) ?? 0.0;
                    onMaxWeightChanged(weight);
                  },
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: TextFormField(
                  initialValue: maxVolumeLiters.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max Volume (L)',
                    hintText: 'e.g., 50',
                    prefixIcon: Icon(Icons.inventory),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    final volume = double.tryParse(value) ?? 0.0;
                    onMaxVolumeChanged(volume);
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Max Packages Count
          TextFormField(
            initialValue: maxPackages.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Maximum Number of Packages',
              hintText: 'e.g., 5',
              prefixIcon: Icon(Icons.inventory_2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              final packages = int.tryParse(value) ?? 1;
              onMaxPackagesChanged(packages);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSizeSelector() {
    final sizes = [
      {
        'name': 'Small',
        'description': 'Fits in pocket/handbag',
        'size': PackageSize.small
      },
      {
        'name': 'Medium',
        'description': 'Shoebox size',
        'size': PackageSize.medium
      },
      {
        'name': 'Large',
        'description': 'Suitcase size',
        'size': PackageSize.large
      },
      {
        'name': 'Extra Large',
        'description': 'Bulky items',
        'size': PackageSize.extraLarge
      },
    ];

    return Column(
      children: sizes.map((sizeData) {
        final size = sizeData['size'] as PackageSize;
        final isSelected = acceptedSizes.contains(size);

        return Container(
          margin: EdgeInsets.only(bottom: 2.w),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              List<PackageSize> newSizes = List.from(acceptedSizes);
              if (value == true) {
                newSizes.add(size);
              } else {
                newSizes.remove(size);
              }
              onAcceptedSizesChanged(newSizes);
            },
            title: Text(
              sizeData['name'] as String,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              sizeData['description'] as String,
              style: TextStyle(fontSize: 11.sp),
            ),
            secondary: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1)
                    : AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.outline,
                ),
              ),
              child: Icon(
                Icons.inventory,
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                size: 20,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemTypeSelector() {
    final itemTypes = [
      {
        'name': 'Documents',
        'icon': Icons.description,
        'type': PackageType.documents
      },
      {
        'name': 'Electronics',
        'icon': Icons.devices,
        'type': PackageType.electronics
      },
      {
        'name': 'Clothing',
        'icon': Icons.checkroom,
        'type': PackageType.clothing
      },
      {'name': 'Books', 'icon': Icons.menu_book, 'type': PackageType.books},
      {'name': 'Food', 'icon': Icons.restaurant, 'type': PackageType.food},
      {'name': 'Gifts', 'icon': Icons.card_giftcard, 'type': PackageType.gifts},
      {
        'name': 'Medicine',
        'icon': Icons.medical_services,
        'type': PackageType.medicine
      },
      {'name': 'Other', 'icon': Icons.category, 'type': PackageType.other},
    ];

    return Wrap(
      spacing: 2.w,
      runSpacing: 2.w,
      children: itemTypes.map((typeData) {
        final type = typeData['type'] as PackageType;
        final isSelected = acceptedItemTypes.contains(type);

        return InkWell(
          onTap: () {
            List<PackageType> newTypes = List.from(acceptedItemTypes);
            if (isSelected) {
              newTypes.remove(type);
            } else {
              newTypes.add(type);
            }
            onAcceptedTypesChanged(newTypes);
          },
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
                Icon(
                  typeData['icon'] as IconData,
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                  size: 18,
                ),
                SizedBox(width: 2.w),
                Text(
                  typeData['name'] as String,
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
}
