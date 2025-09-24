import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../onboarding_flow/onboarding_flow_screen.dart';
import '../../services/animation_preload_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _masterController;
  late AnimationController _pulseController;
  late AnimationController _logoSlideController;

  late Animation<double> _logoFade;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textPosition;
  late Animation<double> _loadingWidth;
  late Animation<double> _truckPosition;
  late Animation<double> _barHeight;
  late Animation<double> _pulseOpacity;
  late Animation<double> _gradientRotation;
  late Animation<Offset> _logoSlide;

  bool _isTransitioning = false;
  bool _resourcesPrecached = false;
  bool _controllersInitialized = false;

  // Animation preload service
  final AnimationPreloadService _animationService = AnimationPreloadService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize controllers first
    _masterController = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_isTransitioning) {
          _navigateToNextScreen(); // Navigate directly after main animation
        }
      });

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _logoSlideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _precacheResources().then((_) {
      if (mounted) {
        setState(() {
          _resourcesPrecached = true;
        });
        _setupAnimations();
        _startAnimationSequence();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _resourcesPrecached) {
      // Restart animations if app comes back to foreground
      _setupAnimations();
      _startAnimationSequence();
    }
  }

  Future<void> _precacheResources() async {
    // Precache SVG logo (flutter_svg caches on first load, so we can precache bytes)
    await DefaultAssetBundle.of(context).loadString('assets/images/logo.svg');

    // Preload onboarding animations during splash screen using the service
    await _animationService.preloadAnimations([
      'assets/animations/onboarding_cost_effective_delivery.json',
      'assets/animations/eran.json',
      'assets/animations/Payment.json',
      'assets/animations/trust.json',
    ]);

    // Force a frame to ensure everything is loaded
    await Future.delayed(const Duration(milliseconds: 16));
  }

  void _setupAnimations() {
    // Logo slide animation - starts slightly lower and moves up
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.1), // Start 10% lower
      end: Offset.zero, // End at normal position
    ).animate(CurvedAnimation(
      parent: _logoSlideController,
      curve: Curves.easeOut,
    ));

    // Logo fade in at the beginning
    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
    ));

    // Text opacity - fades in and stays visible
    _textOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.0), weight: 3), // Reduced
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _masterController,
      curve: Curves.easeInOut,
    ));

    // Text position - enters from left, centers, then exits right
    _textPosition = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(-1.5, 0.0), end: Offset.zero),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: Offset.zero),
        weight: 2, // Reduced
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: const Offset(1.5, 0.0)),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _masterController,
      curve: Curves.easeInOut,
    ));

    // Loading bar width
    _loadingWidth = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.2, 0.7,
          curve: Curves.easeInOut), // Adjusted interval
    ));

    // Truck position - moves across the loading bar
    _truckPosition = Tween<double>(
      begin: -0.1,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.2, 0.7,
          curve: Curves.easeInOut), // Adjusted interval
    ));

    // Loading bar height animation for a polished look
    _barHeight = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.5.h), weight: 1),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.5.h, end: 1.5.h), weight: 6), // Reduced
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.5.h, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _masterController,
      curve: Curves.easeInOut,
    ));

    // Pulse opacity for the gradient effect
    _pulseOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.15), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.15, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Gradient rotation for dynamic lighting effect
    _gradientRotation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159, // Full rotation in radians
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.linear,
    ));

    setState(() {
      _controllersInitialized = true;
    });
  }

  void _disposeControllers() {
    if (_masterController.isAnimating) _masterController.stop();
    if (_pulseController.isAnimating) _pulseController.stop();
    if (_logoSlideController.isAnimating) _logoSlideController.stop();

    _masterController.dispose();
    _pulseController.dispose();
    _logoSlideController.dispose();
  }

  Future<void> _startAnimationSequence() async {
    if (!mounted) return;

    // Set system UI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Start the logo slide animation immediately
    _logoSlideController.forward();

    // Start the pulse animation
    _pulseController.repeat(reverse: true);

    // Start the master animation after a short delay
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _masterController.forward();
    }
  }

  void _navigateToNextScreen() async {
    if (!mounted || _isTransitioning) return;

    _isTransitioning = true;

    // Add a small delay to ensure the animation is fully rendered
    await Future.delayed(const Duration(milliseconds: 50));

    if (mounted) {
      // Use a fade transition for smoother navigation and pass preloaded animations
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              OnboardingFlowScreen(
            preloadedAnimations: _animationService.getAllPreloadedAnimations(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOut;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_resourcesPrecached) {
      // Show a simple white screen with logo to avoid blank screen
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SvgPicture.asset(
            'assets/images/logo.svg',
            width: 30.w,
            height: 30.w,
          ),
        ),
      );
    }

    if (!_controllersInitialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _masterController,
          _pulseController,
          _logoSlideController,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Subtle gradient lightning effect from corners
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _pulseOpacity.value,
                      child: Transform.rotate(
                        angle: _gradientRotation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.5,
                              colors: [
                                Colors.blue.withOpacity(0.1),
                                Colors.transparent,
                                Colors.orange.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.3, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with fade in and slide up animation
                    SlideTransition(
                      position: _logoSlide,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue
                                    .withOpacity(0.1 * _pulseOpacity.value),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/images/logo.svg',
                            fit: BoxFit.contain,
                            width: 40.w,
                            height: 40.w,
                            placeholderBuilder: (context) => Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8.w),
                              ),
                              child: Center(
                                child: Text(
                                  'CW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.w,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 5.h),

                    // App name with smooth entrance and exit
                    SlideTransition(
                      position: _textPosition,
                      child: FadeTransition(
                        opacity: _textOpacity,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue[800]!,
                                    Colors.orange[700]!,
                                  ],
                                  stops: const [0.3, 0.7],
                                ).createShader(bounds);
                              },
                              child: Text(
                                'CrowdWave',
                                style: TextStyle(
                                  fontSize: 10.w,
                                  fontWeight: FontWeight.w900,
                                  color: Colors
                                      .white, // This will be overridden by the gradient
                                  letterSpacing: 1.0,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Tagline
                    SlideTransition(
                      position: _textPosition,
                      child: FadeTransition(
                        opacity: _textOpacity,
                        child: Text(
                          'Deliver Together, Earn Together',
                          style: TextStyle(
                            fontSize: 4.5.w,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 10.h),

                    // YouTube-style loading bar with truck - appears and disappears smoothly
                    AnimatedBuilder(
                      animation: _masterController,
                      builder: (context, child) {
                        return Container(
                          width: 70.w,
                          height: _barHeight.value,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                              BoxShadow(
                                color: Colors.blue
                                    .withOpacity(0.1 * _pulseOpacity.value),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Loading progress with gradient
                              Container(
                                width: 70.w * _loadingWidth.value,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue[800]!,
                                      Colors.blue[600]!,
                                      Colors.blue[400]!,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(
                                          0.3 + 0.1 * _pulseOpacity.value),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),

                              // Moving truck icon with shadow - changed to orange
                              Positioned(
                                left: (70.w - 4.h) * _truckPosition.value,
                                top: -1.2.h,
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.local_shipping,
                                    color:
                                        Colors.orange[700], // Changed to orange
                                    size: 4.h,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
