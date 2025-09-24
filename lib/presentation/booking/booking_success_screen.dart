import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:share_plus/share_plus.dart';
import '../../core/models/booking.dart';
import '../../core/models/transaction.dart' show PaymentMethod;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../routes/tracking_route_handler.dart';
import '../../services/tracking_service.dart';
import '../../widgets/confetti_celebration_widget.dart';

/// 🎉 Booking Success Screen - Phase 2.3
/// Displays booking confirmation, payment receipt, and next steps
class BookingSuccessScreen extends StatefulWidget {
  final Booking booking;
  final stripe.PaymentIntent? paymentIntent;

  const BookingSuccessScreen({
    Key? key,
    required this.booking,
    this.paymentIntent,
  }) : super(key: key);

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCelebration();
  }

  void _initializeAnimations() {
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startCelebration() {
    _celebrationController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Share booking details
  Future<void> _shareBookingDetails() async {
    try {
      final booking = widget.booking;
      final paymentIntent = widget.paymentIntent;

      // Create sharing text with booking details
      final shareText = '''
🎉 CrowdWave Booking Confirmed!

📦 Booking ID: ${booking.id}
� Traveler: ${booking.travelerId}
💰 Total: \$${booking.totalAmount.toStringAsFixed(2)}
� Platform Fee: \$${booking.platformFee.toStringAsFixed(2)}
📅 Booked: ${booking.createdAt.day}/${booking.createdAt.month}/${booking.createdAt.year}
🎯 Status: ${booking.statusDisplayText}
${paymentIntent != null ? '✅ Payment: ${paymentIntent.status}' : ''}

Your package is now being handled by a trusted traveler!

Track your delivery: https://crowdwave.com/track/${booking.id}

Join CrowdWave - Where travelers and senders meet! 🌍
Download: https://crowdwave.com/app
      '''
          .trim();

      // Share using native sharing functionality
      await Share.share(
        shareText,
        subject: 'CrowdWave Booking Confirmation - ${booking.id}',
      );

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking details shared successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      // Handle sharing error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to share booking details'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  /// Copy booking ID to clipboard
  Future<void> _copyBookingId() async {
    await Clipboard.setData(ClipboardData(text: widget.booking.id));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Booking ID copied to clipboard'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  /// Navigate to chat with traveler
  void _chatWithTraveler() {
    Get.toNamed(
      AppRoutes.individualChat,
      arguments: {
        'conversationId':
            '${widget.booking.senderId}_${widget.booking.travelerId}',
        'otherUserId': widget.booking.travelerId,
        'otherUserName': 'Your Traveler',
      },
    );
  }

  /// Navigate to booking tracking
  void _viewBookingDetails() async {
    try {
      // First create tracking entry if not exists
      final trackingService = Get.find<TrackingService>();

      // Check if tracking already exists for this booking
      var tracking = await trackingService
          .getTrackingByPackageId(widget.booking.packageId);

      if (tracking == null) {
        // Create new tracking entry
        final trackingId = await trackingService.createTracking(
          packageRequestId: widget.booking.packageId,
          travelerId: widget.booking.travelerId,
          notes: 'Booking confirmed - ready for pickup',
        );

        // Navigate to tracking screen
        TrackingRouteHandler.navigateToPackageTracking(
          trackingId: trackingId,
          packageRequestId: widget.booking.packageId,
        );
      } else {
        // Navigate to existing tracking
        TrackingRouteHandler.navigateToPackageTracking(
          trackingId: tracking.id,
          packageRequestId: widget.booking.packageId,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to access tracking: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Confetti celebration
          Positioned.fill(
            child: ConfettiCelebrationWidget(
              autoPlay: true,
              duration: const Duration(seconds: 3),
              onAnimationComplete: () {
                // Animation completed
              },
            ),
          ),

          // Main content
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Success Icon and Title
                    _buildSuccessHeader(),

                    const SizedBox(height: 40),

                    // Booking Details Card
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildBookingDetailsCard(),
                            const SizedBox(height: 24),
                            _buildPaymentReceiptCard(),
                            const SizedBox(height: 24),
                            _buildNextStepsCard(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        // Success Icon with Animation
        AnimatedBuilder(
          animation: _celebrationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_celebrationController.value * 0.2),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppColors.success,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Success Title
        Text(
          'Booking Confirmed!',
          style: AppTextStyles.h1.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Success Subtitle
        Text(
          'Your package delivery has been successfully booked.\nYour traveler will contact you soon.',
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBookingDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking Details',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _copyBookingId,
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Copy Booking ID',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Booking ID', widget.booking.id),
          _buildDetailRow('Status', 'Confirmed'),
          _buildDetailRow('Total Amount',
              '\$${widget.booking.totalAmount.toStringAsFixed(2)}'),
          _buildDetailRow('Platform Fee',
              '\$${widget.booking.platformFee.toStringAsFixed(2)}'),
          _buildDetailRow('Traveler Payout',
              '\$${widget.booking.travelerPayout.toStringAsFixed(2)}'),
          _buildDetailRow(
              'Booked On', _formatDateTime(widget.booking.createdAt)),
          if (widget.booking.specialInstructions?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Special Instructions',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.booking.specialInstructions!,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentReceiptCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Payment Receipt',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.paymentIntent != null) ...[
            _buildDetailRow('Payment ID', widget.paymentIntent!.id),
            _buildDetailRow('Payment Method', _getPaymentMethodName()),
            _buildDetailRow('Status', 'Paid'),
            _buildDetailRow('Processed At', _formatDateTime(DateTime.now())),
          ] else ...[
            Text(
              'Payment receipt will be available once processing is complete.',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your payment is secured in escrow until delivery confirmation',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Text(
            'What\'s Next?',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildNextStepItem(
            Icons.chat_bubble_outline,
            'Stay Connected',
            'Chat with your traveler for pickup and delivery coordination',
            _chatWithTraveler,
          ),
          const SizedBox(height: 16),
          _buildNextStepItem(
            Icons.track_changes,
            'Track Progress',
            'Monitor your package delivery in real-time',
            _viewBookingDetails,
          ),
          const SizedBox(height: 16),
          _buildNextStepItem(
            Icons.star_outline,
            'Rate Experience',
            'Share feedback after successful delivery',
            null, // Will be enabled after delivery
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(
    IconData icon,
    String title,
    String description,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
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
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary Actions Row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _chatWithTraveler,
                icon: const Icon(Icons.chat, size: 20),
                label: const Text('Chat with Traveler'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _viewBookingDetails,
                icon: const Icon(Icons.visibility, size: 20),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Secondary Actions Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: _shareBookingDetails,
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Share'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: () => Get.offAllNamed(AppRoutes.mainNavigation),
              icon: const Icon(Icons.home, size: 18),
              label: const Text('Home'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getPaymentMethodName() {
    if (widget.booking.paymentDetails?.paymentMethod != null) {
      switch (widget.booking.paymentDetails!.paymentMethod) {
        case PaymentMethod.creditCard:
          return 'Credit Card';
        case PaymentMethod.debitCard:
          return 'Debit Card';
        case PaymentMethod.paypal:
          return 'PayPal';
        case PaymentMethod.applePay:
          return 'Apple Pay';
        case PaymentMethod.googlePay:
          return 'Google Pay';
        case PaymentMethod.bankTransfer:
          return 'Bank Transfer';
      }
    }
    return 'Card Payment';
  }
}
