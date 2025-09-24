import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:lottie/lottie.dart';

import '../../core/app_export.dart';
import '../../services/animation_preload_service.dart';
import './widgets/navigation_controls_widget.dart';
import './widgets/onboarding_page_widget.dart';
import './widgets/page_indicator_widget.dart';

class OnboardingFlow extends StatefulWidget {
  final Map<String, LottieComposition?>? preloadedAnimations;

  const OnboardingFlow({
    Key? key,
    this.preloadedAnimations,
  }) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;

  // Map to store preloaded animations - either from splash screen or loaded here
  late Map<String, LottieComposition?> _preloadedAnimations;
  bool _isPreloading = false;

  // Animation service for background loading
  final AnimationPreloadService _animationService = AnimationPreloadService();
  // Removed _showRoleSelection since it's no longer needed

  final List<Map<String, String>> _onboardingData = [
    {
      'image': 'assets/animations/onboarding_cost_effective_delivery.json',
      'title': 'Cost-Effective Delivery',
      'description':
          'Send packages with travelers going your way and save up to 70% on delivery costs compared to traditional services.',
    },
    {
      'image': 'assets/animations/eran.json',
      'title': 'Earn While Traveling',
      'description':
          'Turn your trips into income opportunities by delivering packages for others along your route.',
    },
    {
      'image': 'assets/animations/Payment.json',
      'title': 'Secure Payments',
      'description':
          'All transactions are protected with escrow payments, ensuring safe and reliable exchanges for everyone.',
    },
    {
      'image': 'assets/animations/trust.json',
      'title': 'Community Trust',
      'description':
          'Join a verified community with ratings, reviews, and identity verification for peace of mind.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();

    // Use preloaded animations if available, otherwise load them
    if (widget.preloadedAnimations != null) {
      _preloadedAnimations = Map.from(widget.preloadedAnimations!);
      _isPreloading = false;
      _preloadAdditionalAnimations(); // Load any missing animations in background
    } else {
      _preloadedAnimations = {};
      _isPreloading = true;
      // Preload all animations if not provided
      _preloadAnimations();
    }
  }

  // Preload all Lottie animations to prevent delays
  Future<void> _preloadAnimations() async {
    for (var data in _onboardingData) {
      final animationPath = data['image']!;
      if (animationPath.endsWith('.json') ||
          animationPath.endsWith('.lottie')) {
        try {
          final composition = await AssetLottie(animationPath).load();
          _preloadedAnimations[animationPath] = composition;
        } catch (e) {
          print('Error preloading animation $animationPath: $e');
          _preloadedAnimations[animationPath] = null;
        }
      }
    }

    if (mounted) {
      setState(() {
        _isPreloading = false;
      });
    }
  }

  // Load any missing animations in the background using the service
  Future<void> _preloadAdditionalAnimations() async {
    final List<String> missingAnimations = [];

    for (var data in _onboardingData) {
      final animationPath = data['image']!;
      if ((animationPath.endsWith('.json') ||
              animationPath.endsWith('.lottie')) &&
          !_preloadedAnimations.containsKey(animationPath)) {
        missingAnimations.add(animationPath);
      }
    }

    if (missingAnimations.isNotEmpty) {
      // Load missing animations in background
      for (String path in missingAnimations) {
        _animationService.preloadAnimation(path).then((composition) {
          if (mounted) {
            setState(() {
              _preloadedAnimations[path] = composition;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _triggerHapticFeedback();

      // Preload next page animations in background if not already loaded
      _preloadUpcomingPageAnimations(_currentPage + 1);
    } else {
      // Skip role selection and go directly to login screen
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  // Preload animations for upcoming pages while user is viewing current page
  void _preloadUpcomingPageAnimations(int upcomingPageIndex) {
    // Preload next 2 pages animations in background
    for (int i = upcomingPageIndex;
        i < _onboardingData.length && i < upcomingPageIndex + 2;
        i++) {
      final animationPath = _onboardingData[i]['image']!;
      if ((animationPath.endsWith('.json') ||
              animationPath.endsWith('.lottie')) &&
          !_preloadedAnimations.containsKey(animationPath) &&
          !_animationService.isAnimationLoading(animationPath)) {
        _animationService.preloadAnimation(animationPath).then((composition) {
          if (mounted) {
            setState(() {
              _preloadedAnimations[animationPath] = composition;
            });
          }
        });
      }
    }
  }

  void _skipOnboarding() {
    // Skip role selection and go directly to login screen
    Navigator.pushReplacementNamed(context, AppRoutes.login);
    _triggerHapticFeedback();
  }

  void _triggerHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: true,
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _isPreloading
              ? _buildLoadingWidget()
              : _buildOnboardingPages(), // Always show onboarding pages, no role selection
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Preparing experience...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPages() {
    return Column(
      children: [
        // Main content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              _triggerHapticFeedback();

              // Preload upcoming page animations when user swipes to new page
              _preloadUpcomingPageAnimations(index + 1);
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              final data = _onboardingData[index];
              // Only apply 2x scale to the first page (cost-effective delivery)
              final bool doubleScale = index == 0;
              final String imagePath = data['image']!;
              final LottieComposition? preloadedComposition =
                  _preloadedAnimations[imagePath];

              return OnboardingPageWidget(
                imageUrl: imagePath,
                title: data['title']!,
                description: data['description']!,
                doubleScale: doubleScale,
                preloadedAnimation: preloadedComposition,
              );
            },
          ),
        ),

        // Bottom section with indicators and navigation
        Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom + 4.h,
          ),
          child: Column(
            children: [
              // Page indicators
              PageIndicatorWidget(
                currentPage: _currentPage,
                totalPages: _onboardingData.length,
              ),

              SizedBox(height: 2.h),

              // Navigation controls
              NavigationControlsWidget(
                currentPage: _currentPage,
                totalPages: _onboardingData.length,
                onNext: _nextPage,
                onSkip: _skipOnboarding,
                // Removed onGetStarted parameter
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Removed _buildRoleSelection method since it's no longer needed
}
