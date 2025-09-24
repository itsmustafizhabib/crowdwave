import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import 'login_view.dart';
import '../../../core/constants.dart';
import '../../../controllers/simple_ui_controller.dart';
import '../../../services/enhanced_firebase_auth_service.dart';
import '../../../services/username_service.dart';
import '../../../services/user_profile_service.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/validation_messages.dart';
import '../../../core/error_handler.dart';
import '../../../routes/app_routes.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({Key? key}) : super(key: key);

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Focus nodes to track field focus
  FocusNode passwordFocusNode = FocusNode();
  bool isPasswordFocused = false;

  // Username availability checking
  bool isCheckingUsername = false;
  bool? isUsernameAvailable;
  String? lastCheckedUsername;

  // Signup loading state
  bool isSigningUp = false;

  final _formKey = GlobalKey<FormState>();
  final EnhancedFirebaseAuthService _authService = EnhancedFirebaseAuthService();
  final UsernameService _usernameService = UsernameService();
  final UserProfileService _userProfileService = UserProfileService();

  @override
  void initState() {
    super.initState();
    // Add listener to password focus node
    passwordFocusNode.addListener(() {
      setState(() {
        isPasswordFocused = passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  SimpleUIController simpleUIController = Get.put(SimpleUIController());

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return SafeArea(
                child: _buildLargeScreen(size, simpleUIController, theme),
              );
            } else {
              return _buildSmallScreenWithFullTopAnimation(
                  size, simpleUIController, theme);
            }
          },
        ),
      ),
    );
  }

  /// For large screens
  Widget _buildLargeScreen(
      Size size, SimpleUIController simpleUIController, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: RotatedBox(
            quarterTurns: 3,
            child: Lottie.asset(
              'assets/animations/coin.json',
              height: size.height * 0.3,
              width: double.infinity,
              fit: BoxFit.fill,
            ),
          ),
        ),
        SizedBox(width: size.width * 0.06),
        Expanded(
          flex: 5,
          child: _buildMainBody(size, simpleUIController, theme),
        ),
      ],
    );
  }

  /// For Small screens with full-top animation (no gap)
  Widget _buildSmallScreenWithFullTopAnimation(
      Size size, SimpleUIController simpleUIController, ThemeData theme) {
    return Column(
      children: [
        // Wave animation positioned at the very top with no gap
        Lottie.asset(
          'assets/animations/wave.json',
          height: size.height * 0.15, // Reduced by 25% (was 0.2, now 0.15)
          width: size.width,
          fit: BoxFit.fill,
        ),
        // Content wrapped in SafeArea to avoid status bar overlap
        Expanded(
          child: SafeArea(
            top: false, // Don't add top padding since animation handles the top
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildMainBodyWithoutAnimation(
                size,
                simpleUIController,
                theme,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Main Body
  Widget _buildMainBody(
      Size size, SimpleUIController simpleUIController, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment:
          size.width > 600 ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        size.width > 600
            ? Container()
            : Lottie.asset(
                'assets/animations/wave.json',
                height:
                    size.height * 0.15, // Reduced by 25% (was 0.2, now 0.15)
                width: size.width,
                fit: BoxFit.fill,
              ),
        SizedBox(
          height: size.height * 0.03,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text(
            'Sign Up',
            style: kLoginTitleStyle(size),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text(
            'Create Account',
            style: kLoginSubtitleStyle(size),
          ),
        ),
        SizedBox(
          height: size.height * 0.03,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                /// username
                TextFormField(
                  style: kTextFormFieldStyle(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: _getUsernameSuffixIcon(),
                    hintText: 'Username',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                  controller: nameController,
                  onChanged: (value) {
                    final trimmedValue = value.trim();
                    if (trimmedValue.length >= 3) {
                      _checkUsernameAvailability(trimmedValue);
                    } else {
                      setState(() {
                        isUsernameAvailable = null;
                        isCheckingUsername = false;
                        lastCheckedUsername = null;
                      });
                    }
                  },
                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username is required';
                    } else if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    } else if (value.length > 30) {
                      return 'Username cannot exceed 30 characters';
                    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Username can only contain letters, numbers, and underscores';
                    } else if (isUsernameAvailable == false) {
                      return 'This username is already taken';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: size.height * 0.02,
                ),

                /// Gmail
                TextFormField(
                  style: kTextFormFieldStyle(),
                  controller: emailController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_rounded),
                    hintText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: size.height * 0.02,
                ),

                /// password
                Obx(
                  () => TextFormField(
                    style: kTextFormFieldStyle(),
                    controller: passwordController,
                    focusNode: passwordFocusNode,
                    obscureText: simpleUIController.isObscure.value,
                    onChanged: (value) {
                      // Trigger rebuild to update password requirements
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_open),
                      suffixIcon: IconButton(
                        icon: Icon(
                          simpleUIController.isObscure.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          simpleUIController.isObscureActive();
                        },
                      ),
                      hintText: 'Password',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      errorMaxLines: 3,
                      errorText:
                          (isPasswordFocused && passwordController.text.isEmpty)
                              ? _getPasswordRequirements()
                              : null,
                    ),
                    // The validator receives the text that the user has entered.
                    validator: (value) {
                      // Only validate if field is not focused (after user moves away) or has text
                      if (!isPasswordFocused ||
                          (value != null && value.isNotEmpty)) {
                        return _validatePassword(value);
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  height: size.height * 0.02,
                ),
                Text(
                  'Creating an account means you\'re okay with our Terms of Services and our Privacy Policy',
                  style: kLoginTermsAndPrivacyStyle(size),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: size.height * 0.02,
                ),

                /// SignUp Button
                signUpButton(theme),
                SizedBox(
                  height: size.height * 0.02,
                ),

                /// Social Login Buttons
                socialLoginButtons(),
                SizedBox(
                  height: size.height * 0.03,
                ),

                /// Navigate To Login Screen
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (ctx) => const LoginView()));
                    nameController.clear();
                    emailController.clear();
                    passwordController.clear();
                    _formKey.currentState?.reset();

                    simpleUIController.isObscure.value = true;
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account?',
                      style: kHaveAnAccountStyle(size),
                      children: [
                        TextSpan(
                            text: " Login",
                            style: kLoginOrSignUpTextStyle(size)),
                      ],
                    ),
                  ),
                ),
                // Add bottom padding for keyboard
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Main Body Without Animation (for when animation is positioned separately)
  Widget _buildMainBodyWithoutAnimation(
      Size size, SimpleUIController simpleUIController, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text(
            'Sign Up',
            style: kLoginTitleStyle(size),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text(
            'Create Account',
            style: kLoginSubtitleStyle(size),
          ),
        ),
        SizedBox(
          height: size.height * 0.03,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                /// Username
                TextFormField(
                  controller: nameController,
                  style: kTextFormFieldStyle(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: _getUsernameSuffixIcon(),
                    hintText: 'Username',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                  onChanged: (value) {
                    final trimmedValue = value.trim();
                    if (trimmedValue.length >= 3) {
                      _checkUsernameAvailability(trimmedValue);
                    } else {
                      setState(() {
                        isUsernameAvailable = null;
                        isCheckingUsername = false;
                        lastCheckedUsername = null;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    } else if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    } else if (value.length > 30) {
                      return 'Username must be less than 30 characters';
                    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Username can only contain letters, numbers, and underscores';
                    } else if (isUsernameAvailable == false) {
                      return 'This username is already taken';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: size.height * 0.02,
                ),

                /// email
                TextFormField(
                  controller: emailController,
                  style: kTextFormFieldStyle(),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_rounded),
                    hintText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                  validator: (value) {
                    return ValidationMessages.validateEmail(value);
                  },
                ),
                SizedBox(
                  height: size.height * 0.02,
                ),

                /// password
                Obx(
                  () => TextFormField(
                    controller: passwordController,
                    style: kTextFormFieldStyle(),
                    obscureText: simpleUIController.isObscure.value,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_open),
                      suffixIcon: IconButton(
                        onPressed: simpleUIController.isObscureActive,
                        icon: Icon(
                          simpleUIController.isObscure.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                      hintText: 'Password',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      errorMaxLines: 3,
                    ),
                    // The validator receives the text that the user has entered.
                    validator: (value) {
                      return _validatePassword(value);
                    },
                    // Auto-validate when user starts typing
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                ),
                SizedBox(
                  height: size.height * 0.02,
                ),
                Text(
                  'Creating an account means you\'re okay with our Terms of Services and our Privacy Policy',
                  style: kLoginTermsAndPrivacyStyle(size),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: size.height * 0.02,
                ),

                /// SignUp Button
                signUpButton(theme),
                SizedBox(
                  height: size.height * 0.02,
                ),

                /// Social Login Buttons
                socialLoginButtons(),
                SizedBox(
                  height: size.height * 0.03,
                ),

                /// Navigate To Login Screen
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (ctx) => const LoginView()));
                    nameController.clear();
                    emailController.clear();
                    passwordController.clear();
                    _formKey.currentState?.reset();

                    simpleUIController.isObscure.value = true;
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account?',
                      style: kHaveAnAccountStyle(size),
                      children: [
                        TextSpan(
                            text: " Login",
                            style: kLoginOrSignUpTextStyle(size)),
                      ],
                    ),
                  ),
                ),
                // Add bottom padding for keyboard
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // SignUp Button
  Widget signUpButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.deepPurpleAccent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        onPressed: isSigningUp
            ? null
            : () async {
                // Validate returns true if the form is valid, or false otherwise.
                if (_formKey.currentState!.validate()) {
                  // Set loading state
                  setState(() {
                    isSigningUp = true;
                  });

                  try {
                    final username = nameController.text.trim();

                    // Check if we have a cached result for this username
                    if (lastCheckedUsername != username ||
                        isUsernameAvailable != true) {
                      // Re-check username availability if not cached or not available
                      final isAvailable =
                          await _usernameService.isUsernameAvailable(username);

                      if (!isAvailable) {
                        _showCustomSnackbar('Error',
                            'Username is already taken. Please choose another one.',
                            isError: true);
                        setState(() {
                          isUsernameAvailable = false;
                          lastCheckedUsername = username;
                          isSigningUp = false;
                        });
                        return;
                      }
                    }

                    // Create the Firebase Auth user
                    final user =
                        await _authService.registerWithEmailAndPassword(
                      emailController.text.trim(),
                      passwordController.text.trim(),
                    );

                    if (user != null) {
                      // Reserve the username
                      await _usernameService.reserveUsername(
                          username, user.uid);

                      // Send verification email BEFORE creating profile and signing out
                      try {
                        await _authService.sendEmailVerification();
                        print(
                            '✅ Email verification sent successfully to: ${user.email}');
                        debugPrint('Email verification sent successfully');
                      } catch (e) {
                        // Don't block signup if email verification fails
                        print('❌ Email verification failed: $e');
                        debugPrint('Email verification failed: $e');

                        // Show specific error to user
                        _showCustomSnackbar('Email Issue',
                            'Account created but verification email failed. Please check spam folder or try resending later.',
                            isError: true);
                      }

                      // Create user profile with username
                      final userProfile = UserProfile(
                        uid: user.uid,
                        email: emailController.text.trim(),
                        fullName:
                            username, // For now, use username as display name
                        username: username,
                        dateOfBirth: DateTime.now().subtract(
                            const Duration(days: 6570)), // Default 18 years ago
                        role: UserRole.sender, // Default role
                        verificationStatus: VerificationStatus(
                          emailVerified: user.emailVerified,
                          phoneVerified: false,
                          identityVerified: false,
                        ),
                        ratings: UserRatings(
                          averageRating: 0.0,
                          totalRatings: 0,
                          fiveStars: 0,
                          fourStars: 0,
                          threeStars: 0,
                          twoStars: 0,
                          oneStar: 0,
                          recentReviews: [],
                        ),
                        stats: UserStats(
                          totalDeliveries: 0,
                          totalPackagesSent: 0,
                          completedTrips: 0,
                          totalEarnings: 0.0,
                          totalSpent: 0.0,
                          reliabilityScore: 100.0,
                          onTimeDeliveries: 0,
                          lateDeliveries: 0,
                        ),
                        preferences: UserPreferences(
                          allowsNotifications: true,
                          allowsEmailMarketing: false,
                          allowsSMSNotifications: true,
                          preferredLanguage: 'en',
                          preferredCurrency: 'USD',
                          preferredTransportModes: [],
                        ),
                        createdAt: DateTime.now(),
                        lastActiveAt: DateTime.now(),
                      );

                      // Save the user profile to Firestore
                      await _userProfileService.createUserProfile(userProfile);

                      // Show success message
                      _showCustomSnackbar('Success',
                          'Account created! Please verify your email before logging in. Check your inbox!');

                      // Sign out the user so they must verify email first
                      await _authService.signOut();

                      // Navigate back to login screen
                      Get.offAllNamed(AppRoutes.login);
                    }
                  } catch (e) {
                    // Reset loading state on error
                    setState(() {
                      isSigningUp = false;
                    });

                    _showCustomSnackbar(
                        'Error', e.toString().replaceFirst('Exception: ', ''),
                        isError: true);
                  }
                } else {
                  // Reset loading state if validation fails
                  setState(() {
                    isSigningUp = false;
                  });
                }
              },
        child: isSigningUp
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Creating Account...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Text(
                'Sign up',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  // Social Login Buttons
  Widget socialLoginButtons() {
    return Column(
      children: [
        // Divider with "or" text
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[400])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[400])),
          ],
        ),
        const SizedBox(height: 16),

        // Compact Social Login Buttons Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Google Button
            _socialIconButton(
              iconPath: 'assets/icons8-google-color/icons8-google-48.png',
              onPressed: () async {
                try {
                  final user = await _authService.signInWithGoogle();
                  if (user != null) {
                    _showCustomSnackbar('Success', 'Google signup successful!');
                    Get.offAllNamed('/main-navigation');
                  }
                } catch (e) {
                  _showCustomSnackbar('Error', ErrorHandler.getReadableError(e),
                      isError: true);
                }
              },
            ),

            // Facebook Button
            _socialIconButton(
              iconPath:
                  'assets/images/facebook-icon.png', // You'll need to add this
              onPressed: () async {
                try {
                  final user = await _authService.signInWithFacebook();
                  if (user != null) {
                    _showCustomSnackbar(
                        'Success', 'Facebook signup successful!');
                    Get.offAllNamed('/main-navigation');
                  }
                } catch (e) {
                  _showCustomSnackbar('Error', ErrorHandler.getReadableError(e),
                      isError: true);
                }
              },
            ),

            // Apple Button
            _socialIconButton(
              iconPath:
                  'assets/icons8-apple-ios-17-outlined/icons8-apple-100.png',
              onPressed: () async {
                try {
                  final user = await _authService.signInWithApple();
                  if (user != null) {
                    _showCustomSnackbar('Success', 'Apple signup successful!');
                    Get.offAllNamed('/main-navigation');
                  }
                } catch (e) {
                  _showCustomSnackbar('Error', ErrorHandler.getReadableError(e),
                      isError: true);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  // Helper method for social icon buttons
  Widget _socialIconButton({
    required String iconPath,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Image.asset(
          iconPath,
          height: 28,
          width: 28,
        ),
      ),
    );
  }

  // Helper method to get password requirements text
  String? _getPasswordRequirements() {
    // Always show requirements when focused, regardless of input
    return 'At least 8 characters including 1 uppercase letter, 1 lowercase letter, 1 number and 1 special character';
  }

  // Method to check username availability with debouncing
  void _checkUsernameAvailability(String username) async {
    if (username.length < 3) {
      setState(() {
        isUsernameAvailable = null;
        isCheckingUsername = false;
        lastCheckedUsername = null;
      });
      return;
    }

    // Don't check the same username again
    if (lastCheckedUsername == username) return;

    setState(() {
      isCheckingUsername = true;
      isUsernameAvailable = null;
    });

    try {
      // Add a small delay for debouncing
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if the username field value hasn't changed during the delay
      if (nameController.text.trim() != username) return;

      final available = await _usernameService.isUsernameAvailable(username);

      setState(() {
        isUsernameAvailable = available;
        isCheckingUsername = false;
        lastCheckedUsername = username;
      });

      // Show notification only when username is taken
      if (!available) {
        _showCustomSnackbar('Oops!', 'Username "$username" is already taken',
            isError: true);
      }
    } catch (e) {
      setState(() {
        isCheckingUsername = false;
        isUsernameAvailable = null;
      });
    }
  }

  // Get suffix icon for username field
  Widget? _getUsernameSuffixIcon() {
    if (isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      );
    } else if (isUsernameAvailable == true) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
      );
    } else if (isUsernameAvailable == false) {
      return const Icon(
        Icons.warning,
        color: Colors.red,
      );
    }
    return null;
  }

  // Password validation method - Updated to use ValidationMessages
  String? _validatePassword(String? value) {
    return ValidationMessages.validatePassword(value);
  }

  // Enhanced snackbar method
  void _showCustomSnackbar(String title, String message,
      {bool isError = false, bool isInfo = false}) {
    Color backgroundColor;
    IconData iconData;

    if (isError) {
      backgroundColor = Colors.red.shade600;
      iconData = Icons.error_outline;
    } else if (isInfo) {
      backgroundColor = Colors.blue.shade600;
      iconData = Icons.info_outline;
    } else {
      backgroundColor = Colors.green.shade600;
      iconData = Icons.check_circle_outline;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      icon: Icon(
        iconData,
        color: Colors.white,
        size: 28,
      ),
      shouldIconPulse: false,
      duration: const Duration(seconds: 4),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
