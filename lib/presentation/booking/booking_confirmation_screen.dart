import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/models/deal_offer.dart';
import '../../core/models/package_request.dart';
import '../../core/models/travel_trip.dart';
import '../../services/booking_service.dart';
import '../../widgets/booking/booking_summary_widget.dart';
import '../../widgets/booking/terms_agreement_widget.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'payment_method_screen.dart';

/// 📝 Booking Confirmation Screen - Phase 2.1
/// Handles booking confirmation flow after deal acceptance
class BookingConfirmationScreen extends StatefulWidget {
  final DealOffer acceptedDeal;
  final PackageRequest package;
  final TravelTrip trip;

  const BookingConfirmationScreen({
    Key? key,
    required this.acceptedDeal,
    required this.package,
    required this.trip,
  }) : super(key: key);

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final BookingService _bookingService = BookingService();
  final TextEditingController _specialInstructionsController =
      TextEditingController();

  bool _isTermsAgreed = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _specialInstructionsController.dispose();
    super.dispose();
  }

  /// Handle booking confirmation
  Future<void> _confirmBooking() async {
    if (!_isTermsAgreed) {
      setState(() {
        _errorMessage = 'Please agree to the terms and conditions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create the booking
      final booking = await _bookingService.createBooking(
        acceptedDeal: widget.acceptedDeal,
        package: widget.package,
        trip: widget.trip,
        specialInstructions: _specialInstructionsController.text.trim().isEmpty
            ? null
            : _specialInstructionsController.text.trim(),
      );

      if (kDebugMode) {
        print('✅ Booking created successfully: ${booking.id}');
      }

      // Navigate to payment method screen
      if (mounted) {
        // Navigate to payment method screen
        Get.to(() => PaymentMethodScreen(booking: booking));

        // Show success message
        Get.snackbar(
          'Booking Created!',
          'Please select your payment method to complete the booking.',
          backgroundColor: AppColors.success,
          colorText: AppColors.surface,
          icon: Icon(Icons.check_circle, color: AppColors.surface),
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to create booking: $e');
      }

      setState(() {
        _errorMessage = 'Failed to create booking. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Confirm Booking',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress indicator
                    _buildProgressIndicator(),
                    const SizedBox(height: 24),

                    // Booking summary
                    BookingSummaryWidget(
                      deal: widget.acceptedDeal,
                      package: widget.package,
                      trip: widget.trip,
                    ),
                    const SizedBox(height: 24),

                    // Special instructions
                    _buildSpecialInstructions(),
                    const SizedBox(height: 24),

                    // Contact information
                    _buildContactInformation(),
                    const SizedBox(height: 24),

                    // Terms and conditions
                    TermsAgreementWidget(
                      onAgreementChanged: (agreed) {
                        setState(() {
                          _isTermsAgreed = agreed;
                          _errorMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.body2
                                    .copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom action area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textSecondary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Total amount display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: AppTextStyles.h3
                              .copyWith(color: AppColors.textPrimary),
                        ),
                        Text(
                          '\$${(widget.acceptedDeal.offeredPrice + (widget.acceptedDeal.offeredPrice * 0.1)).toStringAsFixed(2)}',
                          style: AppTextStyles.h2
                              .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm booking button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.surface),
                              ),
                            )
                          : Text(
                              'Proceed to Payment',
                              style: AppTextStyles.button,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build progress indicator
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Step 1 - Confirmation (current)
          _buildProgressStep(
            number: '1',
            title: 'Confirmation',
            isActive: true,
            isCompleted: false,
          ),

          // Connector
          Expanded(
            child: Container(
              height: 2,
              color: AppColors.border,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),

          // Step 2 - Payment
          _buildProgressStep(
            number: '2',
            title: 'Payment',
            isActive: false,
            isCompleted: false,
          ),

          // Connector
          Expanded(
            child: Container(
              height: 2,
              color: AppColors.border,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),

          // Step 3 - Complete
          _buildProgressStep(
            number: '3',
            title: 'Complete',
            isActive: false,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  /// Build individual progress step
  Widget _buildProgressStep({
    required String number,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : isCompleted
                    ? AppColors.success
                    : AppColors.border,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: AppColors.surface, size: 18)
                : Text(
                    number,
                    style: AppTextStyles.caption.copyWith(
                      color: isActive
                          ? AppColors.surface
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Build special instructions section
  Widget _buildSpecialInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Special Instructions',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _specialInstructionsController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText:
                  'Add any special instructions for the traveler (optional)',
              hintStyle:
                  AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }

  /// Build contact information section
  Widget _buildContactInformation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Contact Information',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Contact details will be shared after payment confirmation',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.security, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your information is protected and secure',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
