import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../core/models/booking.dart';
import '../../core/models/transaction.dart' show PaymentMethod;
import '../../core/models/chat_message.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../routes/tracking_route_handler.dart';
import '../../services/tracking_service.dart';
import '../../widgets/confetti_celebration_widget.dart';
import '../../controllers/chat_controller.dart';
import '../../presentation/chat/individual_chat_screen.dart';

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
  late AnimationController _contentSlideController;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _contentSlideAnimation;
  bool _showHeader = true;

  // Traveler info for chat
  String? _travelerName;
  String? _travelerPhotoUrl;
  bool _isLoadingTravelerInfo = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCelebration();
    _fetchTravelerInfo();
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

    _contentSlideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentSlideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startCelebration() {
    _slideController.forward();
    // Start celebration animation immediately
    _celebrationController.forward();

    // Hide booking confirmed message and show details after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showHeader = false;
        });
        // Animate content sliding up smoothly
        _contentSlideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _slideController.dispose();
    _contentSlideController.dispose();
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
            content: Text('booking.details_shared_success'.tr()),
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
            content: Text('booking.share_failed'.tr()),
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
          content: Text('booking.id_copied'.tr()),
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

  /// Fetch traveler information from Firestore
  Future<void> _fetchTravelerInfo() async {
    if (_isLoadingTravelerInfo) return;

    setState(() {
      _isLoadingTravelerInfo = true;
    });

    try {
      final travelerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.booking.travelerId)
          .get();

      if (travelerDoc.exists && mounted) {
        final data = travelerDoc.data();
        setState(() {
          _travelerName = data?['fullName'] ?? data?['username'] ?? 'Traveler';
          _travelerPhotoUrl = data?['photoUrl'];
          _isLoadingTravelerInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _travelerName = 'Traveler';
          _isLoadingTravelerInfo = false;
        });
      }
    }
  }

  /// Navigate to chat with traveler
  Future<void> _chatWithTraveler() async {
    // Show loading dialog immediately for responsive UI
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Prevent dismissing while loading
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Lottie.asset(
                    'assets/animations/liquid loader 01.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // Ensure traveler info is loaded
      if (_travelerName == null && !_isLoadingTravelerInfo) {
        await _fetchTravelerInfo();
      }

      // Wait a bit if still loading
      if (_isLoadingTravelerInfo) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Get or create ChatController
      final chatController = Get.isRegistered<ChatController>()
          ? Get.find<ChatController>()
          : Get.put(ChatController(), permanent: true);

      // Create or get conversation with proper traveler info
      final conversationId =
          await chatController.chatService.createOrGetConversation(
        otherUserId: widget.booking.travelerId,
        otherUserName: _travelerName ?? 'Traveler',
        otherUserAvatar: _travelerPhotoUrl,
      );

      // CRITICAL FIX: Force load messages directly from Firestore
      // The stream subscription exists but doesn't emit until triggered by a write
      // So we manually query Firestore to populate messagesMap before navigation
      print('🔄 Force loading messages from Firestore before navigation...');

      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      print(
          '📥 Fetched ${messagesSnapshot.docs.length} messages from Firestore');

      // Parse and store messages in controller
      final messages = messagesSnapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data()))
          .toList();

      // Update messagesMap directly
      chatController.messagesMap[conversationId] = messages;
      print('✅ Pre-loaded ${messages.length} messages into messagesMap');

      // Now start listening for new messages (won't re-fetch, just listens for updates)
      await chatController.startListeningToMessages(conversationId);

      // Close loading dialog AFTER messages are loaded
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (mounted) {
        // Navigate to chat screen with messages already loaded
        Get.to(
          () => IndividualChatScreen(
            conversationId: conversationId,
            otherUserName: _travelerName ?? 'Traveler',
            otherUserId: widget.booking.travelerId,
            otherUserAvatar: _travelerPhotoUrl,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to open chat: ${e.toString()}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    }
  }

  /// Navigate to package tracking screen to view real-time delivery status
  void _viewBookingDetails() async {
    try {
      // Show loading indicator while fetching tracking
      Get.dialog(
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Use TrackingService to get tracking by package ID (handles permissions properly)
      final trackingService = Get.find<TrackingService>();
      final tracking = await trackingService.getTrackingByPackageId(
        widget.booking.packageId,
      );

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (tracking == null) {
        // No tracking record found yet - navigate to orders screen instead
        Get.snackbar(
          'Info',
          'Tracking not yet available. Check your orders.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
        );
        Get.offAllNamed(AppRoutes.mainNavigation,
            arguments: {'initialTab': 1, 'ordersTab': 2});
        return;
      }

      // Navigate directly to the tracking screen for this specific booking
      TrackingRouteHandler.navigateToPackageTracking(
        trackingId: tracking.id,
        packageRequestId: widget.booking.packageId,
      );
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Failed to open tracking screen: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.error,
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
          // Confetti celebration - show immediately
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
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
                child: Column(
                  children: [
                    // Header Section - Show booking confirmed
                    if (_showHeader) ...[
                      const SizedBox(height: 20),
                      _buildSuccessHeader(),
                      const SizedBox(height: 20),
                    ],

                    // Booking Details Card - Animate smoothly to top when header disappears
                    Expanded(
                      child: SlideTransition(
                        position: _showHeader
                            ? const AlwaysStoppedAnimation(Offset.zero)
                            : _contentSlideAnimation,
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildBookingDetailsCard(),
                                    const SizedBox(height: 9),
                                    _buildPaymentReceiptCard(),
                                    const SizedBox(height: 9),
                                    _buildNextStepsCard(),
                                    const SizedBox(height: 7),
                                  ],
                                ),
                              ),
                            ),
                            // Action Buttons - Fixed at bottom
                            _buildActionButtons(),
                          ],
                        ),
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
        Text('booking.booking_success_title'.tr(),
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
      padding: const EdgeInsets.all(20),
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
              Text('booking.booking_details'.tr(),
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
          const SizedBox(height: 12),
          _buildDetailRow('Booking ID', widget.booking.id),
          _buildDetailRow('Status', 'Confirmed'),
          _buildDetailRow('Total Amount',
              '€${widget.booking.totalAmount.toStringAsFixed(2)}'),
          _buildDetailRow('Platform Fee',
              '€${widget.booking.platformFee.toStringAsFixed(2)}'),
          _buildDetailRow('Traveler Payout',
              '€${widget.booking.travelerPayout.toStringAsFixed(2)}'),
          _buildDetailRow(
              'Booked On', _formatDateTime(widget.booking.createdAt)),
          if (widget.booking.specialInstructions?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text('detail.special_instructions'.tr(),
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
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
      padding: const EdgeInsets.all(20),
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
              Text('wallet.payment_receipt'.tr(),
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.paymentIntent != null) ...[
            _buildDetailRow('Payment ID', widget.paymentIntent!.id),
            _buildDetailRow('Payment Method', _getPaymentMethodName()),
            _buildDetailRow('Status', 'Paid'),
            _buildDetailRow('Processed At', _formatDateTime(DateTime.now())),
          ] else ...[
            Text('common.payment_receipt_will_be_available_once_processing_'.tr(),
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
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
                  child: Text('wallet.your_payment_is_secured_in_escrow_until_delivery_c'.tr(),
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
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 12),
          _buildNextStepItem(
            Icons.chat_bubble_outline,
            'Chat with ${_travelerName ?? 'Traveler'}',
            'Stay connected with your traveler',
            _chatWithTraveler,
          ),
          const SizedBox(height: 12),
          _buildNextStepItem(
            Icons.track_changes,
            'Track Progress',
            'Monitor your package delivery in real-time',
            _viewBookingDetails,
          ),
          const SizedBox(height: 12),
          _buildNextStepItem(
            Icons.star_outline,
            'Rate Experience',
            'Share feedback after successful delivery',
            null, // Not clickable yet - will be enabled after delivery
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
    // Always show with full colors, regardless of clickability
    final content = Padding(
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.7),
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
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }

    return content;
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Share Button
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _shareBookingDetails,
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.share_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text('forum.share'.tr(),
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Home Button
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.offAllNamed(AppRoutes.mainNavigation),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.home_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text('nav.home'.tr(),
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
