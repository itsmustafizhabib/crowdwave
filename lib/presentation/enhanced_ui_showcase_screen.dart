import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'post_package/enhanced_post_package_screen.dart';
import '../widgets/enhanced_card_widget.dart';
import '../widgets/animated_button_widget.dart';
import '../widgets/interactive_widgets.dart';

class EnhancedUIShowcaseScreen extends StatefulWidget {
  const EnhancedUIShowcaseScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedUIShowcaseScreen> createState() =>
      _EnhancedUIShowcaseScreenState();
}

class _EnhancedUIShowcaseScreenState extends State<EnhancedUIShowcaseScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));

    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAnimatedHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('✨ Enhanced Screens'),
                    SizedBox(height: 2.h),
                    _buildScreenShowcase(),
                    SizedBox(height: 4.h),
                    _buildSectionTitle('🎯 Interactive Buttons'),
                    SizedBox(height: 2.h),
                    _buildButtonShowcase(),
                    SizedBox(height: 4.h),
                    _buildSectionTitle('📱 Enhanced Cards'),
                    SizedBox(height: 2.h),
                    _buildCardShowcase(),
                    SizedBox(height: 4.h),
                    _buildSectionTitle('🎪 Interactive Widgets'),
                    SizedBox(height: 2.h),
                    _buildInteractiveShowcase(),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF001BB7),
                    const Color(0xFF0046FF),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8.w),
                  bottomRight: Radius.circular(8.w),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 6.w,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enhanced UI Showcase',
                        style: TextStyle(
                          fontSize: 20.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Beautiful, Interactive Components',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildScreenShowcase() {
    return Column(
      children: [
        EnhancedCardWidget(
          child: ListTile(
            leading: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00C851), Color(0xFF007E33)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_box, color: Colors.white, size: 6.w),
            ),
            title: Text(
              'Enhanced Post Package',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Step-by-step form with smooth animations'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnhancedPostPackageScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildButtonShowcase() {
    return Column(
      children: [
        // Elevated Buttons
        Row(
          children: [
            Expanded(
              child: AnimatedButton(
                text: 'Elevated',
                type: AnimatedButtonType.elevated,
                onPressed: () => _showMessage('Elevated Button Pressed!'),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: AnimatedButton(
                text: 'Outlined',
                type: AnimatedButtonType.outlined,
                onPressed: () => _showMessage('Outlined Button Pressed!'),
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Gradient Buttons
        Row(
          children: [
            Expanded(
              child: AnimatedButton(
                text: 'Gradient',
                type: AnimatedButtonType.gradient,
                icon: Icons.star,
                onPressed: () => _showMessage('Gradient Button Pressed!'),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: AnimatedButton(
                text: 'Glass',
                type: AnimatedButtonType.glass,
                icon: Icons.water_drop,
                onPressed: () => _showMessage('Glass Button Pressed!'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardShowcase() {
    return Column(
      children: [
        // Basic Enhanced Card
        EnhancedCardWidget(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enhanced Card',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'This card has interactive hover effects and smooth animations.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          onTap: () => _showMessage('Enhanced Card Tapped!'),
        ),

        SizedBox(height: 2.h),

        // Gradient Card
        GradientCardWidget(
          gradientColors: [
            const Color(0xFF001BB7),
            const Color(0xFF0046FF),
          ],
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gradient Card',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Beautiful gradient backgrounds with smooth interactions.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          onTap: () => _showMessage('Gradient Card Tapped!'),
        ),

        SizedBox(height: 2.h),

        // Glass Morphism Card
        GlassMorphismCard(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Glass Morphism Card',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Modern glass effect with transparency and blur.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          onTap: () => _showMessage('Glass Card Tapped!'),
        ),
      ],
    );
  }

  Widget _buildInteractiveShowcase() {
    final sampleItems = [
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001BB7), Color(0xFF0046FF)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Swipeable Card 1\n👈 Swipe me! 👉',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C851), Color(0xFF007E33)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Swipeable Card 2\n👈 Swipe me! 👉',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF8040), Color(0xFFFF5722)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Swipeable Card 3\n👈 Swipe me! 👉',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ];

    return Column(
      children: [
        // Carousel Widget
        Text(
          'Carousel with Auto-play',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 2.h),
        CarouselWidget(
          height: 25.h,
          items: sampleItems,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 3),
          onPageChanged: (index) {
            _showMessage('Carousel page changed to $index');
          },
        ),

        SizedBox(height: 4.h),

        // Swipeable Cards
        Text(
          'Swipeable Cards (Tinder-style)',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 30.h,
          child: SwipeableCard(
            onSwipeLeft: () => _showMessage('Swiped Left! 👈'),
            onSwipeRight: () => _showMessage('Swiped Right! 👉'),
            onTap: () => _showMessage('Card Tapped!'),
            child: sampleItems[0],
          ),
        ),
      ],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF001BB7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
