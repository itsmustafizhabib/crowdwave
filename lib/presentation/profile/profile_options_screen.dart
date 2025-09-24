import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../services/auth_state_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/image_service.dart';
import '../../core/models/user_profile.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/liquid_loading_indicator.dart';

// App lifecycle observer to handle email verification refresh
class _AppLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onResumed;

  _AppLifecycleObserver({required this.onResumed});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}

class ProfileOptionsScreen extends StatefulWidget {
  const ProfileOptionsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileOptionsScreen> createState() => _ProfileOptionsScreenState();
}

class _ProfileOptionsScreenState extends State<ProfileOptionsScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  late _AppLifecycleObserver _lifecycleObserver;

  // Popular countries list
  final List<Map<String, String>> _countries = [
    {'name': 'Pakistan', 'code': 'PK', 'flag': '🇵🇰'},
    {'name': 'United States', 'code': 'US', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': 'GB', 'flag': '🇬🇧'},
    {'name': 'Canada', 'code': 'CA', 'flag': '🇨🇦'},
    {'name': 'Australia', 'code': 'AU', 'flag': '🇦🇺'},
    {'name': 'Germany', 'code': 'DE', 'flag': '🇩🇪'},
    {'name': 'France', 'code': 'FR', 'flag': '🇫🇷'},
    {'name': 'Italy', 'code': 'IT', 'flag': '🇮🇹'},
    {'name': 'Spain', 'code': 'ES', 'flag': '🇪🇸'},
    {'name': 'Netherlands', 'code': 'NL', 'flag': '🇳🇱'},
    {'name': 'India', 'code': 'IN', 'flag': '🇮🇳'},
    {'name': 'China', 'code': 'CN', 'flag': '🇨🇳'},
    {'name': 'Japan', 'code': 'JP', 'flag': '🇯🇵'},
    {'name': 'South Korea', 'code': 'KR', 'flag': '🇰🇷'},
    {'name': 'Singapore', 'code': 'SG', 'flag': '🇸🇬'},
    {'name': 'Malaysia', 'code': 'MY', 'flag': '🇲🇾'},
    {'name': 'Thailand', 'code': 'TH', 'flag': '🇹🇭'},
    {'name': 'UAE', 'code': 'AE', 'flag': '🇦🇪'},
    {'name': 'Saudi Arabia', 'code': 'SA', 'flag': '🇸🇦'},
    {'name': 'Turkey', 'code': 'TR', 'flag': '🇹🇷'},
  ];

  // Popular cities by country
  final Map<String, List<String>> _citiesByCountry = {
    'Pakistan': [
      'Karachi',
      'Lahore',
      'Islamabad',
      'Rawalpindi',
      'Faisalabad',
      'Multan',
      'Peshawar',
      'Quetta'
    ],
    'United States': [
      'New York',
      'Los Angeles',
      'Chicago',
      'Houston',
      'Phoenix',
      'Philadelphia',
      'San Antonio',
      'San Diego'
    ],
    'United Kingdom': [
      'London',
      'Manchester',
      'Birmingham',
      'Leeds',
      'Glasgow',
      'Liverpool',
      'Bristol',
      'Edinburgh'
    ],
    'Canada': [
      'Toronto',
      'Montreal',
      'Vancouver',
      'Calgary',
      'Ottawa',
      'Edmonton',
      'Mississauga',
      'Winnipeg'
    ],
    'Australia': [
      'Sydney',
      'Melbourne',
      'Brisbane',
      'Perth',
      'Adelaide',
      'Gold Coast',
      'Newcastle',
      'Canberra'
    ],
    'Germany': [
      'Berlin',
      'Hamburg',
      'Munich',
      'Cologne',
      'Frankfurt',
      'Stuttgart',
      'Düsseldorf',
      'Dortmund'
    ],
    'France': [
      'Paris',
      'Marseille',
      'Lyon',
      'Toulouse',
      'Nice',
      'Nantes',
      'Strasbourg',
      'Montpellier'
    ],
    'India': [
      'Mumbai',
      'Delhi',
      'Bangalore',
      'Hyderabad',
      'Chennai',
      'Kolkata',
      'Pune',
      'Ahmedabad'
    ],
    'UAE': [
      'Dubai',
      'Abu Dhabi',
      'Sharjah',
      'Al Ain',
      'Ajman',
      'Ras Al Khaimah',
      'Fujairah',
      'Umm Al Quwain'
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // Create and add lifecycle observer
    _lifecycleObserver = _AppLifecycleObserver(
      onResumed: _refreshEmailVerificationStatus,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  // Refresh email verification status when app resumes
  Future<void> _refreshEmailVerificationStatus() async {
    try {
      final authStateService =
          Provider.of<AuthStateService>(context, listen: false);

      // Reload the current user to get the latest verification status from Firebase
      await authStateService.currentUser?.reload();

      // Refresh the auth state to get latest verification status
      authStateService.refreshAuthState();

      // Sync email verification status between Firebase Auth and Firestore
      await _syncEmailVerificationStatus();

      // Reload user profile to reflect changes
      await _loadUserProfile();
    } catch (e) {
      debugPrint('Error refreshing email verification status: $e');
    }
  }

  // Sync email verification status between Firebase Auth and Firestore
  Future<void> _syncEmailVerificationStatus() async {
    try {
      final authStateService =
          Provider.of<AuthStateService>(context, listen: false);
      final currentUser = authStateService.currentUser;

      if (currentUser != null) {
        // Check if Firebase Auth shows email as verified
        final isEmailVerifiedInAuth = currentUser.emailVerified;

        // Check if our user profile shows different status
        if (_userProfile != null &&
            _userProfile!.verificationStatus.emailVerified !=
                isEmailVerifiedInAuth) {
          // Update the email verification status in Firestore to match Firebase Auth
          await _userProfileService
              .updateEmailVerificationStatus(isEmailVerifiedInAuth);
        }
      }
    } catch (e) {
      debugPrint('Error syncing email verification status: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);

      // First sync email verification status
      await _syncEmailVerificationStatus();

      // Then load the user profile
      final profile = await _userProfileService.getCurrentUserProfile();

      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthStateService>(context);
    final currentUser = authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.primaryVariantLight, // Changed from red to blue
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor:
            AppTheme.primaryVariantLight, // Changed from red to blue
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              Brightness.light, // Light icons for dark background
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Column(
              children: [
                // Profile Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Profile Image with Edit Icon
                      GestureDetector(
                        onTap: () => _showPhotoUpdateDialog(),
                        child: Stack(
                          children: [
                            _buildProfileAvatar(currentUser),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppTheme.primaryVariantLight,
                                      width: 2), // Changed from red to blue
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: AppTheme
                                      .primaryVariantLight, // Changed from red to blue
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name with Edit Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _userProfile?.fullName ??
                                currentUser?.displayName ??
                                'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // White Content Section
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: MediaQuery.of(context).viewPadding.bottom +
                            100, // Space for bottom navigation bar
                      ),
                      child: Column(
                        children: [
                          // Address Section
                          _buildProfileOption(
                            icon: Icons.location_on_outlined,
                            title: 'Address',
                            subtitle: _userProfile?.address != null &&
                                    _userProfile!.address!.isNotEmpty
                                ? '${_userProfile!.address}, ${_userProfile!.city ?? ''}, ${_userProfile!.country ?? ''}'
                                    .replaceAll(RegExp(r',\s*,'), ',')
                                    .replaceAll(RegExp(r',\s*$'), '')
                                : 'Not set',
                            actionText: 'Update',
                            onTap: () => _showAddressUpdateDialog(),
                          ),

                          const SizedBox(height: 20),

                          // Mobile Number Section
                          _buildProfileOption(
                            icon: Icons.phone_outlined,
                            title: 'Mobile Number',
                            subtitle: _userProfile
                                        ?.verificationStatus.phoneVerified ==
                                    true
                                ? 'Verified'
                                : 'Unverified',
                            actionText: 'Change',
                            onTap: () => _showComingSoonDialog(
                                'Phone Number Management'),
                            isVerified: _userProfile
                                    ?.verificationStatus.phoneVerified ==
                                true,
                          ),

                          const SizedBox(height: 20),

                          // Identity Verification Section
                          _buildProfileOption(
                            icon: Icons.badge_outlined,
                            title: 'Identity',
                            subtitle: _userProfile
                                        ?.verificationStatus.identityVerified ==
                                    true
                                ? 'Verified'
                                : 'Unverified',
                            actionText: 'Verify Now',
                            onTap: _userProfile
                                        ?.verificationStatus.identityVerified ==
                                    true
                                ? null
                                : () => Navigator.pushNamed(
                                    context, AppRoutes.kycCompletion),
                            isVerified: _userProfile
                                    ?.verificationStatus.identityVerified ==
                                true,
                          ),

                          const SizedBox(height: 20),

                          // Email Verification Section
                          _buildProfileOption(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            subtitle: _userProfile
                                        ?.verificationStatus.emailVerified ==
                                    true
                                ? 'Verified'
                                : 'Unverified',
                            actionText: _userProfile
                                        ?.verificationStatus.emailVerified ==
                                    true
                                ? 'Refresh'
                                : 'Verify',
                            onTap: _userProfile
                                        ?.verificationStatus.emailVerified ==
                                    true
                                ? () => _refreshEmailVerificationStatus()
                                : () => _showEmailVerificationOptions(),
                            isVerified: _userProfile
                                    ?.verificationStatus.emailVerified ==
                                true,
                          ),

                          const SizedBox(height: 40),

                          // Additional Options
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildSimpleOption(
                                  Icons.settings_outlined,
                                  'Settings',
                                  () => _showComingSoonDialog('Settings'),
                                ),
                                const Divider(),
                                _buildSimpleOption(
                                  Icons.help_outline,
                                  'Help & Support',
                                  () => _showComingSoonDialog('Help & Support'),
                                ),
                                const Divider(),
                                _buildSimpleOption(
                                  Icons.logout,
                                  'Sign Out',
                                  () => _showSignOutDialog(),
                                  isDestructive: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileAvatar(currentUser) {
    final photoUrl = _userProfile?.photoUrl ?? currentUser?.photoURL;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
        ),
        child: ClipOval(
          child: photoUrl.startsWith('data:image/')
              ? // Base64 image stored in Firestore (FREE!)
              Image.memory(
                  base64Decode(photoUrl.split(',')[1]),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 50,
                      ),
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
                    size: 40,
                    color: Colors.white,
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
        ),
      );
    } else {
      final name = _userProfile?.fullName ?? currentUser?.displayName ?? 'User';
      final initials = _getInitials(name);

      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback? onTap,
    bool isVerified = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryVariantLight
                  .withOpacity(0.1), // Changed from red to blue
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryVariantLight, // Changed from red to blue
              size: 24,
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isVerified ? Colors.green : Colors.grey[600],
                          fontWeight:
                              isVerified ? FontWeight.w500 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: Colors.green,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (actionText.isNotEmpty)
            GestureDetector(
              onTap: onTap,
              child: Text(
                actionText,
                style: const TextStyle(
                  fontSize: 14,
                  color:
                      AppTheme.primaryVariantLight, // Changed from red to blue
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleOption(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.grey[600],
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
        size: 20,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
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
                color: AppTheme.primaryVariantLight, // Changed from red to blue
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
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
              await Provider.of<AuthStateService>(context, listen: false)
                  .signOut();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            child: const Text(
              'Sign Out',
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

  void _showAddressUpdateDialog() {
    final addressController =
        TextEditingController(text: _userProfile?.address ?? '');
    String? selectedCountry = _userProfile?.country;
    String? selectedCity = _userProfile?.city;
    bool _isLoadingLocation = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Update Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Country Selection
                      const Text(
                        'Country',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCountry,
                            hint: const Text('Select Country'),
                            isExpanded: true,
                            items: _countries.map((country) {
                              return DropdownMenuItem<String>(
                                value: country['name'],
                                child: Row(
                                  children: [
                                    Text(
                                      country['flag']!,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        country['name']!,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCountry = value;
                                selectedCity =
                                    null; // Reset city when country changes
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // City Selection
                      const Text(
                        'City',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCity,
                            hint: const Text('Select City'),
                            isExpanded: true,
                            items: selectedCountry != null &&
                                    _citiesByCountry[selectedCountry] != null
                                ? _citiesByCountry[selectedCountry]!
                                    .map((city) {
                                    return DropdownMenuItem<String>(
                                      value: city,
                                      child: Text(
                                        city,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  }).toList()
                                : [],
                            onChanged: selectedCountry != null
                                ? (value) {
                                    setState(() {
                                      selectedCity = value;
                                    });
                                  }
                                : null,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Current Location Button
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingLocation
                              ? null
                              : () async {
                                  setState(() {
                                    _isLoadingLocation = true;
                                  });

                                  try {
                                    await _getCurrentLocation(
                                        (address, city, country) {
                                      setState(() {
                                        addressController.text = address;
                                        selectedCity = city;
                                        selectedCountry = country;
                                      });
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to get location: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    setState(() {
                                      _isLoadingLocation = false;
                                    });
                                  }
                                },
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.my_location, size: 16),
                          label: Flexible(
                            child: Text(
                              _isLoadingLocation
                                  ? 'Getting Location...'
                                  : 'Use Current Location',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppTheme.primaryVariantLight.withOpacity(0.1),
                            foregroundColor: AppTheme.primaryVariantLight,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Street Address
                      const Text(
                        'Street Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: addressController,
                        decoration: InputDecoration(
                          hintText: 'Enter your street address',
                          hintStyle: const TextStyle(fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                      ),
                      const SizedBox(
                          height: 20), // Add some spacing before buttons
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (selectedCountry == null ||
                                    selectedCity == null ||
                                    addressController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please fill in all address fields'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                Navigator.pop(context);
                                await _updateAddress(
                                  addressController.text.trim(),
                                  selectedCity!,
                                  selectedCountry!,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryVariantLight,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Update',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // Bottom padding
                    ],
                  ), // Close Column (inside SingleChildScrollView)
                ), // Close SingleChildScrollView
              ), // Close Expanded
            ], // Close Column children
          ), // Close StatefulBuilder Column
        ), // Close StatefulBuilder
      ), // Close Container
    );
  }

  Future<void> _getCurrentLocation(
      Function(String, String, String) onLocationFound) async {
    try {
      // Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String address =
            '${placemark.street ?? ''}, ${placemark.subLocality ?? ''}'
                .replaceAll(RegExp(r'^,\s*|,\s*$'), '');
        String city = placemark.locality ?? placemark.administrativeArea ?? '';
        String country = placemark.country ?? '';

        onLocationFound(address, city, country);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _updateAddress(
      String address, String city, String country) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Update address in Firebase
      await _userProfileService.updateUserAddress(
        address: address,
        city: city,
        country: country,
      );

      // Close loading dialog
      Navigator.pop(context);

      // Refresh profile data
      await _loadUserProfile();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPhotoUpdateDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Update Profile Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPhotoOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildPhotoOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildPhotoOption(
                  icon: Icons.delete_outline,
                  label: 'Remove',
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfilePhoto();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryVariantLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryVariantLight.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryVariantLight,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.primaryVariantLight,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAndUpdatePhoto(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadAndUpdatePhoto(File imageFile) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processing photo...'),
            ],
          ),
        ),
      );

      final user =
          Provider.of<AuthStateService>(context, listen: false).currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get image info for user feedback
      final imageInfo = await ImageService.getImageInfo(imageFile);
      print(
          'Original image: ${imageInfo['width']}x${imageInfo['height']}, Size: ${imageInfo['fileSizeMB']} MB');

      // Convert image to Base64 with automatic compression (Free alternative to Firebase Storage!)
      final String photoData = await ImageService.imageFileToBase64(imageFile);

      // Update user profile with Base64 photo data (stored in Firestore - FREE!)
      await _userProfileService.updateUserProfile(photoUrl: photoData);

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Refresh profile data
      await _loadUserProfile();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Profile photo updated successfully!'),
                    Text(
                      'Saved ${imageInfo['fileSizeMB']} MB to Firestore (FREE!)',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message with more details
      String errorMessage = 'Failed to update photo';
      if (e.toString().contains('too large') ||
          e.toString().contains('800KB')) {
        errorMessage =
            'Image is too large. Please select a smaller image or try taking a new photo.';
      } else if (e.toString().contains('permission')) {
        errorMessage =
            'Permission denied. Please check your account permissions.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('Invalid image')) {
        errorMessage = 'Invalid image file. Please try a different image.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _uploadAndUpdatePhoto(imageFile),
          ),
        ),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Remove Profile Photo'),
          content:
              const Text('Are you sure you want to remove your profile photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  // Update profile with null photo URL
                  await _userProfileService.updateUserProfile(photoUrl: '');

                  // Close loading dialog
                  Navigator.pop(context);

                  // Refresh profile
                  await _loadUserProfile();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile photo removed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Close loading dialog
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove photo: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle email verification
  Future<void> _handleEmailVerification() async {
    try {
      // Get the auth state service
      final authStateService =
          Provider.of<AuthStateService>(context, listen: false);
      final currentUser = authStateService.currentUser;

      // Check if user is logged in
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to verify your email'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if email is already verified
      if (currentUser.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email is already verified!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUserProfile(); // Refresh the UI
        return;
      }

      print('Sending verification email to: ${currentUser.email}');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Sending verification email...'),
            ],
          ),
        ),
      );

      // Send email verification
      bool success = await authStateService.sendEmailVerification();

      // Close loading dialog
      Navigator.pop(context);

      if (success) {
        // Show success dialog with refresh option
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verification Email Sent'),
            content: Text(
              'A verification email has been sent to ${currentUser.email}.\n\nPlease check your inbox (and spam folder) and click the verification link to verify your email.\n\nAfter verifying, you can tap "Check Status" to refresh your verification status.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _refreshEmailVerificationStatus();
                },
                child: const Text('Check Status'),
              ),
            ],
          ),
        );

        // Optionally refresh the user profile to check verification status
        _loadUserProfile();
      } else {
        // Show error message with more details
        String errorMsg = authStateService.error ?? 'Unknown error occurred';
        print('Email verification failed: $errorMsg');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send verification email: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Exception in email verification: $e');

      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending verification email: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Show email verification options
  Future<void> _showEmailVerificationOptions() async {
    final authStateService =
        Provider.of<AuthStateService>(context, listen: false);
    final currentUser = authStateService.currentUser;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Email Verification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (currentUser != null) ...[
              Text(
                'Email: ${currentUser.email}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                'Status: ${currentUser.emailVerified ? "Verified" : "Not Verified"}',
                style: TextStyle(
                  fontSize: 14,
                  color: currentUser.emailVerified ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Send/Resend Email Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleEmailVerification();
                },
                child: const Text('Send Verification Email'),
              ),
            ),

            const SizedBox(height: 12),

            // Check Status Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _refreshEmailVerificationStatus();
                },
                child: const Text('Check Verification Status'),
              ),
            ),

            const SizedBox(height: 12),

            // Debug Info Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showDebugInfo();
                },
                child: const Text('Debug Info'),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Troubleshooting Tips:\n'
              '• Check your spam/junk folder\n'
              '• Wait a few minutes for the email to arrive\n'
              '• Make sure your email address is correct\n'
              '• Try clicking "Check Status" after opening the email link\n'
              '• Check if emails from crowdwave.eu are blocked\n'
              '• Try with a different email address for testing',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Show debug information
  Future<void> _showDebugInfo() async {
    final authStateService =
        Provider.of<AuthStateService>(context, listen: false);
    final currentUser = authStateService.currentUser;

    String debugInfo = '''
Debug Information:
━━━━━━━━━━━━━━━━━━━━━━

User Info:
• Logged in: ${currentUser != null ? 'Yes' : 'No'}
• Email: ${currentUser?.email ?? 'N/A'}
• UID: ${currentUser?.uid ?? 'N/A'}
• Email Verified: ${currentUser?.emailVerified ?? false}
• Created: ${currentUser?.metadata.creationTime ?? 'N/A'}

Profile Info:
• Profile Loaded: ${_userProfile != null ? 'Yes' : 'No'}
• Profile Email Verified: ${_userProfile?.verificationStatus.emailVerified ?? false}

Firebase Project: crowdwave-93d4d
Auth Domain: crowdwave-93d4d.firebaseapp.com
SMTP: Zoho Mail

Zoho SMTP Troubleshooting:
━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. CHECK ZOHO MAIL SETTINGS:
   • Login to Zoho Mail Admin Console
   • Check if SMTP is enabled for your domain
   • Verify SMTP authentication credentials

2. FIREBASE CONSOLE CHECKS:
   • Go to Authentication > Templates
   • Check if email verification template is configured
   • Verify SMTP settings under Templates > SMTP

3. EMAIL DELIVERY ISSUES:
   • Zoho might be filtering/blocking emails
   • Check Zoho Mail Sent folder
   • Check Zoho SMTP logs/reports
   • Verify recipient email in allowed list

4. DOMAIN AUTHENTICATION:
   • Ensure SPF record includes Zoho
   • Verify DKIM is set up correctly
   • Check DMARC policy

5. RATE LIMITING:
   • Zoho has sending limits
   • Try waiting 15-30 minutes between attempts
   • Check Zoho account sending quotas

Common Solutions:
• Add your email to Zoho whitelist
• Check Zoho spam/quarantine
• Verify domain DNS settings
• Use different test email address
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zoho SMTP Debug Info'),
        content: SingleChildScrollView(
          child: Text(
            debugInfo,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Copy to clipboard would be nice but needs additional package
              print(debugInfo);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debug info printed to console')),
              );
              Navigator.pop(context);
            },
            child: const Text('Print to Console'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showZohoTroubleshootingSteps();
            },
            child: const Text('Zoho Steps'),
          ),
        ],
      ),
    );
  }

  // Show specific Zoho troubleshooting steps
  Future<void> _showZohoTroubleshootingSteps() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zoho SMTP Troubleshooting'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step 1: Check Firebase Console',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                  '• Go to Firebase Console > Authentication > Templates'),
              const Text('• Check "Email address verification" template'),
              const Text('• Verify SMTP settings are configured for Zoho'),
              const SizedBox(height: 16),
              const Text(
                'Step 2: Zoho Mail Admin',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Login to Zoho Mail Admin Console'),
              const Text('• Check SMTP settings and authentication'),
              const Text('• Verify sending limits and quotas'),
              const SizedBox(height: 16),
              const Text(
                'Step 3: Email Delivery',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Check Zoho Mail Sent folder'),
              const Text('• Look in recipient\'s spam/junk folder'),
              const Text('• Check Zoho delivery reports'),
              const SizedBox(height: 16),
              const Text(
                'Step 4: DNS & Domain',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Verify SPF record includes Zoho'),
              const Text('• Check DKIM configuration'),
              const Text('• Ensure domain is properly authenticated'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
