import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:lottie/lottie.dart';
import '../../../core/app_export.dart';

class OnboardingPageWidget extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final bool doubleScale;
  final LottieComposition? preloadedAnimation;

  const OnboardingPageWidget({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.description,
    this.doubleScale = false,
    this.preloadedAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 80.w,
              height: 35.h,
              margin: EdgeInsets.only(bottom: 6.h),
              child: (imageUrl.toLowerCase().endsWith('.lottie') ||
                      imageUrl.toLowerCase().endsWith('.json'))
                  ? (doubleScale
                      ? Transform.scale(
                          scale: 2,
                          child: preloadedAnimation != null
                              ? Lottie(
                                  composition: preloadedAnimation,
                                  width: 80.w,
                                  height: 35.h,
                                  fit: BoxFit.contain,
                                )
                              : Lottie.asset(
                                  imageUrl,
                                  width: 80.w,
                                  height: 35.h,
                                  fit: BoxFit.contain,
                                ),
                        )
                      : preloadedAnimation != null
                          ? Lottie(
                              composition: preloadedAnimation,
                              width: 80.w,
                              height: 35.h,
                              fit: BoxFit.contain,
                            )
                          : Lottie.asset(
                              imageUrl,
                              width: 80.w,
                              height: 35.h,
                              fit: BoxFit.contain,
                            ))
                  : CustomImageWidget(
                      imageUrl: imageUrl,
                      width: 80.w,
                      height: 35.h,
                      fit: BoxFit.contain,
                    ),
            ),

            // Title
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 3.h),

            // Description
            Text(
              description,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
