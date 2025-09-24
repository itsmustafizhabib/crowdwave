import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_state_service.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/main_navigation/main_navigation_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStateService>(
      builder: (context, authState, child) {
        // Show loading screen while checking auth state
        if (authState.isLoading) {
          return SplashScreen();
        }

        // If user is signed in, go to main navigation with 5 tabs
        if (authState.isAuthenticated) {
          return MainNavigationScreen();
        }

        // If user is not signed in, go to onboarding flow (without preloaded animations since we come directly here)
        return OnboardingFlow();
      },
    );
  }
}
