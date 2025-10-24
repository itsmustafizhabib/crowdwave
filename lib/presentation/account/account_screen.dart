import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart' hide Trans;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../services/auth_state_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/locale/locale_detection_service.dart';
import '../../core/models/user_profile.dart';
import '../../routes/app_routes.dart';
import '../../utils/debug_menu.dart';
import '../../widgets/liquid_loading_indicator.dart';
import '../../widgets/language_picker_sheet.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthStateService _authService = AuthStateService();
  final UserProfileService _userProfileService = UserProfileService();
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthStateChanged);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _userProfileService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9E9E9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header Section
              _buildProfileHeader(),

              const SizedBox(height: 20),

              // Account Options
              _buildAccountOptions(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _authService.currentUser;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF215C5C),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            // Profile Avatar
            _buildUserAvatar(),
            const SizedBox(height: 12),

            // User Name
            Text(
              _getUserDisplayName(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // User Email
            if (user?.email != null)
              Text(
                user!.email!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    final user = _authService.currentUser;
    final photoUrl = _userProfile?.photoUrl ?? user?.photoURL;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          child: ClipOval(
            child: photoUrl.startsWith('data:image/')
                ? // Base64 image stored in Firestore
                Image.memory(
                    base64Decode(photoUrl.split(',')[1]),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        color: Color(0xFF215C5C),
                        size: 50,
                      );
                    },
                  )
                : // URL image (Google profile photo or external URL)
                CachedNetworkImage(
                    imageUrl: photoUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => LiquidLoadingIndicator(
                      size: 100,
                      color: Color(0xFF215C5C),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      color: Color(0xFF215C5C),
                      size: 50,
                    ),
                  ),
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          child: Text(
            _getUserInitials(),
            style: const TextStyle(
              color: Color(0xFF215C5C),
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildAccountOptions() {
    return Column(
      children: [
        // Settings Section
        _buildSectionCard(
          title: 'account.settings_title'.tr(),
          children: [
            _buildAccountOption(
              icon: Icons.person_outline,
              title: 'drawer.profile'.tr(),
              onTap: () async {
                await Navigator.pushNamed(context, AppRoutes.profileOptions);
                // Reload profile when returning from profile options screen
                _loadUserProfile();
              },
            ),
            _buildDivider(),
            _buildAccountOption(
              icon: Icons.history_outlined,
              title: 'account.delivery_history'.tr(),
              onTap: () {
                Navigator.pushNamed(context, '/tracking-history');
              },
            ),
            _buildDivider(),
            _buildAccountOption(
              icon: Icons.language,
              title: 'drawer.language'.tr(),
              trailing: Text(
                context.locale.languageCode.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                await LanguagePickerSheet.show(
                  context: context,
                  onLanguageSelected: (String languageCode) async {
                    final localeService = Get.find<LocaleDetectionService>();
                    await localeService.updateLocale(languageCode);
                  },
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Support Section
        _buildSectionCard(
          title: 'account.support'.tr(),
          children: [
            _buildAccountOption(
              icon: Icons.headset_mic,
              title: 'drawer.help_support'.tr(),
              onTap: _showHelpSupportDialog,
            ),
            _buildDivider(),
            _buildAccountOption(
              icon: Icons.info_outline,
              title: 'drawer.about'.tr(),
              onTap: _showAboutDialog,
            ),
          ],
        ),

        // Debug Menu (only in debug mode)
        if (kDebugMode) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'account.developer_options'.tr(),
            children: [
              _buildAccountOption(
                icon: Icons.bug_report,
                title: 'drawer.debug_menu'.tr(),
                onTap: () => DebugMenu.show(context),
                iconColor: Colors.orange,
                textColor: Colors.orange,
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),

        // Logout Button
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAccountOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF215C5C)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? const Color(0xFF215C5C),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? Colors.black87,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 24,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 76,
      endIndent: 20,
      color: Colors.grey[200],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
      child: InkWell(
        onTap: _showLogoutDialog,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'drawer.logout'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUserDisplayName() {
    final user = _authService.currentUser;

    // First check Firestore profile
    if (_userProfile?.fullName != null && _userProfile!.fullName.isNotEmpty) {
      return _userProfile!.fullName;
    }

    // Fallback to Firebase Auth
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

    // First check Firestore profile
    final displayName = _userProfile?.fullName ?? user?.displayName;

    if (displayName != null && displayName.isNotEmpty) {
      final names = displayName.split(' ');
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.logout,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'drawer.logout'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'common.are_you_sure_you_want_to_logout'.tr(),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            child: Text(
              'drawer.logout'.tr(),
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
                      size: 28,
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
                        SnackBar(
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF215C5C).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFF215C5C),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'common.about_crowdwave'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'common.crowdwave_courier'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF215C5C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Your trusted platform for peer-to-peer package delivery and travel connections.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.close'.tr(),
              style: const TextStyle(
                color: Color(0xFF215C5C),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
