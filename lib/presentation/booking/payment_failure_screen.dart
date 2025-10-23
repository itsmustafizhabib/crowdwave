import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import '../../core/models/booking.dart';
import '../../core/models/transaction.dart' show PaymentMethod;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../routes/app_routes.dart';

/// ❌ Payment Failure Screen - Phase 2.4
/// Handles payment failures with retry options and support
class PaymentFailureScreen extends StatefulWidget {
  final Booking booking;
  final String error;
  final PaymentMethod selectedMethod;

  const PaymentFailureScreen({
    Key? key,
    required this.booking,
    required this.error,
    required this.selectedMethod,
  }) : super(key: key);

  @override
  State<PaymentFailureScreen> createState() => _PaymentFailureScreenState();
}

class _PaymentFailureScreenState extends State<PaymentFailureScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startErrorAnimation();
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  void _startErrorAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  /// Retry payment with same method
  void _retryPayment() {
    Get.back(); // Go back to payment method screen

    // Navigate to payment processing with same details
    Get.toNamed(
      AppRoutes.paymentProcessing,
      arguments: {
        'booking': widget.booking,
        'selectedMethod': widget.selectedMethod,
      },
    );
  }

  /// Choose different payment method
  void _chooseDifferentMethod() {
    Get.back(); // Go back to payment method screen
  }

  /// Contact support
  void _contactSupport() {
    Get.snackbar(
      'Support',
      'Support chat will be available soon. Please try again or use a different payment method.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.info,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  /// Cancel and go home
  void _cancelAndGoHome() {
    Get.offAllNamed(AppRoutes.mainNavigation);
  }

  /// Get user-friendly error message
  String _getUserFriendlyError() {
    final error = widget.error.toLowerCase();

    if (error.contains('card') && error.contains('declined')) {
      return 'Your card was declined. Please check your card details or try a different payment method.';
    } else if (error.contains('insufficient')) {
      return 'Insufficient funds. Please check your account balance or use a different card.';
    } else if (error.contains('expired')) {
      return 'Your card has expired. Please use a different payment method.';
    } else if (error.contains('network')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    } else if (error.contains('timeout')) {
      return 'Payment request timed out. Please try again.';
    } else if (error.contains('authentication')) {
      return 'Payment authentication failed. Please verify your card details.';
    } else {
      return widget.error;
    }
  }

  /// Get error icon based on error type
  IconData _getErrorIcon() {
    final error = widget.error.toLowerCase();

    if (error.contains('card') || error.contains('declined')) {
      return Icons.credit_card_off;
    } else if (error.contains('network') || error.contains('timeout')) {
      return Icons.wifi_off;
    } else if (error.contains('authentication')) {
      return Icons.security;
    } else {
      return Icons.error_outline;
    }
  }

  /// Get suggested actions based on error type
  List<Widget> _getSuggestedActions() {
    final error = widget.error.toLowerCase();
    List<Widget> actions = [];

    if (error.contains('card') && error.contains('declined')) {
      actions.addAll([
        _buildSuggestionItem(
          Icons.credit_card,
          'Check Card Details',
          'Verify your card number, expiry date, and CVV',
        ),
        _buildSuggestionItem(
          Icons.account_balance,
          'Check Account Balance',
          'Ensure sufficient funds are available',
        ),
      ]);
    } else if (error.contains('network') || error.contains('timeout')) {
      actions.addAll([
        _buildSuggestionItem(
          Icons.wifi,
          'Check Internet Connection',
          'Ensure you have a stable internet connection',
        ),
        _buildSuggestionItem(
          Icons.refresh,
          'Try Again',
          'Network issues are often temporary',
        ),
      ]);
    }

    actions.add(
      _buildSuggestionItem(
        Icons.payment,
        'Try Different Payment Method',
        'Use another card or payment option',
      ),
    );

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('payment.failed_title'.tr()),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Error Header
              _buildErrorHeader(),

              const SizedBox(height: 40),

              // Error Details and Suggestions
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildErrorDetailsCard(),
                      const SizedBox(height: 24),
                      _buildBookingSummaryCard(),
                      const SizedBox(height: 24),
                      _buildSuggestionsCard(),
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
    );
  }

  Widget _buildErrorHeader() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Column(
            children: [
              // Error Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getErrorIcon(),
                  size: 60,
                  color: AppColors.error,
                ),
              ),

              const SizedBox(height: 24),

              // Error Title
              Text('payment.failed_title'.tr(),
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Error Subtitle
              Text(
                'Don\'t worry, your booking is still available.\nLet\'s try to resolve this payment issue.',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorDetailsCard() {
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
                Icons.info_outline,
                color: AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text('error_messages.error_details'.tr(),
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What happened:',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getUserFriendlyError(),
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummaryCard() {
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
          Text('booking.booking_summary'.tr(),
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Booking ID', widget.booking.id),
          _buildDetailRow(
              'Amount', '€${widget.booking.totalAmount.toStringAsFixed(2)}'),
          _buildDetailRow('Payment Method', _getPaymentMethodName()),
          _buildDetailRow('Status', 'Payment Pending'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This booking will be held for 30 minutes',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
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

  Widget _buildSuggestionsCard() {
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
          Text('common.suggested_solutions'.tr(),
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._getSuggestedActions(),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.info,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle2.copyWith(
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
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary Action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _retryPayment,
            icon: const Icon(Icons.refresh, size: 20),
            label: Text('payment.retry_payment'.tr()),
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

        const SizedBox(height: 12),

        // Secondary Actions Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _chooseDifferentMethod,
                icon: const Icon(Icons.payment, size: 18),
                label: Text('payment.different_method'.tr()),
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
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _contactSupport,
                icon: const Icon(Icons.support_agent, size: 18),
                label: Text('payment.get_help'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.info,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: AppColors.info),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Cancel Action
        TextButton.icon(
          onPressed: _cancelAndGoHome,
          icon: const Icon(Icons.home, size: 18),
          label: Text('payment.cancel_go_home'.tr()),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
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
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
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
