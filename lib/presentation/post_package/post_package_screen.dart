import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../../core/app_export.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/image_storage_service.dart';
import './widgets/location_picker_widget.dart';
import './widgets/package_details_widget.dart';
import './widgets/compensation_widget.dart';
import '../../core/validation_messages.dart';
import '../../core/error_recovery_helper.dart';

class PostPackageScreen extends StatefulWidget {
  const PostPackageScreen({Key? key}) : super(key: key);

  @override
  State<PostPackageScreen> createState() => _PostPackageScreenState();
}

class _PostPackageScreenState extends State<PostPackageScreen>
    with TickerProviderStateMixin {
  // Controllers and Form
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Repositories and Services
  final PackageRepository _packageRepository = PackageRepository();
  final FirebaseAuthService _authService = FirebaseAuthService();

  // Form Data
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Step 1: Locations
  Location? _pickupLocation;
  Location? _destinationLocation;

  // Step 2: Package Details
  final TextEditingController _descriptionController = TextEditingController();
  PackageSize _selectedSize = PackageSize.small;
  double _weightKg = 1.0;
  PackageType _selectedType = PackageType.other;
  final TextEditingController _brandController = TextEditingController();
  double? _valueUSD;
  bool _isFragile = false;
  bool _isPerishable = false;
  bool _requiresRefrigeration = false;
  List<File> _packagePhotos = [];

  // Step 3: Delivery Preferences
  DateTime _preferredDeliveryDate = DateTime.now().add(Duration(days: 1));
  bool _isFlexibleDate = false;
  DateTime? _flexibleStartDate;
  DateTime? _flexibleEndDate;
  bool _isUrgent = false;
  List<String> _preferredTransportModes = [];
  final TextEditingController _specialInstructionsController =
      TextEditingController();

  // Step 4: Compensation
  double _compensationOffer = 10.0;
  bool _insuranceRequired = false;
  double? _insuranceValue;

  // State
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
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
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post a Package',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildLocationStep(),
                  _buildPackageDetailsStep(),
                  _buildDeliveryPreferencesStep(),
                  _buildCompensationStep(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.lightTheme.primaryColor
                                : AppTheme.lightTheme.colorScheme.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (index < _totalSteps - 1)
                        Container(
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.only(left: 2.w),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.lightTheme.primaryColor
                                : AppTheme.lightTheme.colorScheme.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 2.h),
          Text(
            _getStepTitle(_currentStep),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _getStepDescription(_currentStep),
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Pickup & Destination';
      case 1:
        return 'Package Details';
      case 2:
        return 'Delivery Preferences';
      case 3:
        return 'Set Compensation';
      default:
        return '';
    }
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 0:
        return 'Where should your package be picked up and delivered?';
      case 1:
        return 'Tell us about your package and upload photos';
      case 2:
        return 'When do you need it delivered and any special requirements?';
      case 3:
        return 'How much are you willing to pay for delivery?';
      default:
        return '';
    }
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationPickerWidget(
            title: 'Pickup Location',
            location: _pickupLocation,
            onLocationSelected: (location) {
              setState(() {
                _pickupLocation = location;
              });
            },
          ),
          LocationPickerWidget(
            title: 'Destination',
            location: _destinationLocation,
            onLocationSelected: (location) {
              setState(() {
                _destinationLocation = location;
              });
            },
          ),
          if (_pickupLocation != null && _destinationLocation != null) ...[
            SizedBox(height: 3.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Distance: ${_calculateDistance().toStringAsFixed(1)} km\nEstimated delivery cost range: \$${(_calculateDistance() * 0.5).toStringAsFixed(0)} - \$${(_calculateDistance() * 1.2).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.lightTheme.primaryColor,
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

  Widget _buildPackageDetailsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: PackageDetailsWidget(
        descriptionController: _descriptionController,
        selectedSize: _selectedSize,
        weightKg: _weightKg,
        selectedType: _selectedType,
        brandController: _brandController,
        valueUSD: _valueUSD,
        isFragile: _isFragile,
        isPerishable: _isPerishable,
        requiresRefrigeration: _requiresRefrigeration,
        packagePhotos: _packagePhotos,
        onSizeChanged: (size) => setState(() => _selectedSize = size),
        onWeightChanged: (weight) => setState(() => _weightKg = weight),
        onTypeChanged: (type) => setState(() => _selectedType = type),
        onValueChanged: (value) => setState(() => _valueUSD = value),
        onFragileChanged: (fragile) => setState(() => _isFragile = fragile),
        onPerishableChanged: (perishable) =>
            setState(() => _isPerishable = perishable),
        onRefrigerationChanged: (refrigeration) =>
            setState(() => _requiresRefrigeration = refrigeration),
        onPhotosChanged: (photos) => setState(() => _packagePhotos = photos),
      ),
    );
  }

  Widget _buildDeliveryPreferencesStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery Date
          _buildSectionTitle('Delivery Date'),
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
                InkWell(
                  onTap: () => _selectDeliveryDate(),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'calendar_today',
                        color: AppTheme.lightTheme.primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preferred Delivery Date',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color:
                                    AppTheme.lightTheme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, MMM dd, yyyy')
                                  .format(_preferredDeliveryDate),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppTheme.lightTheme.primaryColor,
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
                SizedBox(height: 2.h),
                CheckboxListTile(
                  value: _isFlexibleDate,
                  onChanged: (value) {
                    setState(() {
                      _isFlexibleDate = value ?? false;
                      if (_isFlexibleDate) {
                        _flexibleStartDate = _preferredDeliveryDate;
                        _flexibleEndDate =
                            _preferredDeliveryDate.add(Duration(days: 7));
                      } else {
                        _flexibleStartDate = null;
                        _flexibleEndDate = null;
                      }
                    });
                  },
                  title: Text(
                    'I\'m flexible with dates',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Get better matches by allowing date flexibility',
                    style: TextStyle(fontSize: 10.sp),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Transport Modes
          _buildSectionTitle('Preferred Transport'),
          _buildTransportModeSelector(),

          SizedBox(height: 3.h),

          // Special Instructions
          _buildSectionTitle('Special Instructions'),
          TextFormField(
            controller: _specialInstructionsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Any special handling instructions, delivery notes, or requirements...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Urgent Delivery
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
              ),
            ),
            child: CheckboxListTile(
              value: _isUrgent,
              onChanged: (value) => setState(() => _isUrgent = value ?? false),
              title: Text(
                'Urgent Delivery',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Mark as urgent for priority matching (+\$5 fee)',
                style: TextStyle(fontSize: 11.sp),
              ),
              secondary: CustomIconWidget(
                iconName: 'priority_high',
                color: Color(0xFFFF8040),
                size: 24,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompensationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: CompensationWidget(
        compensationOffer: _compensationOffer,
        insuranceRequired: _insuranceRequired,
        insuranceValue: _insuranceValue,
        packageValue: _valueUSD,
        distance: _calculateDistance(),
        onCompensationChanged: (value) =>
            setState(() => _compensationOffer = value),
        onInsuranceChanged: (required) =>
            setState(() => _insuranceRequired = required),
        onInsuranceValueChanged: (value) =>
            setState(() => _insuranceValue = value),
      ),
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
      {'name': 'Flight', 'icon': 'flight', 'value': 'flight'},
      {'name': 'Train', 'icon': 'train', 'value': 'train'},
      {'name': 'Bus', 'icon': 'directions_bus', 'value': 'bus'},
      {'name': 'Car', 'icon': 'directions_car', 'value': 'car'},
    ];

    return Wrap(
      spacing: 2.w,
      runSpacing: 2.w,
      children: transportModes.map((mode) {
        final isSelected = _preferredTransportModes.contains(mode['value']);

        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _preferredTransportModes.remove(mode['value']);
              } else {
                _preferredTransportModes.add(mode['value'] as String);
              }
            });
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

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.only(
        left: 4.w,
        right: 4.w,
        top: 4.w,
        bottom: 4.w + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 3.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 4.w),
          ],
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_currentStep < _totalSteps - 1
                      ? _nextStep
                      : _submitPackage),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.only(top: 3.h, bottom: 4.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep < _totalSteps - 1 ? 'Next' : 'Post Package',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
    });
    _pageController.previousPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        String? locationError =
            ValidationMessages.validateLocation(_pickupLocation, 'pickup');
        if (locationError != null) {
          _showErrorSnackBar(locationError);
          return false;
        }
        locationError = ValidationMessages.validateLocation(
            _destinationLocation, 'destination');
        if (locationError != null) {
          _showErrorSnackBar(locationError);
          return false;
        }
        return true;
      case 1:
        String? descriptionError =
            ValidationMessages.validatePackageDescription(
                _descriptionController.text);
        if (descriptionError != null) {
          _showErrorSnackBar(descriptionError);
          return false;
        }
        return true;
      case 2:
        return true; // All fields are optional or have defaults
      case 3:
        String? compensationError =
            ValidationMessages.validateCompensation(_compensationOffer);
        if (compensationError != null) {
          _showErrorSnackBar(compensationError);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
      ),
    );
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _preferredDeliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _preferredDeliveryDate) {
      setState(() {
        _preferredDeliveryDate = picked;
      });
    }
  }

  double _calculateDistance() {
    if (_pickupLocation == null || _destinationLocation == null) return 0.0;

    return Geolocator.distanceBetween(
          _pickupLocation!.latitude,
          _pickupLocation!.longitude,
          _destinationLocation!.latitude,
          _destinationLocation!.longitude,
        ) /
        1000; // Convert to kilometers
  }

  Future<void> _submitPackage() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _showErrorSnackBar('Please sign in to continue');
        return;
      }

      // Upload photos to base64 storage
      List<String> photoUrls = [];
      if (_packagePhotos.isNotEmpty) {
        try {
          final imageService = ImageStorageService();

          // Show progress for photo processing
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Processing photos...'),
              duration: Duration(seconds: 2),
            ),
          );

          for (int i = 0; i < _packagePhotos.length; i++) {
            final photo = _packagePhotos[i];
            // Compress and convert to base64
            final compressedPhoto = await _compressImage(photo);
            final base64String =
                await imageService.fileToBase64(compressedPhoto);
            photoUrls.add(base64String);

            print('Processed photo ${i + 1}/${_packagePhotos.length}');
          }

          print('Successfully processed ${photoUrls.length} photos');
        } catch (e) {
          _showErrorSnackBar('Failed to process photos: $e');
          return;
        }
      }

      final packageRequest = PackageRequest(
        id: Uuid().v4(),
        senderId: user.uid,
        senderName: user.displayName ?? 'Unknown',
        senderPhotoUrl: user.photoURL ?? '',
        pickupLocation: _pickupLocation!,
        destinationLocation: _destinationLocation!,
        packageDetails: PackageDetails(
          description: _descriptionController.text.trim(),
          size: _selectedSize,
          weightKg: _weightKg,
          type: _selectedType,
          brand: _brandController.text.trim().isNotEmpty
              ? _brandController.text.trim()
              : null,
          valueUSD: _valueUSD,
          isFragile: _isFragile,
          isPerishable: _isPerishable,
          requiresRefrigeration: _requiresRefrigeration,
        ),
        preferredDeliveryDate: _preferredDeliveryDate,
        flexibleDateStart: _flexibleStartDate,
        flexibleDateEnd: _flexibleEndDate,
        compensationOffer: _compensationOffer,
        insuranceRequired: _insuranceRequired,
        insuranceValue: _insuranceValue,
        photoUrls: photoUrls,
        status: PackageStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        specialInstructions:
            _specialInstructionsController.text.trim().isNotEmpty
                ? _specialInstructionsController.text.trim()
                : null,
        isUrgent: _isUrgent,
        preferredTransportModes: _preferredTransportModes,
      );

      final packageId =
          await _packageRepository.createPackageRequest(packageRequest);

      // Show success and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Package posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, packageId);
      }
    } catch (e) {
      if (mounted) {
        ErrorRecoveryHelper.showSubmissionError(
          context,
          'package request',
          e,
          () => _submitPackage(), // Retry function
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Compress image to reduce file size for Firestore storage
  Future<File> _compressImage(File imageFile) async {
    try {
      // Read file stats to determine if compression is needed
      final fileStat = await imageFile.stat();
      final fileSizeInMB = fileStat.size / (1024 * 1024);

      // If file is already small (< 1MB), return original
      if (fileSizeInMB < 1.0) {
        return imageFile;
      }

      // For larger files, we'll still return original for now
      // but log the size so we know compression would be beneficial
      print('Package photo size: ${fileSizeInMB.toStringAsFixed(2)} MB');

      // TODO: Future enhancement - add actual image compression
      // using flutter_image_compress package when needed
      return imageFile;
    } catch (e) {
      print('Error checking image file size: $e');
      return imageFile;
    }
  }
}
