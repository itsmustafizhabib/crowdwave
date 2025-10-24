import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/app_export.dart';
import 'package:easy_localization/easy_localization.dart';

class PackageDetailsWidget extends StatefulWidget {
  final TextEditingController descriptionController;
  final PackageSize? selectedSize;
  final double weightKg;
  final PackageType? selectedType;
  final TextEditingController brandController;
  final double? valueUSD;
  final bool isFragile;
  final bool isPerishable;
  final bool requiresRefrigeration;
  final List<File> packagePhotos;
  final Function(PackageSize) onSizeChanged;
  final Function(double) onWeightChanged;
  final Function(PackageType) onTypeChanged;
  final Function(double?) onValueChanged;
  final Function(bool) onFragileChanged;
  final Function(bool) onPerishableChanged;
  final Function(bool) onRefrigerationChanged;
  final Function(List<File>) onPhotosChanged;

  const PackageDetailsWidget({
    Key? key,
    required this.descriptionController,
    required this.selectedSize,
    required this.weightKg,
    required this.selectedType,
    required this.brandController,
    required this.valueUSD,
    required this.isFragile,
    required this.isPerishable,
    required this.requiresRefrigeration,
    required this.packagePhotos,
    required this.onSizeChanged,
    required this.onWeightChanged,
    required this.onTypeChanged,
    required this.onValueChanged,
    required this.onFragileChanged,
    required this.onPerishableChanged,
    required this.onRefrigerationChanged,
    required this.onPhotosChanged,
  }) : super(key: key);

  @override
  State<PackageDetailsWidget> createState() => _PackageDetailsWidgetState();
}

class _PackageDetailsWidgetState extends State<PackageDetailsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ImagePicker _imagePicker = ImagePicker();

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
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package Description
            _buildSectionTitle('Package Description', Icons.description),
            _buildDescriptionField(),

            SizedBox(height: 4.h),

            // Package Photos
            _buildSectionTitle('Package Photos', Icons.photo_camera),
            _buildPhotoSection(),

            SizedBox(height: 4.h),

            // Package Type & Size
            _buildSectionTitle('Package Details', Icons.inventory_2),
            _buildPackageTypeSelector(),
            SizedBox(height: 3.h),
            _buildPackageSizeSelector(),

            SizedBox(height: 4.h),

            // Weight & Value
            _buildSectionTitle('Weight & Value', Icons.scale),
            _buildWeightAndValueSection(),

            SizedBox(height: 4.h),

            // Special Handling
            _buildSectionTitle('Special Handling', Icons.warning_amber),
            _buildSpecialHandlingOptions(),

            SizedBox(height: 4.h),

            // Brand/Store (Optional)
            _buildSectionTitle('Brand/Store (Optional)', Icons.store),
            _buildBrandField(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: TextFormField(
        controller: widget.descriptionController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText:
              'Describe your package in detail (e.g., iPhone 15 Pro in original box, documents in sealed envelope, etc.)',
          hintStyle: TextStyle(
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.5),
            fontSize: 12.sp,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(4.w),
        ),
        style: TextStyle(
          fontSize: 14.sp,
          color: AppTheme.lightTheme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('post_package.upload_clear_photos_of_your_package'.tr(),
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 2.h),

          // Photo grid
          if (widget.packagePhotos.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2.w,
                mainAxisSpacing: 2.w,
                childAspectRatio: 1,
              ),
              itemCount: widget.packagePhotos.length +
                  (widget.packagePhotos.length < 6 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == widget.packagePhotos.length) {
                  return _buildAddPhotoButton();
                }
                return _buildPhotoCard(widget.packagePhotos[index], index);
              },
            ),
          ] else ...[
            _buildAddPhotoButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _showPhotoOptions,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              color: AppTheme.lightTheme.primaryColor,
              size: 28,
            ),
            SizedBox(height: 1.h),
            Text('common.add_photo'.tr(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(File photo, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(photo),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Remove button
        Positioned(
          top: 1.w,
          right: 1.w,
          child: InkWell(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageTypeSelector() {
    final types = [
      {
        'type': PackageType.documents,
        'label': 'Documents',
        'icon': Icons.description
      },
      {
        'type': PackageType.electronics,
        'label': 'Electronics',
        'icon': Icons.smartphone
      },
      {
        'type': PackageType.clothing,
        'label': 'Clothing',
        'icon': Icons.checkroom
      },
      {'type': PackageType.food, 'label': 'Food', 'icon': Icons.restaurant},
      {
        'type': PackageType.medicine,
        'label': 'Medicine',
        'icon': Icons.medical_services
      },
      {
        'type': PackageType.gifts,
        'label': 'Gifts',
        'icon': Icons.card_giftcard
      },
      {'type': PackageType.books, 'label': 'Books', 'icon': Icons.menu_book},
      {
        'type': PackageType.cosmetics,
        'label': 'Cosmetics',
        'icon': Icons.face_retouching_natural
      },
      {'type': PackageType.other, 'label': 'Other', 'icon': Icons.category},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('post_package.package_type'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 2.w,
          children: types.map((typeData) {
            final isSelected = widget.selectedType == typeData['type'];

            return InkWell(
              onTap: () =>
                  widget.onTypeChanged(typeData['type'] as PackageType),
              borderRadius: BorderRadius.circular(12),
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
                        : AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.3),
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
                      typeData['label'] as String,
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
        ),
      ],
    );
  }

  Widget _buildPackageSizeSelector() {
    final sizes = [
      {
        'size': PackageSize.small,
        'label': 'Small',
        'description': 'Fits in pocket/small bag\n(Phone, documents)',
        'icon': Icons.smartphone,
      },
      {
        'size': PackageSize.medium,
        'label': 'Medium',
        'description': 'Shoebox size\n(Shoes, books)',
        'icon': Icons.inventory,
      },
      {
        'size': PackageSize.large,
        'label': 'Large',
        'description': 'Suitcase space required\n(Laptop, clothes)',
        'icon': Icons.luggage,
      },
      {
        'size': PackageSize.extraLarge,
        'label': 'Extra Large',
        'description': 'Special arrangement\n(Large electronics)',
        'icon': Icons.monitor,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('post_package.package_size'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Column(
          children: sizes.map((sizeData) {
            final isSelected = widget.selectedSize == sizeData['size'];

            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              child: InkWell(
                onTap: () =>
                    widget.onSizeChanged(sizeData['size'] as PackageSize),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.primaryColor
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.primaryColor
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.lightTheme.primaryColor
                                  .withValues(alpha: 0.2)
                              : AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          sizeData['icon'] as IconData,
                          color: isSelected
                              ? AppTheme.lightTheme.primaryColor
                              : AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sizeData['label'] as String,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.lightTheme.primaryColor
                                    : AppTheme.lightTheme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              sizeData['description'] as String,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppTheme.lightTheme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.lightTheme.primaryColor,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWeightAndValueSection() {
    return Row(
      children: [
        // Weight
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('post_package.weight_label'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${widget.weightKg.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                    Slider(
                      value: widget.weightKg,
                      min: 0.1,
                      max: 30.0,
                      divisions: 299,
                      onChanged: widget.onWeightChanged,
                      activeColor: AppTheme.lightTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: 4.w),

        // Value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Value (EUR)',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: TextFormField(
                  initialValue: widget.valueUSD?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'common.optional'.tr(),
                    prefixText: '€ ',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(3.w),
                  ),
                  onChanged: (value) {
                    final doubleValue = double.tryParse(value);
                    widget.onValueChanged(doubleValue);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialHandlingOptions() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildHandlingOption(
            icon: Icons.warning,
            title: 'package.fragile'.tr(),
            subtitle: 'package.fragile_desc'.tr(),
            value: widget.isFragile,
            onChanged: widget.onFragileChanged,
            color: Colors.orange,
          ),
          Divider(height: 3.h),
          _buildHandlingOption(
            icon: Icons.schedule,
            title: 'package.perishable'.tr(),
            subtitle: 'package.perishable_desc'.tr(),
            value: widget.isPerishable,
            onChanged: widget.onPerishableChanged,
            color: Colors.red,
          ),
          Divider(height: 3.h),
          _buildHandlingOption(
            icon: Icons.ac_unit,
            title: 'package.requires_refrigeration'.tr(),
            subtitle: 'package.refrigeration_desc'.tr(),
            value: widget.requiresRefrigeration,
            onChanged: widget.onRefrigerationChanged,
            color: Color(0xFF008080),
          ),
        ],
      ),
    );
  }

  Widget _buildHandlingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
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
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
        ),
      ],
    );
  }

  Widget _buildBrandField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: TextFormField(
        controller: widget.brandController,
        decoration: InputDecoration(
          hintText: 'e.g., Apple, Nike, Amazon, Local Store...',
          prefixIcon: Icon(Icons.store),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(4.w),
        ),
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),

            // Title
            Text('post_package.add_package_photo'.tr(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),

            // Camera option
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
              title: Text('common.take_photo'.tr()),
              subtitle: Text('package.take_photo_desc'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),

            // Gallery option
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_library,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
              title: Text('common.choose_from_gallery'.tr()),
              subtitle: Text('common.select_photo_desc'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        final List<File> updatedPhotos = List.from(widget.packagePhotos);
        updatedPhotos.add(File(image.path));
        widget.onPhotosChanged(updatedPhotos);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('image.pick_failed'.tr(args: [e.toString()]))),
      );
    }
  }

  void _removePhoto(int index) {
    final List<File> updatedPhotos = List.from(widget.packagePhotos);
    updatedPhotos.removeAt(index);
    widget.onPhotosChanged(updatedPhotos);
  }
}
