import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/firebase_auth_service.dart';
import '../../core/error_handler.dart';
import '../post_package/widgets/location_picker_widget.dart';
import './widgets/trip_details_widget.dart';
import './widgets/trip_capacity_widget.dart';
import './widgets/trip_compensation_widget.dart';

class PostTripScreen extends StatefulWidget {
  const PostTripScreen({Key? key}) : super(key: key);

  @override
  State<PostTripScreen> createState() => _PostTripScreenState();
}

class _PostTripScreenState extends State<PostTripScreen>
    with TickerProviderStateMixin {
  // Controllers and Form
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Repositories and Services
  final TripRepository _tripRepository = TripRepository();
  final FirebaseAuthService _authService = FirebaseAuthService();

  // Form Data
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Step 1: Locations
  Location? _departureLocation;
  Location? _destinationLocation;

  // Step 2: Trip Details
  final TextEditingController _notesController = TextEditingController();
  TransportMode _selectedTransportMode = TransportMode.flight;
  DateTime _departureDate = DateTime.now().add(Duration(days: 1));
  DateTime? _arrivalDate;
  bool _isFlexibleRoute = false;
  double? _maxDetourKm;

  // Step 3: Capacity
  double _maxWeightKg = 10.0;
  double _maxVolumeLiters = 20.0;
  int _maxPackages = 3;
  List<PackageSize> _acceptedSizes = [PackageSize.small, PackageSize.medium];
  List<PackageType> _acceptedItemTypes = [
    PackageType.documents,
    PackageType.electronics
  ];

  // Step 4: Compensation
  double _suggestedReward = 25.0;

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
    _notesController.dispose();
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
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            _buildProgressIndicator(),

            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _buildLocationStep(),
                    _buildTripDetailsStep(),
                    _buildCapacityStep(),
                    _buildCompensationStep(),
                  ],
                ),
              ),
            ),

            // Navigation Buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Post a Trip',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (index < _totalSteps - 1) SizedBox(width: 2.w),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Departure Location
          LocationPickerWidget(
            title: 'Departure Location',
            subtitle: 'Where are you starting your journey?',
            location: _departureLocation,
            onLocationSelected: (location) =>
                setState(() => _departureLocation = location),
            prefixIcon: Icons.flight_takeoff,
          ),

          SizedBox(height: 3.h),

          // Destination Location
          LocationPickerWidget(
            title: 'Destination Location',
            subtitle: 'Where are you going?',
            location: _destinationLocation,
            onLocationSelected: (location) =>
                setState(() => _destinationLocation = location),
            prefixIcon: Icons.flight_land,
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: TripDetailsWidget(
        notesController: _notesController,
        selectedTransportMode: _selectedTransportMode,
        departureDate: _departureDate,
        arrivalDate: _arrivalDate,
        isFlexibleRoute: _isFlexibleRoute,
        maxDetourKm: _maxDetourKm,
        onTransportModeChanged: (mode) =>
            setState(() => _selectedTransportMode = mode),
        onDepartureDateTap: _selectDepartureDate,
        onArrivalDateTap: _selectArrivalDate,
        onFlexibleRouteChanged: (flexible) =>
            setState(() => _isFlexibleRoute = flexible),
        onMaxDetourChanged: (detour) => setState(() => _maxDetourKm = detour),
      ),
    );
  }

  Widget _buildCapacityStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: TripCapacityWidget(
        maxWeightKg: _maxWeightKg,
        maxVolumeLiters: _maxVolumeLiters,
        maxPackages: _maxPackages,
        acceptedSizes: _acceptedSizes,
        acceptedItemTypes: _acceptedItemTypes,
        onMaxWeightChanged: (weight) => setState(() => _maxWeightKg = weight),
        onMaxVolumeChanged: (volume) =>
            setState(() => _maxVolumeLiters = volume),
        onMaxPackagesChanged: (packages) =>
            setState(() => _maxPackages = packages),
        onAcceptedSizesChanged: (sizes) =>
            setState(() => _acceptedSizes = sizes),
        onAcceptedTypesChanged: (types) =>
            setState(() => _acceptedItemTypes = types),
      ),
    );
  }

  Widget _buildCompensationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: TripCompensationWidget(
        suggestedReward: _suggestedReward,
        onRewardChanged: (reward) => setState(() => _suggestedReward = reward),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(4.w),
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
                  : (_currentStep < _totalSteps - 1 ? _nextStep : _submitTrip),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 3.h),
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
                      _currentStep < _totalSteps - 1 ? 'Next' : 'Post Trip',
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
        if (_departureLocation == null || _destinationLocation == null) {
          _showErrorSnackBar(
              'Please select both departure and destination locations');
          return false;
        }
        return true;
      case 1:
        if (_departureDate.isBefore(DateTime.now())) {
          _showErrorSnackBar('Departure date cannot be in the past');
          return false;
        }
        return true;
      case 2:
        if (_acceptedSizes.isEmpty) {
          _showErrorSnackBar(
              'Please select at least one accepted package size');
          return false;
        }
        if (_acceptedItemTypes.isEmpty) {
          _showErrorSnackBar('Please select at least one accepted item type');
          return false;
        }
        return true;
      case 3:
        if (_suggestedReward <= 0) {
          _showErrorSnackBar('Please set a valid reward amount');
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
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _selectDepartureDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _departureDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _departureDate) {
      setState(() {
        _departureDate = picked;
        // Reset arrival date if it's before departure
        if (_arrivalDate != null && _arrivalDate!.isBefore(_departureDate)) {
          _arrivalDate = null;
        }
      });
    }
  }

  Future<void> _selectArrivalDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _arrivalDate ?? _departureDate.add(Duration(days: 1)),
      firstDate: _departureDate,
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _arrivalDate = picked;
      });
    }
  }

  Future<void> _submitTrip() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = _authService.currentUser;
      if (user == null) {
        _showErrorSnackBar('Please sign in to continue');
        return;
      }

      // Create TravelTrip object
      final travelTrip = TravelTrip(
        id: '', // Will be set by Firestore
        travelerId: user.uid,
        travelerName: user.displayName ?? 'Unknown',
        travelerPhotoUrl: user.photoURL ?? '',
        departureLocation: _departureLocation!,
        destinationLocation: _destinationLocation!,
        departureDate: _departureDate,
        arrivalDate: _arrivalDate,
        transportMode: _selectedTransportMode,
        capacity: TripCapacity(
          maxWeightKg: _maxWeightKg,
          maxVolumeLiters: _maxVolumeLiters,
          maxPackages: _maxPackages,
          acceptedSizes: _acceptedSizes,
        ),
        suggestedReward: _suggestedReward,
        acceptedItemTypes: _acceptedItemTypes,
        status: TripStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        isFlexibleRoute: _isFlexibleRoute,
        maxDetourKm: _maxDetourKm,
      );

      final tripId = await _tripRepository.createTravelTrip(travelTrip);

      // Show success and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, tripId);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(ErrorHandler.getReadableError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
