import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart' hide Trans;
import '../home/updated_home_screen.dart';
import '../orders/orders_screen.dart';
import '../wallet/wallet_screen.dart';
import '../chat/chat_screen.dart';
import '../account/account_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../../services/auth_state_service.dart';
import '../../services/locale/locale_detection_service.dart';
import '../../services/deal_negotiation_service.dart';
import '../../routes/app_routes.dart';
import '../../services/location_notification_service.dart';
import '../../utils/black_screen_fix.dart';
import '../../utils/debug_menu.dart';
import '../../widgets/liquid_loading_indicator.dart';
import '../../widgets/language_picker_sheet.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final AuthStateService _authService = AuthStateService();
  final LocationBasedNotificationService _locationNotificationService =
      LocationBasedNotificationService();

  // Unseen offers count for badge
  int _unseenOffersCount = 0;
  StreamSubscription<int>? _offersCountSubscription;

  // Based on analysis of the app structure
  final List<Widget> _screens = [
    const UpdatedHomeScreen(), // Updated home screen with the new design
    const ChatScreen(), // Chat functionality
    const OrdersScreen(), // Order management
    const WalletScreen(), // Payments & earnings
    const AccountScreen(), // Account settings and profile
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Listen to auth state changes to update drawer UI when user data changes
    _authService.addListener(_onAuthStateChanged);

    // Setup unseen offers count stream
    _setupOffersCountStream();

    // Don't initialize location notifications automatically
    // Users will enable them manually in settings when they want them
  }

  void _setupOffersCountStream() {
    _offersCountSubscription =
        DealNegotiationService().streamUnseenOffersCount().listen((count) {
      if (mounted) {
        setState(() {
          _unseenOffersCount = count;
        });
      }
    });
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

      // Cancel stream subscriptions
      _offersCountSubscription?.cancel();

      // Dispose controllers safely
      if (_pageController.hasClients) {
        _pageController.dispose();
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
        body: PageView(
          controller: _pageController,
          physics: const ClampingScrollPhysics(), // Prevent over-scroll issues
          onPageChanged: (index) {
            if (_selectedIndex != index && mounted) {
              setState(() {
                _selectedIndex = index;
              });
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
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'nav.home'.tr()),
            _buildNavItem(1, Icons.chat_outlined, Icons.chat, 'nav.chat'.tr()),
            _buildNavItem(2, Icons.receipt_long_outlined, Icons.receipt_long,
                'nav.orders'.tr(),
                badgeCount: _unseenOffersCount),
            _buildNavItem(3, Icons.account_balance_wallet_outlined,
                Icons.account_balance_wallet, 'nav.wallet'.tr()),
            _buildNavItem(
                4, Icons.person_outline, Icons.person, 'nav.account'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData inactiveIcon, IconData activeIcon, String label,
      {int? badgeCount}) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon area with fixed size
              SizedBox(
                width: 50,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Background indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      width: isSelected ? 50 : 0,
                      height: isSelected ? 32 : 0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCE8C9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    // Icon with fixed size - no scaling
                    Icon(
                      isSelected ? activeIcon : inactiveIcon,
                      size: 24,
                      color: isSelected
                          ? const Color(0xFF215C5C)
                          : Colors.grey[800],
                    ),
                    // Badge
                    if (badgeCount != null && badgeCount > 0)
                      Positioned(
                        right: 7,
                        top: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              badgeCount > 9 ? '9+' : badgeCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Label - always dark and bold
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
                colors: [Color(0xFF215C5C), Color(0xFF2D7A6E)],
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
                  title: 'drawer.profile'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    _showProfileBottomSheet();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'drawer.settings'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('drawer.settings'.tr());
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.language,
                  title: 'drawer.language'.tr(),
                  subtitle: context.locale.languageCode.toUpperCase(),
                  onTap: () async {
                    Navigator.pop(context);
                    await LanguagePickerSheet.show(
                      context: context,
                      onLanguageSelected: (String languageCode) async {
                        final localeService =
                            Get.find<LocaleDetectionService>();
                        await localeService.updateLocale(languageCode);
                      },
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_outlined,
                  title: 'drawer.notification_settings'.tr(),
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
                  title: 'drawer.order_history'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('drawer.order_history'.tr());
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.payment_outlined,
                  title: 'drawer.payment_methods'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('drawer.payment_methods'.tr());
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'drawer.help_support'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('drawer.help_support'.tr());
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'drawer.about'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog();
                  },
                ),
                // ✅ DEBUG: Add notification test screen (only in debug mode)
                if (kDebugMode) ...[
                  const Divider(
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildDrawerItem(
                    icon: Icons.bug_report,
                    title: 'drawer.debug_menu'.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      DebugMenu.show(context);
                    },
                    textColor: Colors.orange,
                    iconColor: Colors.orange,
                  ),
                ],
                const Divider(
                  indent: 16,
                  endIndent: 16,
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'drawer.logout'.tr(),
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
              color: Color(0xFF215C5C),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.person,
              color: Color(0xFF215C5C),
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
            color: Color(0xFF215C5C),
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
    String? subtitle,
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
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            )
          : null,
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
            Padding (
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('profile.profile_information'.tr(),
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
                        backgroundColor: const Color(0xFF215C5C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text('profile.edit_profile'.tr(),
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
        title: Text('profile.coming_soon'.tr(),
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
            child: Text('common.ok'.tr(),
              style: TextStyle(
                color: Color(0xFF215C5C),
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
      applicationName: 'app.name'.tr(),
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF215C5C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.waves,
          color: Colors.white,
          size: 30,
        ),
      ),
      children: [
        Text('post_package.crowdwave_connects_senders_and_travelers_for_effic'.tr(),
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
        title: Text('drawer.logout'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Text('common.are_you_sure_you_want_to_logout'.tr(),
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr(),
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
            child: Text('drawer.logout'.tr(),
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
