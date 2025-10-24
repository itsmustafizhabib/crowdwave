import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'dart:math' as math;
import '../../core/app_export.dart';
import '../../services/auth_state_service.dart';
import '../../services/notification_service.dart';
import '../../services/kyc_service.dart';
import '../../controllers/smart_matching_controller.dart';
import '../package_detail/package_detail_screen.dart';
import '../../widgets/liquid_refresh_indicator.dart';
import '../../widgets/liquid_loading_indicator.dart';
import '../../widgets/trip_card_widget.dart';
import '../forum/community_forum_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../chat/individual_chat_screen.dart';
import '../booking/make_offer_screen.dart';

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

  // Location filter: 'all', 'local', 'abroad'
  String _locationFilter = 'all';

  // Smart matching controller
  late SmartMatchingController _smartMatchingController;
  late NotificationService _notificationService;

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

    // Initialize notification service
    _notificationService = Get.put(NotificationService());

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
    // Always get all recent packages for discovery (not user's own)
    _packagesStream =
        _packageRepository.getRecentPackages(limit: 50); // Increased limit
    _tripsStream = _tripRepository.getRecentTrips(limit: 50); // Increased limit

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

                // KYC Alert Banner
                _buildKYCBanner(),

                // Swipeable Cards
                _buildSwipeableCards(),

                // Additional content area (optional)
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Green header section with background image
        Container(
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/bg_header.png'),
              fit: BoxFit.cover,
              opacity: 0.3,
            ),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2D6A5F),
                Color(0xFF1F4D43)
              ], // Teal/green gradient
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with profile and action icons
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
                                    'post_package.find_available_packages'.tr(),
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
                      Container(
                        padding: EdgeInsets.zero,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Support Icon
                            InkWell(
                              onTap: _showHelpSupportDialog,
                              child: const Icon(
                                Icons.headset_mic,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Community Forum Icon
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CommunityForumScreen(),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.people,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Notification Bell with Badge
                            Stack(
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, '/notifications');
                                  },
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                // Badge for unread notifications
                                if (_notificationService.unreadCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 12,
                                        minHeight: 12,
                                      ),
                                      child: Text(
                                        _notificationService.unreadCount > 9
                                            ? '9+'
                                            : _notificationService.unreadCount
                                                .toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Search bar + Local/Abroad buttons
                  Row(
                    children: [
                      // Search bar
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
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
                              hintText: 'Search packages...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              icon: Icon(
                                Icons.search,
                                color: Colors.grey[400],
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon:
                                          Icon(Icons.clear, color: Colors.grey),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          // Trigger rebuild to clear search filter
                                        });
                                      },
                                    )
                                  : null,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 15),
                            ),
                            cursorColor: const Color(0xFF2D6A5F),
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
                      ),
                      SizedBox(width: 8),
                      // Local button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _locationFilter = 'local';
                          });
                        },
                        child: Container(
                          width: 70,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _locationFilter == 'local'
                                  ? Color(0xFF2D6A5F)
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business,
                                color: _locationFilter == 'local'
                                    ? Color(0xFF2D6A5F)
                                    : Colors.grey[600],
                                size: 20,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Local',
                                style: TextStyle(
                                  color: _locationFilter == 'local'
                                      ? Color(0xFF2D6A5F)
                                      : Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Abroad button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _locationFilter = 'abroad';
                          });
                        },
                        child: Container(
                          width: 70,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _locationFilter == 'abroad'
                                  ? Color(0xFF2D6A5F)
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.public,
                                color: _locationFilter == 'abroad'
                                    ? Color(0xFF2D6A5F)
                                    : Colors.grey[600],
                                size: 20,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Abroad',
                                style: TextStyle(
                                  color: _locationFilter == 'abroad'
                                      ? Color(0xFF2D6A5F)
                                      : Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Post Package and Create Trip buttons (outside green header)
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              // Post Package button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.postPackage);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2D6A5F),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Post Package',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Create Trip button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to travel screen
                    Navigator.pushNamed(context, AppRoutes.travel);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2D6A5F),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Create Trip',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
                  color: Color(0xFF2D6A5F).withOpacity(0.3), // Teal/green
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
                              ? Color(0xFF2D6A5F) // Teal/green
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'home.all_items'.tr(),
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
                              ? Color(0xFF2D6A5F) // Teal/green
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'home.my_items'.tr(),
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
        color: const Color(0xFF2D6A5F), // Teal/green
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
          Expanded(
            child: Text(
              'common.complete_your_kyc_to_start_earning'.tr(),
              style: const TextStyle(
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
            child: Text(
              'booking.complete_step'.tr(),
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

// Always show all packages (not user's own)
  Widget _buildSwipeableCards() {
    return _buildPackagesListView();
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
                  color: Color(0xFF2D6A5F), size: 20), // Teal/green
              SizedBox(width: 8),
              Text(
                _showOnlyMyPackages ? 'My Trips' : 'Recommended Travelers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D6A5F), // Teal/green
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
                        Text('home.error_loading_trips'.tr(),
                            style: TextStyle(color: Colors.red)),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initializeDataStreams(); // Refresh streams
                            });
                          },
                          child: Text('common.retry'.tr()),
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
                        Text('home.error_loading_packages'.tr(),
                            style: TextStyle(color: Colors.red)),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initializeDataStreams(); // Refresh streams
                            });
                          },
                          child: Text('common.retry'.tr()),
                        ),
                      ],
                    ),
                  );
                }

                final packages = snapshot.data ?? [];
                final currentUserId = _authService.currentUser?.uid ?? '';
                final searchText = _searchController.text.toLowerCase().trim();

                // Show all packages except current user's own packages and show only pending packages
                List<PackageRequest> filteredPackages = packages
                    .where((package) =>
                        package.senderId != currentUserId &&
                        package.status == PackageStatus.pending)
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

                // Apply location filter (Local/Abroad)
                if (_locationFilter == 'local') {
                  filteredPackages = filteredPackages.where((package) {
                    // Local: same country for pickup and destination
                    final pickupCountry =
                        package.pickupLocation.country?.toLowerCase() ?? '';
                    final destCountry =
                        package.destinationLocation.country?.toLowerCase() ??
                            '';
                    return pickupCountry.isNotEmpty &&
                        destCountry.isNotEmpty &&
                        pickupCountry == destCountry;
                  }).toList();
                } else if (_locationFilter == 'abroad') {
                  filteredPackages = filteredPackages.where((package) {
                    // Abroad: different countries for pickup and destination
                    final pickupCountry =
                        package.pickupLocation.country?.toLowerCase() ?? '';
                    final destCountry =
                        package.destinationLocation.country?.toLowerCase() ??
                            '';
                    return pickupCountry.isNotEmpty &&
                        destCountry.isNotEmpty &&
                        pickupCountry != destCountry;
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
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with package icon, sender info and price
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Package icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.black87,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 12),
                  // Sender info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                package.senderName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              color: Color(0xFF2D6A5F),
                              size: 18,
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatDate(package.preferredDeliveryDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Price badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF2D6A5F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '€${package.compensationOffer.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Route section with FROM/TO
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
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
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            package.pickupLocation.city ??
                                package.pickupLocation.address.split(',').first,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Airplane icon
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Transform.rotate(
                        angle: math.pi / 2,
                        child: Icon(
                          Icons.flight,
                          size: 28,
                          color: Color(0xFF2D6A5F),
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
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            package.destinationLocation.city ??
                                package.destinationLocation.address
                                    .split(',')
                                    .first,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
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

              // Action buttons - Chat and Make Offer
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to chat with the package sender
                        final currentUserId =
                            _authService.currentUser?.uid ?? '';
                        final conversationId = _generateConversationId(
                            currentUserId, package.senderId);

                        Get.to(() => IndividualChatScreen(
                              conversationId: conversationId,
                              otherUserName: package.senderName,
                              otherUserId: package.senderId,
                              otherUserAvatar: null,
                            ));
                      },
                      icon: Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2D6A5F),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to make offer screen
                        Get.to(() => MakeOfferScreen(
                              package: package,
                            ));
                      },
                      icon: Icon(Icons.local_offer_outlined, size: 18),
                      label: Text('Make Offer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2D6A5F),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
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
                      color: Color(0xFF2D6A5F).withOpacity(0.1), // Teal/green
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      color: Color(0xFF2D6A5F), // Teal/green
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
                      color: Color(0xFF2D6A5F), // Teal/green
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF2D6A5F), // Teal/green
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'home.view_details'.tr(),
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
        statusColor = Colors.amber;
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
        statusColor = Colors.amber;
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
              color: Color(0xFF2D6A5F), // Teal/green
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.person,
              color: Color(0xFF2D6A5F), // Teal/green
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
            color: Color(0xFF2D6A5F), // Teal/green
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

  // Helper method to generate conversation ID
  String _generateConversationId(String userId1, String userId2) {
    // Sort user IDs to ensure consistent conversation ID regardless of order
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
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
                        Text('home.error_loading_packages'.tr(),
                            style: TextStyle(color: Colors.red)),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initializeDataStreams();
                            });
                          },
                          child: Text('common.retry'.tr()),
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
              Icon(Icons.person,
                  color: Color(0xFF2D6A5F), size: 20), // Teal/green
              SizedBox(width: 8),
              Text(
                'travel.my_trips'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D6A5F), // Teal/green
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
                        Text('home.error_loading_trips'.tr(),
                            style: TextStyle(color: Colors.red)),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initializeDataStreams();
                            });
                          },
                          child: Text('common.retry'.tr()),
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
          'color': Color(0xFFFFC107), // Amber
        };
      } else {
        return {
          'text': 'Urgent',
          'color': Color(0xFFF59E0B), // Amber
        };
      }
    }

    // Time-based availability for non-urgent packages
    if (daysDifference < 0) {
      return {
        'text': 'Past Due',
        'color': Color(0xFFF87171), // Light red
      };
    } else if (daysDifference == 0) {
      return {
        'text': 'Today',
        'color': Color(0xFFFFC107), // Amber (urgent but not overdue)
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

  void _showHelpSupportDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              20,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF215C5C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.headset_mic,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Support & Help',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSupportOptionRow(
                icon: Icons.email_outlined,
                title: 'account.email_support'.tr(),
                subtitle: 'info@crowdwave.eu',
                onTap: () async {
                  Navigator.pop(context);
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'info@crowdwave.eu',
                    query: 'subject=Support Request',
                  );
                  try {
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Could not open email app. Please email us at info@crowdwave.eu'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print('Error launching email: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Could not open email app. Please email us at info@crowdwave.eu'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 24),
              _buildSupportOptionRow(
                icon: Icons.chat_bubble_outline,
                title: 'account.whatsapp'.tr(),
                subtitle: 'account.whatsapp_desc'.tr(),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri whatsappUri =
                      Uri.parse('https://wa.me/491782045474');
                  if (await canLaunchUrl(whatsappUri)) {
                    await launchUrl(whatsappUri,
                        mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const Divider(height: 24),
              _buildSupportOptionRow(
                icon: Icons.help_center_outlined,
                title: 'account.help_center'.tr(),
                subtitle: 'account.help_center_desc'.tr(),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri faqUri = Uri.parse(
                      'https://crowdwave-website-live.vercel.app/index.html#faq');
                  if (await canLaunchUrl(faqUri)) {
                    await launchUrl(faqUri,
                        mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportOptionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5FAF4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF215C5C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
