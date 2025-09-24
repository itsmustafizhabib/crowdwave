import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../home/updated_home_screen.dart';
import '../orders/orders_screen.dart';
import '../travel/travel_screen.dart';
import '../wallet/wallet_screen.dart';
import '../chat/chat_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../../services/auth_state_service.dart';
import '../../routes/app_routes.dart';
import '../../services/location_notification_service.dart';
import '../../utils/black_screen_fix.dart';
import '../../widgets/liquid_loading_indicator.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late List<AnimationController> _iconAnimationControllers;
  late AnimationController _indicatorAnimationController;
  final AuthStateService _authService = AuthStateService();
  final LocationBasedNotificationService _locationNotificationService =
      LocationBasedNotificationService();

  // Based on analysis of the app structure
  final List<Widget> _screens = [
    const UpdatedHomeScreen(), // Updated home screen with the new design
    const OrdersScreen(), // Order management
    const TravelScreen(), // Travel/Flight services
    const WalletScreen(), // Payments & earnings
    const ChatScreen(), // Chat functionality
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _indicatorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _iconAnimationControllers = List.generate(5, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
      if (index == 0) controller.forward(); // Start with home selected
      return controller;
    });

    // Listen to auth state changes to update drawer UI when user data changes
    _authService.addListener(_onAuthStateChanged);

    // Don't initialize location notifications automatically
    // Users will enable them manually in settings when they want them
  }

  void _onAuthStateChanged() {
    // Rebuild the widget when auth state changes (user login/logout, profile updates)
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    try {
      // 🚨 ENHANCED DISPOSAL - Prevent black screen issues
      print('🧹 MainNavigationScreen: Starting enhanced disposal...');

      // Remove listeners first
      _authService.removeListener(_onAuthStateChanged);

      // Dispose controllers safely
      if (_pageController.hasClients) {
        _pageController.dispose();
      }

      _indicatorAnimationController.dispose();

      for (var controller in _iconAnimationControllers) {
        if (!controller.isCompleted && !controller.isDismissed) {
          controller.stop();
        }
        controller.dispose();
      }

      // Stop location notifications with error handling
      try {
        _locationNotificationService.stopLocationBasedNotifications();
      } catch (e) {
        print('❌ Error stopping location notifications: $e');
      }

      // Clear image cache to free memory
      imageCache.clear();

      print('✅ MainNavigationScreen: Enhanced disposal completed');
    } catch (e) {
      print('❌ MainNavigationScreen disposal error: $e');
    }

    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Prevent unnecessary animations

    // Haptic feedback for better UX
    HapticFeedback.lightImpact();

    // Animate to the new page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );

    // Update icon animations
    _iconAnimationControllers[_selectedIndex].reverse();
    _iconAnimationControllers[index].forward();

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlackScreenProtection(
      screenName: 'MainNavigation',
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        drawer: _selectedIndex == 0
            ? _buildDrawer()
            : null, // Only show drawer on home screen
        body: PageView(
          controller: _pageController,
          physics: const ClampingScrollPhysics(), // Prevent over-scroll issues
          onPageChanged: (index) {
            if (_selectedIndex != index && mounted) {
              try {
                _iconAnimationControllers[_selectedIndex].reverse();
                _iconAnimationControllers[index].forward();
                setState(() {
                  _selectedIndex = index;
                });
              } catch (e) {
                print('❌ Page change error: $e');
                // Fallback: just update index without animations
                if (mounted) {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              }
            }
          },
          children: _screens,
        ),
        bottomNavigationBar: _buildCustomBottomNavBar(),
      ),
    );
  }

  Widget _buildCustomBottomNavBar() {
    return Container(
      height: 85 + MediaQuery.of(context).viewPadding.bottom,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
            _buildNavItem(
                1, Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
            _buildNavItem(2, Icons.flight_outlined, Icons.flight, 'Travel'),
            _buildNavItem(3, Icons.account_balance_wallet_outlined,
                Icons.account_balance_wallet, 'Wallet'),
            _buildNavItem(4, Icons.chat_outlined, Icons.chat, 'Chat'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData inactiveIcon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon container with indicator
            Stack(
              alignment: Alignment.center,
              children: [
                // Background indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  width: isSelected ? 50 : 0,
                  height: isSelected ? 32 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0046FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                // Icon with scale animation
                AnimatedBuilder(
                  animation: _iconAnimationControllers[index],
                  builder: (context, child) {
                    final scale =
                        1.0 + (_iconAnimationControllers[index].value * 0.2);
                    return Transform.scale(
                      scale: scale,
                      child: Icon(
                        isSelected ? activeIcon : inactiveIcon,
                        size: 24,
                        color: Color.lerp(
                          Colors.grey[600],
                          const Color(0xFF0046FF),
                          _iconAnimationControllers[index].value,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Animated label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: Color.lerp(
                  Colors.grey[600],
                  const Color(0xFF0046FF),
                  _iconAnimationControllers[index].value,
                ),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final user = _authService.currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header section with user profile
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0046FF), Color(0xFF001BB7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile image/avatar
                    _buildDrawerUserAvatar(),
                    const SizedBox(height: 16),

                    // User name
                    Text(
                      _getUserDisplayName(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // User email
                    if (user?.email != null)
                      Text(
                        user!.email!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    _showProfileBottomSheet();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Settings');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notification Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.history_outlined,
                  title: 'Order History',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Order History');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.payment_outlined,
                  title: 'Payment Methods',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Payment Methods');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Help & Support');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog();
                  },
                ),
                const Divider(
                  indent: 16,
                  endIndent: 16,
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                  textColor: Colors.red,
                  iconColor: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerUserAvatar() {
    final user = _authService.currentUser;

    if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: user.photoURL!,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (context, url) => LiquidLoadingIndicator(
              size: 80,
              color: Color(0xFF0046FF),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.person,
              color: Color(0xFF0046FF),
              size: 40,
            ),
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white,
        child: Text(
          _getUserInitials(),
          style: const TextStyle(
            color: Color(0xFF0046FF),
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.grey[600],
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  String _getUserDisplayName() {
    final user = _authService.currentUser;

    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    } else if (user?.email != null) {
      final emailName = user!.email!.split('@').first;
      return emailName[0].toUpperCase() + emailName.substring(1);
    } else {
      return 'User';
    }
  }

  String _getUserInitials() {
    final user = _authService.currentUser;

    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final names = user.displayName!.split(' ');
      if (names.length >= 2) {
        return (names[0][0] + names[1][0]).toUpperCase();
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

  void _showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProfileBottomSheet(),
    );
  }

  Widget _buildProfileBottomSheet() {
    final user = _authService.currentUser;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Profile avatar
            _buildDrawerUserAvatar(),

            const SizedBox(height: 16),

            // User information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Name
                  _buildProfileInfoRow(
                    'Name',
                    _getUserDisplayName(),
                    Icons.person_outline,
                  ),

                  const SizedBox(height: 12),

                  // Email
                  if (user?.email != null)
                    _buildProfileInfoRow(
                      'Email',
                      user!.email!,
                      Icons.email_outlined,
                    ),

                  const SizedBox(height: 12),

                  // Join date
                  if (user?.metadata.creationTime != null)
                    _buildProfileInfoRow(
                      'Member since',
                      _formatDate(user!.metadata.creationTime!),
                      Icons.calendar_today_outlined,
                    ),

                  const SizedBox(height: 30),

                  // Edit profile button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.profileOptions);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0046FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Coming Soon',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Text(
          '$feature is coming soon in the next update!',
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF0046FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'CrowdWave',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF0046FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.waves,
          color: Colors.white,
          size: 30,
        ),
      ),
      children: [
        const Text(
          'CrowdWave connects senders and travelers for efficient package delivery worldwide.',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  String errorMessage =
                      e.toString().replaceFirst('Exception: ', '');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $errorMessage'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
