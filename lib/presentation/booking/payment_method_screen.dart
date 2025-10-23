import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import '../../core/models/booking.dart';
import '../../core/models/transaction.dart';
import '../../core/theme/app_colors.dart';
import '../../services/payment_service.dart';
import '../../widgets/animated_button_widget.dart';
import '../../widgets/booking/payment_method_widget.dart';
import 'payment_processing_screen.dart';
import 'package:easy_localization/easy_localization.dart';

/// Screen for selecting payment method for booking
class PaymentMethodScreen extends StatefulWidget {
  final Booking booking;

  const PaymentMethodScreen({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final PaymentService _paymentService = PaymentService();
  PaymentMethod? _selectedPaymentMethod;
  bool _isLoading = false;
  List<PaymentMethod> _availablePaymentMethods = [];

  @override
  void initState() {
    super.initState();
    _initializePaymentService();
  }

  Future<void> _initializePaymentService() async {
    setState(() => _isLoading = true);
    try {
      print('🔧 Initializing payment service...');
      await _paymentService.initializeStripe();

      // Get available payment methods
      _availablePaymentMethods =
          await _paymentService.getSupportedPaymentMethods();
      print(
          '💳 Available payment methods: ${_availablePaymentMethods.map((m) => m.name).join(', ')}');
    } catch (e) {
      print('❌ Payment service initialization failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize payment service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('payment.method_title'.tr()),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBookingSummary(),
                    const SizedBox(height: 24),
                    _buildPaymentMethodsSection(),
                    const SizedBox(height: 24),
                    _buildSecurityInfo(context),
                    // Add bottom padding to account for bottom section
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Package Delivery',
              '${widget.booking.totalAmount.toStringAsFixed(2)} €'),
          _buildSummaryRow('Platform Fee',
              '${widget.booking.platformFee.toStringAsFixed(2)} €'),
          const Divider(height: 20),
          _buildSummaryRow(
            'Total Amount',
            '${widget.booking.totalAmount.toStringAsFixed(2)} €',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 16 : 14,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isTotal ? 16 : 14,
                  color: isTotal ? AppColors.primary : null,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('booking.select_payment_method'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<PaymentMethod>>(
          future: _paymentService.getSupportedPaymentMethods(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading payment methods: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
                ),
              );
            }

            final supportedMethods = snapshot.data ?? [];

            if (supportedMethods.isEmpty) {
              return Center(
                child: Text('wallet.no_payment_methods_available'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              );
            }

            return Column(
              children: supportedMethods.map((method) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FutureBuilder<bool>(
                    future: _paymentService.isPaymentMethodAvailable(method),
                    builder: (context, availabilitySnapshot) {
                      final isAvailable = availabilitySnapshot.data ?? false;

                      return PaymentMethodWidget(
                        method: method,
                        isSelected: _selectedPaymentMethod == method,
                        isAvailable: isAvailable,
                        onSelected: isAvailable
                            ? () {
                                print(
                                    '💳 Payment method selected: ${method.name}');
                                setState(() {
                                  _selectedPaymentMethod = method;
                                });
                                print(
                                    '💳 Current selected method: ${_selectedPaymentMethod?.name}');
                              }
                            : null,
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSecurityInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF008080),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF008080)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Color(0xFF008080),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('wallet.secure_payment'.tr(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF008080),
                      ),
                ),
                const SizedBox(height: 4),
                Text('travel.your_payment_is_secured_by_stripe_your_card_detail'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Color(0xFF008080),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final isButtonEnabled = _selectedPaymentMethod != null && !_isLoading;
    print(
        '🔘 Button state: enabled=$isButtonEnabled, selected=${_selectedPaymentMethod?.name}, loading=$_isLoading');
    print('🔘 Button onPressed: ${isButtonEnabled ? "NOT NULL" : "NULL"}');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedButton(
            text: 'wallet.proceed_to_payment'.tr(),
            onPressed: isButtonEnabled
                ? () {
                    print('🔥 Button tap detected in _buildBottomSection!');
                    _proceedToPayment();
                  }
                : null,
            backgroundColor: AppColors.primary,
            textColor: Colors.white,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 6),
          Text('common.by_proceeding_you_agree_to_our_terms_of_service'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToPayment() async {
    print('🔥 _proceedToPayment called!');

    if (_selectedPaymentMethod == null) {
      print('❌ No payment method selected');
      return;
    }

    print(
        '💳 Proceeding to payment with method: ${_selectedPaymentMethod!.name}');
    print('📦 Booking ID: ${widget.booking.id}');

    setState(() {
      _isLoading = true;
    });

    try {
      // Navigate to payment processing screen using Get.to instead of Get.toNamed
      print('🚀 Navigating to PaymentProcessingScreen...');
      Get.to(() => PaymentProcessingScreen(
            booking: widget.booking,
            selectedMethod: _selectedPaymentMethod!,
          ));
    } catch (e) {
      print('❌ Navigation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
