import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import '../../core/models/booking.dart';
import '../../core/models/transaction.dart' show PaymentMethod;
import '../../core/models/payment_details.dart' as payment_models;
import '../../services/payment_service.dart';
import '../../services/booking_service.dart';
import '../../widgets/booking/payment_status_widget.dart' as status_widget;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'booking_success_screen.dart';

/// 💳 Payment Processing Screen - Phase 2.2
/// Handles real-time payment processing with Stripe integration
class PaymentProcessingScreen extends StatefulWidget {
  final Booking booking;
  final PaymentMethod selectedMethod;

  const PaymentProcessingScreen({
    Key? key,
    required this.booking,
    required this.selectedMethod,
  }) : super(key: key);

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen>
    with TickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  final BookingService _bookingService = BookingService();

  PaymentUIStatus _paymentStatus = PaymentUIStatus.processing;
  String? _errorMessage;
  String? _paymentIntentId;
  String? _clientSecret;
  double _progress = 0.0;

  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _processPayment();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Process the payment through Stripe
  Future<void> _processPayment() async {
    try {
      setState(() {
        _paymentStatus = PaymentUIStatus.processing;
        _progress = 0.1;
      });

      // Step 1: Create payment intent
      final paymentIntentData = await _paymentService.createPaymentIntent(
        amount: widget.booking.totalAmount,
        currency: 'usd',
        bookingId: widget.booking.id,
        metadata: {
          'booking_id': widget.booking.id,
          'package_id': widget.booking.packageId,
          'traveler_id': widget.booking.travelerId,
          'sender_id': widget.booking.senderId,
        },
      );

      _clientSecret = paymentIntentData['clientSecret']!;
      _paymentIntentId = paymentIntentData['paymentIntentId']!;

      print('💳 Payment Intent created: $_paymentIntentId');
      print('🔑 Client Secret: ${_clientSecret!.substring(0, 20)}...');

      setState(() => _progress = 0.3);

      // Step 2: Initialize payment sheet
      await _paymentService.initializePaymentSheet(
        clientSecret: _clientSecret!,
        customerEmail: null, // Add user email if available
      );

      setState(() => _progress = 0.5);

      // Step 3: Present payment sheet
      print('💳 Presenting Stripe payment sheet...');
      await stripe.Stripe.instance.presentPaymentSheet();

      setState(() => _progress = 0.7);

      // Step 4: Confirm payment completion (server-side)
      // Ensure backend creates deliveryTracking and updates booking via Cloud Function
      if (_paymentIntentId != null) {
        await _paymentService.handlePaymentSuccess(
          paymentIntentId: _paymentIntentId!,
          bookingId: widget.booking.id,
        );
      }

      // Update local booking metadata/status for UI continuity
      await _confirmPaymentSuccess();

      setState(() => _progress = 1.0);
    } on stripe.StripeException catch (e) {
      debugPrint('Stripe error: ${e.error.localizedMessage}');
      _handlePaymentError(e.error.localizedMessage ?? 'Payment failed');
    } catch (e) {
      debugPrint('Payment error: $e');

      // ✅ Better error handling for authentication issues
      String errorMessage = 'An unexpected error occurred. Please try again.';

      if (e.toString().contains('UNAUTHENTICATED') ||
          e.toString().contains('unauthenticated') ||
          e.toString().contains('User not authenticated') ||
          e.toString().contains('authentication lost')) {
        errorMessage =
            'Authentication expired. Please sign in again and retry payment.';
      } else if (e.toString().contains('permission-denied')) {
        errorMessage =
            'Permission denied. Please check your account permissions.';
      } else if (e.toString().contains('network')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      }

      _handlePaymentError(errorMessage);
    }
  }

  /// Confirm payment success and update booking
  Future<void> _confirmPaymentSuccess() async {
    try {
      // Update booking status to payment completed
      await _bookingService.updateBookingStatus(
        bookingId: widget.booking.id,
        status: BookingStatus.paymentCompleted,
      );

      // Add payment details to booking
      final paymentDetails = payment_models.PaymentDetails(
        stripePaymentIntentId: _paymentIntentId!,
        paymentMethod: widget.selectedMethod,
        status: payment_models.PaymentStatus.succeeded,
        amount: widget.booking.totalAmount,
        currency: 'USD',
        processedAt: DateTime.now(),
      );

      await _bookingService.updatePaymentDetails(
        bookingId: widget.booking.id,
        paymentDetails: paymentDetails,
      );

      setState(() => _paymentStatus = PaymentUIStatus.success);

      // Navigate to success screen after short delay
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Import the success screen and navigate directly
        Get.off(() => BookingSuccessScreen(
              booking: widget.booking,
              paymentIntent: null, // Will be updated if needed
            ));
      }
    } catch (e) {
      debugPrint('Error confirming payment: $e');
      _handlePaymentError('Payment succeeded but booking update failed');
    }
  }

  /// Handle payment errors
  void _handlePaymentError(String error) {
    print('💥 Payment error occurred: $error');

    setState(() {
      _paymentStatus = PaymentUIStatus.failed;
      _errorMessage = error;
    });

    _progressController.stop();

    // Navigate back to payment method screen for now, with error message
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Show error message
        Get.snackbar(
          'Payment Failed',
          error,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );

        // Navigate back to payment method screen
        Get.back();
      }
    });
  }

  /// Retry payment process
  void _retryPayment() {
    setState(() {
      _paymentStatus = PaymentUIStatus.processing;
      _errorMessage = null;
      _progress = 0.0;
    });

    _progressController.reset();
    _progressController.forward();
    _processPayment();
  }

  /// Convert UI status to widget status
  status_widget.PaymentStatus _convertToPaymentStatus(
      PaymentUIStatus uiStatus) {
    switch (uiStatus) {
      case PaymentUIStatus.processing:
        return status_widget.PaymentStatus.processing;
      case PaymentUIStatus.success:
        return status_widget.PaymentStatus.success;
      case PaymentUIStatus.failed:
        return status_widget.PaymentStatus.failed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation during processing
        return _paymentStatus != PaymentUIStatus.processing;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Processing Payment',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          automaticallyImplyLeading:
              _paymentStatus != PaymentUIStatus.processing,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    kToolbarHeight -
                    48, // Account for app bar and padding
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Payment Status Widget
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _paymentStatus == PaymentUIStatus.processing
                              ? _pulseAnimation.value
                              : 1.0,
                          child: status_widget.PaymentStatusWidget(
                            status: _convertToPaymentStatus(_paymentStatus),
                            message: _getStatusMessage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Progress Bar (only show during processing)
                    if (_paymentStatus == PaymentUIStatus.processing) ...[
                      Text(
                        'Processing your payment...',
                        style: AppTextStyles.h3,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Column(
                            children: [
                              LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                                minHeight: 8,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${(_progress * 100).toInt()}% Complete',
                                style: AppTextStyles.body1,
                              ),
                            ],
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 5),

                    // Booking Details Card
                    _buildBookingDetailsCard(),

                    const Expanded(child: SizedBox()),

                    // Action Buttons
                    if (_paymentStatus == PaymentUIStatus.failed) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _retryPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Retry Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            'Choose Different Payment Method',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Security Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your payment is secured by Stripe\'s industry-leading encryption',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusMessage() {
    switch (_paymentStatus) {
      case PaymentUIStatus.processing:
        return 'Securely processing your payment...';
      case PaymentUIStatus.success:
        return 'Payment successful! Booking confirmed.';
      case PaymentUIStatus.failed:
        return _errorMessage ?? 'Payment failed. Please try again.';
    }
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
          Text(
            'Payment Details',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
              'Amount', '\$${widget.booking.totalAmount.toStringAsFixed(2)}'),
          _buildDetailRow('Platform Fee',
              '\$${widget.booking.platformFee.toStringAsFixed(2)}'),
          _buildDetailRow('Payment Method', _getPaymentMethodName()),
          _buildDetailRow('Booking ID', widget.booking.id),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
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
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName() {
    switch (widget.selectedMethod) {
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
}

/// Payment UI status enum for screen states
enum PaymentUIStatus {
  processing,
  success,
  failed,
}
