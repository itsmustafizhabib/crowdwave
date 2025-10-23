import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/home/updated_home_screen.dart';
import '../presentation/screens/auth/login_view.dart';
import '../presentation/screens/auth/signUp_view.dart';
import '../presentation/screens/auth/password_reset_with_code_view.dart';
import '../presentation/screens/auth/email_verification_screen.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/post_package/post_package_screen.dart';
import '../presentation/post_package/enhanced_post_package_screen.dart';
import '../presentation/post_trip/post_trip_screen.dart';
import '../presentation/enhanced_ui_showcase_screen.dart';
import '../presentation/main_navigation/main_navigation_screen.dart';
import '../presentation/screens/kyc/kyc_completion_screen.dart';
import '../presentation/profile/profile_options_screen.dart';
import '../presentation/screens/matching/matching_screen.dart';
import '../presentation/notifications/notification_screen.dart';
import '../presentation/chat/chat_screen.dart';
import '../presentation/chat/individual_chat_screen.dart';
import '../presentation/tracking/tracking_history_screen.dart';
import '../presentation/travel/travel_screen.dart';
import '../utils/email_test_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String updatedHome = '/updated-home';
  static const String mainNavigation = '/main-navigation';
  static const String login = '/login-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String registration = '/registration-screen';
  static const String postPackage = '/post-package';
  static const String postTrip = '/post-trip';
  static const String enhancedPostPackage = '/enhanced-post-package';
  static const String uiShowcase = '/ui-showcase';
  static const String kycCompletion = '/kyc-completion';
  static const String profileOptions = '/profile-options';
  static const String matching = '/matching';
  static const String notifications = '/notifications';
  static const String bookingConfirmation = '/booking-confirmation';
  static const String paymentMethod = '/payment-method';
  static const String paymentProcessing = '/payment-processing';
  static const String bookingSuccess = '/booking-success';
  static const String paymentFailure = '/payment-failure';
  static const String emailTest = '/email-test';
  static const String passwordReset = '/password-reset';
  static const String emailVerification = '/email-verification';
  static const String chat = '/chat';
  static const String individualChat = '/individual-chat';
  static const String packageTracking = '/tracking';
  static const String trackingHistory = '/tracking-history';
  static const String trackingStatusUpdate = '/tracking-status-update';
  static const String travel = '/travel';

  static Map<String, WidgetBuilder> get routes {
    final Map<String, WidgetBuilder> appRoutes = {
      splash: (context) => const SplashScreen(),
      updatedHome: (context) => const UpdatedHomeScreen(),
      mainNavigation: (context) => const MainNavigationScreen(),
      login: (context) => const LoginView(),
      onboardingFlow: (context) => const OnboardingFlow(),
      registration: (context) => const SignUpView(),
      postPackage: (context) => const PostPackageScreen(),
      postTrip: (context) => const PostTripScreen(),
      enhancedPostPackage: (context) => const EnhancedPostPackageScreen(),
      uiShowcase: (context) => const EnhancedUIShowcaseScreen(),
      kycCompletion: (context) => const KYCCompletionScreen(),
      profileOptions: (context) => const ProfileOptionsScreen(),
      matching: (context) => const MatchingScreen(),
      notifications: (context) => const NotificationScreen(),
      emailTest: (context) => const EmailTestScreen(),
      passwordReset: (context) => const PasswordResetWithCodeView(),
      emailVerification: (context) => const EmailVerificationScreen(),
      chat: (context) => const ChatScreen(),
      individualChat: (context) => const IndividualChatScreen(
            conversationId: '',
            otherUserName: '',
            otherUserId: '',
          ),
      trackingHistory: (context) => const TrackingHistoryScreen(),
      travel: (context) => const TravelScreen(),

      // ✅ Payment Flow Routes - FIXED
      bookingConfirmation: (context) {
        // This will be handled dynamically with arguments
        return Scaffold(
            body: Center(
                child: Text('error_messages.route_requires_arguments'.tr())));
      },
      paymentMethod: (context) {
        // This will be handled dynamically with arguments
        return Scaffold(
            body: Center(
                child: Text('error_messages.route_requires_arguments'.tr())));
      },
      paymentProcessing: (context) {
        // This will be handled dynamically with arguments
        return const Scaffold(
            body:
                Center(child: Text('error_messages.route_requires_arguments')));
      },
      bookingSuccess: (context) {
        // This will be handled dynamically with arguments
        return const Scaffold(
            body:
                Center(child: Text('error_messages.route_requires_arguments')));
      },
      paymentFailure: (context) {
        // This will be handled dynamically with arguments
        return const Scaffold(
            body:
                Center(child: Text('error_messages.route_requires_arguments')));
      },

      // Booking and tracking routes with arguments will be handled dynamically
    };

    return appRoutes;
  }
}
