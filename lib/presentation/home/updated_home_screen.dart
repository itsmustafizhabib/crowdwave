import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../../core/app_export.dart';
import '../../services/auth_state_service.dart';
// import '../../services/notification_service.dart'; // Removed - bell icon removed from home screen
import '../../services/kyc_service.dart';
import '../../controllers/smart_matching_controller.dart';
import '../package_detail/package_detail_screen.dart';
import '../../widgets/liquid_refresh_indicator.dart';
import '../../widgets/liquid_loading_indicator.dart';

// Removed unused notification screen import
import '../../widgets/trip_card_widget.dart';

class UpdatedHomeScreen extends StatefulWidget {
  const UpdatedHomeScreen({Key? key}) : super(key: key);

  @override
  State<UpdatedHomeScreen> createState() => _UpdatedHomeScreenState();
}

class _UpdatedHomeScreenState extends State<UpdatedHomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // 'Sender' or 'Traveler'
  bool _showOnlyMyPackages =
      false; // Toggle to show only user's own packages/trips
  final AuthStateService _authService = AuthStateService();
  final PackageRepository _packageRepository = PackageRepository();
  final TripRepository _tripRepository = TripRepository();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _airplaneController;
  final TextEditingController _searchController = TextEditingController();

  // Smart matching controller
  late SmartMatchingController _smartMatchingController;
  // late NotificationService _notificationService; // Removed - bell icon removed from home screen

  // KYC related
  final KycService _kycService = KycService();
  bool _hasSubmittedKyc = false;
  bool _isKycCheckLoading = true;

  // Real data streams
  Stream<List<PackageRequest>>? _packagesStream;
  Stream<List<TravelTrip>>? _tripsStream;

  @override
  void initState() {
    super.initState();

    // Initialize airplane animation controller
    _airplaneController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Add app lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Initialize smart matching controller
    _smartMatchingController = Get.put(SmartMatchingController());

    // Initialize notification service - REMOVED since bell icon removed from home screen
    // _notificationService = Get.put(NotificationService());

    // Listen to auth state changes to update UI when user data changes
    _authService.addListener(_onAuthStateChanged);

    // Initialize data streams
    _initializeDataStreams();

    // Check KYC status on initialization
    _checkKycStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _forceRefreshStreams();
    }
  }

  void _initializeDataStreams() {
    final currentUserId = _authService.currentUser?.uid ?? '';

    if (_showOnlyMyPackages) {
      // Get user's own packages and trips
      _packagesStream = _packageRepository.getPackagesBySender(currentUserId);
      _tripsStream = _tripRepository.getTripsByTraveler(currentUserId);
    } else {
      // Get all recent packages and trips for discovery
      _packagesStream =
          _packageRepository.getRecentPackages(limit: 50); // Increased limit
      _tripsStream =
          _tripRepository.getRecentTrips(limit: 50); // Increased limit
    }

    // Load initial data for smart matching controller
    _smartMatchingController.loadSuggestedTrips();
    _smartMatchingController.loadSuggestedPackages();
  }

  // Method to force refresh data streams
  void _forceRefreshStreams() {
    if (mounted) {
      setState(() {
        _initializeDataStreams();
      });
      // Also refresh smart matching controller
      _smartMatchingController.loadSuggestedTrips();
      _smartMatchingController.loadSuggestedPackages();
    }
  }

  void _onAuthStateChanged() {
    // Rebuild the widget when auth state changes and refresh streams
    if (mounted) {
      _initializeDataStreams(); // Refresh streams when user changes
      _checkKycStatus(); // Check KYC status when auth state changes
      setState(() {});
    }
  }

  Future<void> _checkKycStatus() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      setState(() {
        _hasSubmittedKyc = false;
        _isKycCheckLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isKycCheckLoading = true;
      });

      // Check if user has submitted KYC
      final hasSubmitted = await _kycService.hasSubmittedKyc(currentUser.uid);

      setState(() {
        _hasSubmittedKyc = hasSubmitted;
        _isKycCheckLoading = false;
      });
    } catch (e) {
      print('Error checking KYC status: $e');
      setState(() {
        _hasSubmittedKyc = false;
        _isKycCheckLoading = false;
      });
    }
  }

  @override
  void dispose() {
    try {
      print('🧹 UpdatedHomeScreen: Starting enhanced disposal...');

      // Remove observers first
      WidgetsBinding.instance.removeObserver(this);
      _authService.removeListener(_onAuthStateChanged);

      _searchFocusNode.dispose();
      _searchController.dispose();
      _airplaneController.dispose();

      // Clear any cached data
      imageCache.clear();

      print('✅ UpdatedHomeScreen: Enhanced disposal completed');
    } catch (e) {
      print('❌ UpdatedHomeScreen disposal error: $e');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFE9E9E9), // Light grey background
        body: SafeArea(
          top: false, // Let content go under status bar for immersive feel
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Add top padding for status bar area
                SizedBox(height: MediaQuery.of(context).padding.top),

                // Blue header with profile and search
                _buildHeader(),

                // Role toggle (Sender/Traveler)

                // Filter toggle (All vs My items)
                _buildFilterToggle(),

                // KYC Alert Banner
                _buildKYCBanner(),

                // Swipeable Cards
                _buildSwipeableCards(),

                // Additional content area (optional)
                SizedBox(height: 20), // Reduced padding for FAB
              ],
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: _CustomFloatingActionButtonLocation(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0046FF), Color(0xFF001BB7)], // Blue gradient
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with profile and menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildUserAvatar(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getUserGreeting(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Find available packages',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notification Bell with Badge - REMOVED per user request
                      // Users can access notifications through the main menu instead

                      IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                        tooltip: 'Menu',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search packages',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    icon: Icon(
                      Icons.search,
                      color: Color(0xFF0046FF),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                // Trigger rebuild to clear search filter
                              });
                            },
                          )
                        : null,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  cursorColor: const Color(0xFF0046FF),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  onChanged: (value) {
                    setState(() {
                      // Trigger rebuild to apply search filter
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildRoleToggle() {
  //   return Padding(
  //     padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
  //     child: Container(
  //       height: 50, // Fixed height to prevent overflow
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(25),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.05),
  //             blurRadius: 4,
  //             offset: const Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       padding: EdgeInsets.all(4),
  //       child: Row(
  //         children: [
  //           Expanded(
  //             child: GestureDetector(
  //               onTap: () {
  //                 setState(() {
  //                   _currentRole = 'Sender';
  //                 });
  //                 _pageController.animateToPage(
  //                   0,
  //                   duration: Duration(milliseconds: 300),
  //                   curve: Curves.easeInOut,
  //                 );
  //               },
  //               child: Container(
  //                 decoration: BoxDecoration(
  //                   color: _currentRole == 'Sender'
  //                       ? Color(0xFF0046FF)
  //                       : Colors.transparent,
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //                 child: Center(
  //                   child: Text(
  //                     'Sender',
  //                     style: TextStyle(
  //                       color: _currentRole == 'Sender'
  //                           ? Colors.white
  //                           : Colors.black,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //           Expanded(
  //             child: GestureDetector(
  //               onTap: () {
  //                 setState(() {
  //                   _currentRole = 'Traveler';
  //                 });
  //                 _pageController.animateToPage(
  //                   1,
  //                   duration: Duration(milliseconds: 300),
  //                   curve: Curves.easeInOut,
  //                 );
  //               },
  //               child: Container(
  //                 decoration: BoxDecoration(
  //                   color: _currentRole == 'Traveler'
  //                       ? Color(0xFF0046FF)
  //                       : Colors.transparent,
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //                 child: Center(
  //                   child: Text(
  //                     'Traveler',
  //                     style: TextStyle(
  //                       color: _currentRole == 'Traveler'
  //                           ? Colors.white
  //                           : Colors.black,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildFilterToggle() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 3, 20, 2),
      child: Row(
        children: [
          SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Color(0xFF0046FF).withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.all(2),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showOnlyMyPackages = false;
                          _initializeDataStreams(); // Refresh streams
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_showOnlyMyPackages
                              ? Color(0xFF0046FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'All Items',
                            style: TextStyle(
                              color: !_showOnlyMyPackages
                                  ? Colors.white
                                  : Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showOnlyMyPackages = true;
                          _initializeDataStreams(); // Refresh streams
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _showOnlyMyPackages
                              ? Color(0xFF0046FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'My Items',
                            style: TextStyle(
                              color: _showOnlyMyPackages
                                  ? Colors.white
                                  : Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKYCBanner() {
    // Don't show banner if user has already submitted KYC or if we're still loading
    if (_hasSubmittedKyc || _isKycCheckLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 2, 20, 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8040), // Orange
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_rounded,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Complete your KYC to start earning',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final result =
                  await Navigator.pushNamed(context, AppRoutes.kycCompletion);
              // Check KYC status again when returning from KYC screen
              if (result == true) {
                _checkKycStatus();
              }
            },
            child: const Text(
              'Complete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Replace the _buildSwipeableCards() method with:
  Widget _buildSwipeableCards() {
    return _showOnlyMyPackages
        ? _buildMyPackagesListView()
        : _buildPackagesListView();
  }

  Widget _buildTripsListView() {
    return Column(
      children: [
        // Smart Matching Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(_showOnlyMyPackages ? Icons.person : Icons.smart_toy,
                  color: Color(0xFF0046FF), size: 20),
              SizedBox(width: 8),
              Text(
                _showOnlyMyPackages ? 'My Trips' : 'Recommended Travelers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0046FF),
                ),
              ),
              Spacer(),
              if (!_showOnlyMyPackages) GestureDetector(),
            ],
          ),
        ),
        // Real-time Streaming Trips
        Expanded(
          child: LiquidRefreshIndicator(
            onRefresh: () async {
              _forceRefreshStreams();
              await Future.delayed(
                  Duration(milliseconds: 500)); // Small delay for user feedback
            },
            child: StreamBuilder<List<TravelTrip>>(
              stream: _tripsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CenteredLiquidLoading();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text('Error loading trips',
                            style: TextStyle(color: Colors.red)),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initializeDataStreams(); // Refresh streams
                            });
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final trips = snapshot.data ?? [];
                final currentUserId = _authService.currentUser?.uid ?? '';
                final searchText = _searchController.text.toLowerCase().trim();

                // Apply filtering based on toggle
                List<TravelTrip> filteredTrips;
                if (_showOnlyMyPackages) {
                  // Show only current user's trips
                  filteredTrips = trips
                      .where((trip) => trip.travelerId == currentUserId)
                      .take(10)
                      .toList();
                } else {
                  // Show all trips except current user's own trips and show only active trips
                  filteredTrips = trips
                      .where((trip) =>
                          trip.travelerId != currentUserId &&
                          trip.status == TripStatus.active)
                      .take(10)
                      .toList();
                }

                // Apply search filter if search text is provided
                if (searchText.isNotEmpty) {
                  filteredTrips = filteredTrips.where((trip) {
                    final fromLocation =
                        trip.departureLocation.address.toLowerCase();
                    final toLocation =
                        trip.destinationLocation.address.toLowerCase();
                    final travelerName = trip.travelerName.toLowerCase();
                    final departureCity =
                        (trip.departureLocation.city ?? '').toLowerCase();
                    final destinationCity =
                        (trip.destinationLocation.city ?? '').toLowerCase();

                    return fromLocation.contains(searchText) ||
                        toLocation.contains(searchText) ||
                        travelerName.contains(searchText) ||
                        departureCity.contains(searchText) ||
                        destinationCity.contains(searchText);
                  }).toList();
                }

                if (filteredTrips.isEmpty) {
                  return _buildEmptyCardsList('trip');
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredTrips.length,
                  itemBuilder: (context, index) {
                    return TripCardWidget(
                      trip: filteredTrips[index],
                      index: index,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackagesListView() {
    return Column(
      children: [
        // Real-time Streaming Packages
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: LiquidRefreshIndicator(
            onRefresh: () async {
              _forceRefreshStreams();
              await Future.delayed(
                  Duration(milliseconds: 500)); // Small delay for user feedback
            },
            child: StreamBuilder<List<PackageRequest>>(
              stream: _packagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CenteredLiquidLoading();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text('Error loading packages',
                            style: TextStyle(color: Colors.red)),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initializeDataStreams(); // Refresh streams
                            });
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final packages = snapshot.data ?? [];
                final currentUserId = _authService.currentUser?.uid ?? '';
                final searchText = _searchController.text.toLowerCase().trim();

                // Apply filtering based on toggle
                List<PackageRequest> filteredPackages;
                if (_showOnlyMyPackages) {
                  // Show only current user's packages
                  filteredPackages = packages
                      .where((package) => package.senderId == currentUserId)
                      .take(10)
                      .toList();
                } else {
                  // Show all packages except current user's own packages and show only pending packages
                  filteredPackages = packages
                      .where((package) =>
                          package.senderId != currentUserId &&
                          package.status == PackageStatus.pending)
                      .take(10)
                      .toList();
                }

                // Apply search filter if search text is provided
                if (searchText.isNotEmpty) {
                  filteredPackages = filteredPackages.where((package) {
                    final pickupLocation =
                        package.pickupLocation.address.toLowerCase();
                    final destinationLocation =
                        package.destinationLocation.address.toLowerCase();
                    final senderName = package.senderName.toLowerCase();
                    final description =
                        package.packageDetails.description.toLowerCase();
                    final pickupCity =
                        (package.pickupLocation.city ?? '').toLowerCase();
                    final destinationCity =
                        (package.destinationLocation.city ?? '').toLowerCase();

                    return pickupLocation.contains(searchText) ||
                        destinationLocation.contains(searchText) ||
                        senderName.contains(searchText) ||
                        description.contains(searchText) ||
                        pickupCity.contains(searchText) ||
                        destinationCity.contains(searchText);
                  }).toList();
                }

                if (filteredPackages.isEmpty) {
                  return _buildEmptyCardsList('package');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(20, 5, 20, 0),
                  itemCount: filteredPackages.length,
                  itemBuilder: (context, index) {
                    return _buildSmartPackageCard(
                        filteredPackages[index], index);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Modern Package Card with enhanced UI
  Widget _buildSmartPackageCard(PackageRequest package, int index) {
    final statusInfo = _getSmartPackageStatus(package);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PackageDetailScreen(package: package),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFFAFAFA),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFE5E5E5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with sender info and status
                    Row(
                      children: [
                        // Package type icon with gradient background
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFF8040),
                                Color(0xFFFF6020),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF8040).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getPackageTypeIcon(package.packageDetails.type),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        // Sender info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                package.senderName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                package.packageDetails.description.isNotEmpty
                                    ? package.packageDetails.description
                                    : 'Package delivery',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Smart status badge
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusInfo['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusInfo['color'].withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusInfo['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                statusInfo['text'],
                                style: TextStyle(
                                  color: statusInfo['color'],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Route section with modern design
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFFE2E8F0), width: 1),
                      ),
                      child: Row(
                        children: [
                          // From location
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FROM',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  package.pickupLocation.city ??
                                      package.pickupLocation.address
                                          .split(',')
                                          .first,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Animated airplane indicator
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 12),
                            width: 50,
                            height: 24,
                            child: Center(
                              child: AnimatedBuilder(
                                animation: _airplaneController,
                                builder: (context, child) {
                                  final double animationValue =
                                      _airplaneController.value;

                                  // Subtle vertical floating effect only
                                  final double verticalOffset =
                                      math.sin(animationValue * 2 * math.pi) *
                                          2.0;

                                  return Transform.translate(
                                    offset: Offset(0, verticalOffset),
                                    child: Transform.rotate(
                                      angle: math.pi / 2, // 90 degree rotation
                                      child: Icon(
                                        Icons.flight,
                                        size: 40, // Doubled from 20 to 40
                                        color: Color(
                                            0xFF4B5563), // Dark grey color
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // To location
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'TO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  package.destinationLocation.city ??
                                      package.destinationLocation.address
                                          .split(',')
                                          .first,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Bottom row with date and price
                    Row(
                      children: [
                        // Date info
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF6B7280),
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                _formatDate(package.preferredDeliveryDate),
                                style: TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Spacer(),

                        // Price with enhanced styling
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF0046FF),
                                Color(0xFF0037CC),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF0046FF).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '€${package.compensationOffer}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Subtle accent line at the top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFF8040),
                        Color(0xFF0046FF),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Unused legacy methods - kept for potential future use
  // ignore: unused_element

  // ignore: unused_element
  Widget _buildPackageCard(PackageRequest package) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PackageDetailScreen(package: package),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
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
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF0046FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      color: Color(0xFF0046FF),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      package.packageDetails.description,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildPackageStatusIndicator(package.status),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.grey,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${package.pickupLocation.city ?? package.pickupLocation.address} → ${package.destinationLocation.city ?? package.destinationLocation.address}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${package.compensationOffer.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0046FF),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF0046FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripStatusIndicator(TripStatus status) {
    Color statusColor;
    String statusText;

    switch (status) {
      case TripStatus.active:
        statusColor = Colors.green;
        statusText = 'Active';
        break;
      case TripStatus.full:
        statusColor = Colors.orange;
        statusText = 'Full';
        break;
      case TripStatus.inProgress:
        statusColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case TripStatus.completed:
        statusColor = Colors.green[700]!;
        statusText = 'Completed';
        break;
      case TripStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageStatusIndicator(PackageStatus status) {
    Color statusColor;
    String statusText;

    switch (status) {
      case PackageStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case PackageStatus.matched:
        statusColor = Colors.blue;
        statusText = 'Matched';
        break;
      case PackageStatus.confirmed:
        statusColor = Colors.green;
        statusText = 'Confirmed';
        break;
      case PackageStatus.delivered:
        statusColor = Colors.green[700]!;
        statusText = 'Delivered';
        break;
      case PackageStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCardsList(String type) {
    String title, subtitle;

    if (type == 'package') {
      if (_showOnlyMyPackages) {
        title = 'No packages yet';
        subtitle = 'Post a package to get started';
      } else {
        title = 'No available packages';
        subtitle = 'Check back later or switch to "My Items" view';
      }
    } else {
      if (_showOnlyMyPackages) {
        title = 'No trips yet';
        subtitle = 'Post a trip to get started';
      } else {
        title = 'No available trips';
        subtitle = 'Check back later or switch to "My Items" view';
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'package' ? Icons.inbox : Icons.flight_takeoff,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () async {
        // Always navigate to post package since we're removing traveler role
        final result =
            await Navigator.pushNamed(context, AppRoutes.postPackage);
        if (result != null && mounted) {
          _forceRefreshStreams();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Package posted!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      backgroundColor: Color(0xFF0046FF),
      foregroundColor: Colors.white,
      elevation: 6,
      icon: Icon(Icons.add),
      label: Text(
        'Post Package',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    final user = _authService.currentUser;

    if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      // User has a profile photo (from Google/Apple login)
      return CircleAvatar(
        radius: 25,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: user.photoURL!,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            placeholder: (context, url) => LiquidLoadingIndicator(
              size: 50,
              color: Color(0xFF0046FF),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.person,
              color: Color(0xFF0046FF),
              size: 30,
            ),
          ),
        ),
      );
    } else {
      // No profile photo, show default avatar with user's initials or icon
      return CircleAvatar(
        radius: 25,
        backgroundColor: Colors.white,
        child: Text(
          _getUserInitials(),
          style: const TextStyle(
            color: Color(0xFF0046FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }

  String _getUserGreeting() {
    final user = _authService.currentUser;

    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      // Use display name (especially for Google/Apple login)
      final firstName = user.displayName!.split(' ').first;
      return 'Hi, $firstName';
    } else if (user?.email != null) {
      // Extract name from email if no display name
      final emailName = user!.email!.split('@').first;
      final capitalizedName =
          emailName[0].toUpperCase() + emailName.substring(1);
      return 'Hi, $capitalizedName';
    } else {
      // Fallback
      return 'Hi, User';
    }
  }

  String _getUserInitials() {
    final user = _authService.currentUser;

    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final names = user.displayName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        return names[0].substring(0, 2).toUpperCase();
      }
    } else if (user?.email != null) {
      final emailName = user!.email!.split('@').first;
      return emailName.substring(0, 2).toUpperCase();
    } else {
      return 'US';
    }
  }

  // Helper method to format dates
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 1) {
      return 'In $difference days';
    } else {
      return '${-difference} days ago';
    }
  }

  // New method: Shows user's own packages (for Sender + My Items)
  Widget _buildMyPackagesListView() {
    return Column(
      children: [
        // Real-time Streaming Packages
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: LiquidRefreshIndicator(
            onRefresh: () async {
              _forceRefreshStreams();
              await Future.delayed(Duration(milliseconds: 500));
            },
            child: StreamBuilder<List<PackageRequest>>(
              stream: _packagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CenteredLiquidLoading();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text('Error loading packages',
                            style: TextStyle(color: Colors.red)),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initializeDataStreams();
                            });
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final packages = snapshot.data ?? [];
                final currentUserId = _authService.currentUser?.uid ?? '';
                final searchText = _searchController.text.toLowerCase().trim();

                // Show only current user's packages
                List<PackageRequest> filteredPackages = packages
                    .where((package) => package.senderId == currentUserId)
                    .take(10)
                    .toList();

                // Apply search filter if search text is provided
                if (searchText.isNotEmpty) {
                  filteredPackages = filteredPackages.where((package) {
                    final pickupLocation =
                        package.pickupLocation.address.toLowerCase();
                    final destinationLocation =
                        package.destinationLocation.address.toLowerCase();
                    final senderName = package.senderName.toLowerCase();
                    final description =
                        package.packageDetails.description.toLowerCase();
                    final pickupCity =
                        (package.pickupLocation.city ?? '').toLowerCase();
                    final destinationCity =
                        (package.destinationLocation.city ?? '').toLowerCase();

                    return pickupLocation.contains(searchText) ||
                        destinationLocation.contains(searchText) ||
                        senderName.contains(searchText) ||
                        description.contains(searchText) ||
                        pickupCity.contains(searchText) ||
                        destinationCity.contains(searchText);
                  }).toList();
                }

                if (filteredPackages.isEmpty) {
                  return _buildEmptyCardsList('package');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                  itemCount: filteredPackages.length,
                  itemBuilder: (context, index) {
                    return _buildSmartPackageCard(
                        filteredPackages[index], index);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // New method: Shows user's own trips (for Traveler + My Items)
  Widget _buildMyTripsListView() {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.person, color: Color(0xFF0046FF), size: 20),
              SizedBox(width: 8),
              Text(
                'My Trips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0046FF),
                ),
              ),
            ],
          ),
        ),
        // Real-time Streaming Trips
        Expanded(
          child: LiquidRefreshIndicator(
            onRefresh: () async {
              _forceRefreshStreams();
              await Future.delayed(Duration(milliseconds: 500));
            },
            child: StreamBuilder<List<TravelTrip>>(
              stream: _tripsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CenteredLiquidLoading();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text('Error loading trips',
                            style: TextStyle(color: Colors.red)),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initializeDataStreams();
                            });
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final trips = snapshot.data ?? [];
                final currentUserId = _authService.currentUser?.uid ?? '';
                final searchText = _searchController.text.toLowerCase().trim();

                // Show only current user's trips
                List<TravelTrip> filteredTrips = trips
                    .where((trip) => trip.travelerId == currentUserId)
                    .take(10)
                    .toList();

                // Apply search filter if search text is provided
                if (searchText.isNotEmpty) {
                  filteredTrips = filteredTrips.where((trip) {
                    final fromLocation =
                        trip.departureLocation.address.toLowerCase();
                    final toLocation =
                        trip.destinationLocation.address.toLowerCase();
                    final travelerName = trip.travelerName.toLowerCase();
                    final departureCity =
                        (trip.departureLocation.city ?? '').toLowerCase();
                    final destinationCity =
                        (trip.destinationLocation.city ?? '').toLowerCase();

                    return fromLocation.contains(searchText) ||
                        toLocation.contains(searchText) ||
                        travelerName.contains(searchText) ||
                        departureCity.contains(searchText) ||
                        destinationCity.contains(searchText);
                  }).toList();
                }

                if (filteredTrips.isEmpty) {
                  return _buildEmptyCardsList('trip');
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredTrips.length,
                  itemBuilder: (context, index) {
                    return TripCardWidget(
                      trip: filteredTrips[index],
                      index: index,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to get package type icons
  IconData _getPackageTypeIcon(PackageType type) {
    switch (type) {
      case PackageType.documents:
        return Icons.description;
      case PackageType.electronics:
        return Icons.devices;
      case PackageType.clothing:
        return Icons.checkroom;
      case PackageType.food:
        return Icons.restaurant;
      case PackageType.books:
        return Icons.menu_book;
      case PackageType.gifts:
        return Icons.card_giftcard;
      case PackageType.medicine:
        return Icons.medical_services;
      case PackageType.cosmetics:
        return Icons.face;
      case PackageType.other:
        return Icons.inventory;
    }
  }

  IconData _getTransportModeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.flight:
        return Icons.flight;
      case TransportMode.train:
        return Icons.train;
      case TransportMode.bus:
        return Icons.directions_bus;
      case TransportMode.car:
        return Icons.directions_car;
      case TransportMode.motorcycle:
        return Icons.motorcycle;
      case TransportMode.bicycle:
        return Icons.pedal_bike;
      case TransportMode.walking:
        return Icons.directions_walk;
      case TransportMode.ship:
        return Icons.directions_boat;
    }
  }

  // Smart package status determination based on multiple factors
  Map<String, dynamic> _getSmartPackageStatus(PackageRequest package) {
    final now = DateTime.now();
    final daysDifference = package.preferredDeliveryDate.difference(now).inDays;

    // Check actual package status first
    switch (package.status) {
      case PackageStatus.matched:
        return {
          'text': 'Matched',
          'color': Color(0xFF3B82F6), // Blue
        };
      case PackageStatus.confirmed:
        return {
          'text': 'Confirmed',
          'color': Color(0xFF10B981), // Green
        };
      case PackageStatus.pickedUp:
        return {
          'text': 'Picked Up',
          'color': Color(0xFF8B5CF6), // Purple
        };
      case PackageStatus.inTransit:
        return {
          'text': 'In Transit',
          'color': Color(0xFF6366F1), // Indigo
        };
      case PackageStatus.delivered:
        return {
          'text': 'Delivered',
          'color': Color(0xFF059669), // Emerald
        };
      case PackageStatus.cancelled:
        return {
          'text': 'Cancelled',
          'color': Color(0xFFEF4444), // Red
        };
      case PackageStatus.disputed:
        return {
          'text': 'Disputed',
          'color': Color(0xFFDC2626), // Dark Red
        };
      case PackageStatus.pending:
        // For pending packages, determine smart availability status
        break;
    }

    // For pending packages, calculate smart status based on multiple factors
    if (package.isUrgent) {
      if (daysDifference <= 0) {
        return {
          'text': 'Overdue',
          'color': Color(0xFFEF4444), // Red
        };
      } else if (daysDifference <= 1) {
        return {
          'text': 'Critical',
          'color': Color(0xFFFF6B35), // Orange-red
        };
      } else {
        return {
          'text': 'Urgent',
          'color': Color(0xFFF59E0B), // Amber
        };
      }
    }

    // Time-based availability for non-urgent packages
    if (daysDifference <= 0) {
      return {
        'text': 'Past Due',
        'color': Color(0xFFF87171), // Light red
      };
    } else if (daysDifference <= 2) {
      return {
        'text': 'Soon',
        'color': Color(0xFFF59E0B), // Amber
      };
    } else if (daysDifference <= 7) {
      return {
        'text': 'This Week',
        'color': Color(0xFF3B82F6), // Blue
      };
    } else {
      // Check for special requirements or high value
      if (package.packageDetails.isFragile ||
          package.packageDetails.requiresRefrigeration ||
          package.packageDetails.isPerishable) {
        return {
          'text': 'Special Care',
          'color': Color(0xFF8B5CF6), // Purple
        };
      } else if (package.packageDetails.valueUSD != null &&
          package.packageDetails.valueUSD! > 500) {
        return {
          'text': 'High Value',
          'color': Color(0xFF10B981), // Green
        };
      } else {
        return {
          'text': 'Available',
          'color': Color(0xFF10B981), // Green
        };
      }
    }
  }
}

class _CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Get the standard centerFloat position
    final Offset standardOffset =
        FloatingActionButtonLocation.centerFloat.getOffset(scaffoldGeometry);

    // Adjust the Y position to be higher to avoid the bottom navigation bar
    // Move the FAB up by approximately 100 pixels to clear the bottom navigation bar
    final double adjustedY = standardOffset.dy - 100;

    return Offset(standardOffset.dx, adjustedY);
  }
}
