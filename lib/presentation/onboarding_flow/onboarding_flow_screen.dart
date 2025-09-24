import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'onboarding_flow.dart';

class OnboardingFlowScreen extends StatelessWidget {
  final Map<String, LottieComposition?>? preloadedAnimations;

  const OnboardingFlowScreen({
    Key? key,
    this.preloadedAnimations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OnboardingFlow(
      preloadedAnimations: preloadedAnimations,
    );
  }
}
