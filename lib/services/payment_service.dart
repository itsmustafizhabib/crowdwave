import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/api_constants.dart';
import '../core/models/transaction.dart' show PaymentMethod;

/// Centralized payment service for Stripe integration
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  bool _isInitialized = false;

  /// Initialize Stripe with environment-specific keys
  Future<void> initializeStripe() async {
    if (_isInitialized) return;

    try {
      // Get the publishable key based on environment
      String publishableKey = EnvironmentConfig.stripePublishableKey;

      // If we get a placeholder, use the actual test key from ApiConstants
      if (publishableKey == 'pk_test_PLACEHOLDER' ||
          publishableKey == 'pk_live_PLACEHOLDER') {
        publishableKey = ApiConstants.stripePublishableKey;
      }

      // Debug logging
      if (kDebugMode) {
        print('🔧 Initializing Stripe...');
        print(
            '📍 Current environment: ${EnvironmentConfig.currentEnvironment}');
        // Safe substring - only show first part if key is long enough
        final keyPreview = publishableKey.length > 20
            ? '${publishableKey.substring(0, 20)}...'
            : publishableKey;
        print('🔑 Publishable key: $keyPreview');
      }

      // Initialize Stripe
      stripe.Stripe.publishableKey = publishableKey;

      // Configure Stripe settings
      await stripe.Stripe.instance.applySettings();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Stripe initialized successfully');
      }

      log('Stripe initialized successfully');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Stripe: $e');
      }
      log('Failed to initialize Stripe: $e');
      rethrow;
    }
  }

  /// Create or retrieve Stripe customer for saved payment methods
  Future<Map<String, String?>> getOrCreateCustomer({
    required String userId,
    required String email,
    String? name,
  }) async {
    try {
      log('Getting or creating customer for user: $userId');

      // Call Firebase Cloud Function to get/create customer
      final callable =
          FirebaseFunctions.instance.httpsCallable('getOrCreateStripeCustomer');
      final result = await callable.call({
        'userId': userId,
        'email': email,
        'name': name,
      });

      final data = result.data as Map<String, dynamic>;

      return {
        'customerId': data['customerId'] as String?,
        'ephemeralKey': data['ephemeralKey'] as String?,
      };
    } catch (e) {
      log('Failed to get/create customer: $e');
      return {'customerId': null, 'ephemeralKey': null};
    }
  }

  /// Get saved payment methods for a customer
  Future<List<Map<String, dynamic>>> getSavedPaymentMethods(
      String customerId) async {
    try {
      log('Getting saved payment methods for customer: $customerId');

      final callable =
          FirebaseFunctions.instance.httpsCallable('getCustomerPaymentMethods');
      final result = await callable.call({'customerId': customerId});

      final data = result.data as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['paymentMethods'] ?? []);
    } catch (e) {
      log('Failed to get saved payment methods: $e');
      return [];
    }
  }

  /// Create payment intent using Firebase Cloud Functions
  Future<Map<String, String>> createPaymentIntent({
    required double amount,
    required String currency,
    required String bookingId,
    Map<String, dynamic>? metadata,
  }) async {
    await initializeStripe();

    try {
      // Check authentication
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      log('Creating payment intent for booking: $bookingId');

      // Call us-central1 region function
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('createPaymentIntent');

      final result = await callable.call({
        'amount': amount,
        'currency': currency,
        'bookingId': bookingId,
        'metadata': metadata ?? {},
      });

      final data = result.data;
      if (data == null) {
        throw Exception('No data returned from payment intent creation');
      }

      return {
        'clientSecret': data['clientSecret'],
        'paymentIntentId': data['paymentIntentId'],
      };
    } catch (e) {
      log('Failed to create payment intent: $e');
      rethrow;
    }
  }

  /// Process payment using Stripe Payment Sheet
  Future<PaymentResult> processPayment({
    required String clientSecret,
    required String paymentIntentId,
    required BuildContext context,
  }) async {
    try {
      log('Processing payment with intent: $paymentIntentId');

      // Present payment sheet
      await stripe.Stripe.instance.presentPaymentSheet();

      // If we reach here, payment was successful
      log('Payment completed successfully');

      // Confirm payment with backend
      await _confirmPaymentWithBackend(paymentIntentId);

      return PaymentResult(
        status: PaymentStatus.succeeded,
        paymentIntentId: paymentIntentId,
      );
    } on stripe.StripeException catch (e) {
      log('Stripe error during payment: ${e.error}');
      return PaymentResult(
        status: PaymentStatus.failed,
        error: e.error.localizedMessage ?? 'Payment failed',
      );
    } catch (e) {
      log('Unexpected error during payment: $e');
      return PaymentResult(
        status: PaymentStatus.failed,
        error: 'An unexpected error occurred',
      );
    }
  }

  /// Confirm payment with Firebase Cloud Functions
  Future<void> _confirmPaymentWithBackend(String paymentIntentId) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('confirmPayment');
      await callable.call({
        'paymentIntentId': paymentIntentId,
      });
      log('Payment confirmed with Firebase Functions');
    } catch (e) {
      log('Error confirming payment: $e');
    }
  }

  /// Call backend to confirm payment and update booking status
  Future<void> _callBackendConfirmPayment(
      String paymentIntentId, String bookingId) async {
    try {
      // Check authentication and refresh token if needed
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Force refresh the ID token to ensure it's fresh after payment
      log('Refreshing authentication token after payment...');
      await currentUser.getIdToken(true);

      // Wait for token propagation
      await Future.delayed(Duration(milliseconds: 1000));

      log('Confirming payment for booking: $bookingId');

      // Try the call with retry logic for auth errors
      await _makeBackendCallWithRetry(paymentIntentId, bookingId);

      log('Payment confirmed for booking: $bookingId');
    } catch (e) {
      log('Payment confirmation failed: $e');
      throw Exception('Failed to confirm payment: $e');
    }
  }

  /// Make backend call with retry logic for authentication errors
  Future<void> _makeBackendCallWithRetry(
      String paymentIntentId, String bookingId) async {
    int maxRetries = 2;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
            .httpsCallable('confirmPayment');

        final result = await callable.call({
          'paymentIntentId': paymentIntentId,
          'bookingId': bookingId,
        });

        final success = result.data['success'] as bool? ?? false;
        if (!success) {
          throw Exception(
              'Payment confirmation failed: ${result.data['error'] ?? 'Unknown error'}');
        }

        // Success - exit the retry loop
        return;
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'unauthenticated' && attempt < maxRetries) {
          log('Unauthenticated error on attempt $attempt, retrying with fresh token...');

          // Force sign out and back in to get a completely fresh session
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await currentUser.reload();
            await currentUser.getIdToken(true);
            await Future.delayed(Duration(milliseconds: 1500));
            continue; // Retry
          }
        }

        // If it's the last attempt or not an auth error, throw the exception
        if (e.code == 'unauthenticated') {
          throw Exception(
              'Your session has expired during payment processing. Please sign in again and retry payment. The payment may have succeeded - check your orders first.');
        }
        throw Exception('Payment confirmation failed: ${e.message}');
      }
    }
  }

  /// Call backend to handle payment failure and update booking status
  Future<void> _callBackendPaymentFailure(
      String bookingId, String error) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('handlePaymentFailure');
      final result = await callable.call({
        'bookingId': bookingId,
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final success = result.data['success'] as bool? ?? false;
      if (!success) {
        throw Exception(
            'Backend payment failure handling failed: ${result.data['error']}');
      }

      log('Backend payment failure handling successful for booking: $bookingId');
    } catch (e) {
      log('Backend payment failure handling failed: $e');
      // Don't throw here as this is failure handling - log the error instead
    }
  }

  /// Initialize payment sheet
  Future<void> initializePaymentSheet({
    required String clientSecret,
    String? customerEmail,
    String? merchantDisplayName,
    String? userId,
    String? userName,
    bool enableSavedPaymentMethods = false,
  }) async {
    try {
      String? customerId;
      String? ephemeralKey;

      // Get or create customer if saved payment methods are enabled
      if (enableSavedPaymentMethods &&
          userId != null &&
          customerEmail != null) {
        final customerData = await getOrCreateCustomer(
          userId: userId,
          email: customerEmail,
          name: userName,
        );
        customerId = customerData['customerId'];
        ephemeralKey = customerData['ephemeralKey'];
      }

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName ?? 'CrowdWave',
          customerEphemeralKeySecret: ephemeralKey,
          customerId: customerId,
          style: ThemeMode.system,
          billingDetails: stripe.BillingDetails(
            email: customerEmail,
          ),
          primaryButtonLabel: 'Pay Now',
          allowsDelayedPaymentMethods: false,
        ),
      );

      log('Payment sheet initialized successfully');
    } catch (e) {
      log('Failed to initialize payment sheet: $e');
      rethrow;
    }
  }

  /// Handle payment success
  Future<void> handlePaymentSuccess({
    required String paymentIntentId,
    required String bookingId,
  }) async {
    try {
      log('Handling payment success for booking: $bookingId');

      // Simple authentication check
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Call backend to confirm payment
      await _callBackendConfirmPayment(paymentIntentId, bookingId);

      log('Payment success handled for booking: $bookingId');
    } catch (e) {
      log('Failed to handle payment success: $e');
      throw Exception('Payment confirmation failed: $e');
    }
  }

  /// Handle payment failure
  Future<void> handlePaymentFailure({
    required String error,
    required String bookingId,
  }) async {
    try {
      log('Handling payment failure for booking: $bookingId');

      // Call backend to update booking status for failed payment
      await _callBackendPaymentFailure(bookingId, error);

      log('Payment failed for booking $bookingId: $error');
    } catch (e) {
      log('Failed to handle payment failure: $e');
      rethrow;
    }
  }

  /// Calculate platform fee (10% for now)
  double calculatePlatformFee(double amount) {
    return amount * 0.1; // 10% platform fee
  }

  /// Calculate traveler payout after platform fee
  double calculateTravelerPayout(double amount) {
    return amount - calculatePlatformFee(amount);
  }

  /// Enhanced error handling for different Stripe errors
  PaymentResult _handleStripeError(stripe.StripeException error) {
    log('Handling Stripe error: ${error.error.code} - ${error.error.message}');

    PaymentErrorType errorType;
    String userFriendlyMessage;

    // Handle error based on error message since FailureCode constants vary
    final errorCodeString = error.error.code.toString().toLowerCase();
    final errorMessage = error.error.message?.toLowerCase() ?? '';

    if (errorCodeString.contains('card') &&
        errorCodeString.contains('declined')) {
      errorType = PaymentErrorType.cardDeclined;
      userFriendlyMessage =
          'Your card was declined. Please try a different payment method.';
    } else if (errorMessage.contains('insufficient') ||
        errorMessage.contains('funds')) {
      errorType = PaymentErrorType.insufficientFunds;
      userFriendlyMessage =
          'Insufficient funds. Please check your account balance or use a different card.';
    } else if (errorMessage.contains('expired')) {
      errorType = PaymentErrorType.expiredCard;
      userFriendlyMessage =
          'Your card has expired. Please use a different payment method.';
    } else if (errorMessage.contains('cvc') ||
        errorMessage.contains('security')) {
      errorType = PaymentErrorType.incorrectCvc;
      userFriendlyMessage =
          'The card security code is incorrect. Please check and try again.';
    } else if (errorMessage.contains('number') ||
        errorMessage.contains('card')) {
      errorType = PaymentErrorType.incorrectNumber;
      userFriendlyMessage =
          'The card number is incorrect. Please check and try again.';
    } else if (errorMessage.contains('authentication') ||
        errorMessage.contains('verify')) {
      errorType = PaymentErrorType.authenticationFailed;
      userFriendlyMessage = 'Payment authentication failed. Please try again.';
    } else if (errorMessage.contains('processing') ||
        errorMessage.contains('api')) {
      errorType = PaymentErrorType.apiError;
      userFriendlyMessage = 'Payment processing error. Please try again.';
    } else {
      errorType = PaymentErrorType.unknown;
      userFriendlyMessage =
          error.error.localizedMessage ?? 'Payment failed. Please try again.';
    }

    return PaymentResult(
      status: PaymentStatus.failed,
      error: userFriendlyMessage,
      errorType: errorType,
      metadata: {
        'stripe_error_code': error.error.code.toString(),
        'stripe_error_message': error.error.message,
      },
    );
  }

  /// Handle network and timeout errors
  PaymentResult _handleNetworkError(dynamic error) {
    log('Handling network error: $error');

    String errorString = error.toString().toLowerCase();
    PaymentErrorType errorType;
    String userFriendlyMessage;

    if (errorString.contains('timeout') || errorString.contains('time out')) {
      errorType = PaymentErrorType.timeout;
      userFriendlyMessage =
          'Payment request timed out. Please check your connection and try again.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      errorType = PaymentErrorType.networkError;
      userFriendlyMessage =
          'Network connection issue. Please check your internet and try again.';
    } else {
      errorType = PaymentErrorType.unknown;
      userFriendlyMessage = 'An unexpected error occurred. Please try again.';
    }

    return PaymentResult(
      status: PaymentStatus.failed,
      error: userFriendlyMessage,
      errorType: errorType,
      metadata: {
        'original_error': error.toString(),
      },
    );
  }

  /// Process payment with comprehensive error handling
  Future<PaymentResult> processPaymentWithErrorHandling({
    required stripe.PaymentIntent paymentIntent,
    required BuildContext context,
    int maxRetries = 1, // Reduced from 3 to 1
    Duration retryDelay = const Duration(seconds: 1), // Reduced from 2 to 1
  }) async {
    try {
      log('Processing payment for intent: ${paymentIntent.id}');

      // Present payment sheet
      await stripe.Stripe.instance.presentPaymentSheet();

      // If we reach here, payment was successful
      log('Payment completed successfully');

      return PaymentResult(
        status: PaymentStatus.succeeded,
        paymentIntentId: paymentIntent.id,
        metadata: {
          'completion_time': DateTime.now().toIso8601String(),
        },
      );
    } on stripe.StripeException catch (e) {
      log('Stripe error during payment: ${e.error}');
      return _handleStripeError(e);
    } catch (e) {
      log('Unexpected error during payment: $e');
      return _handleNetworkError(e);
    }
  }

  /// Get user-friendly error message with suggestions
  String getErrorMessageWithSuggestions(PaymentErrorType errorType) {
    switch (errorType) {
      case PaymentErrorType.cardDeclined:
        return 'Your card was declined. Try:\n• Checking with your bank\n• Using a different card\n• Verifying card details';
      case PaymentErrorType.insufficientFunds:
        return 'Insufficient funds. Try:\n• Checking your account balance\n• Using a different payment method\n• Adding funds to your account';
      case PaymentErrorType.expiredCard:
        return 'Your card has expired. Please use a current, valid payment method.';
      case PaymentErrorType.incorrectCvc:
        return 'Security code is incorrect. Please check the 3 or 4 digit code on your card.';
      case PaymentErrorType.incorrectNumber:
        return 'Card number is incorrect. Please double-check your card details.';
      case PaymentErrorType.networkError:
        return 'Connection issue. Try:\n• Checking your internet connection\n• Moving to a better network area\n• Trying again in a moment';
      case PaymentErrorType.timeout:
        return 'Request timed out. Please try again. If the problem persists, check your connection.';
      case PaymentErrorType.authenticationFailed:
        return 'Authentication failed. Please verify your payment details and try again.';
      case PaymentErrorType.apiError:
        return 'Service temporarily unavailable. Please try again in a few moments.';
      case PaymentErrorType.invalidRequest:
        return 'Invalid payment request. Please try again or contact support.';
      case PaymentErrorType.unknown:
        return 'An unexpected error occurred. Please try again or contact support if the problem persists.';
    }
  }

  /// Get supported payment methods based on platform and availability
  Future<List<PaymentMethod>> getSupportedPaymentMethods() async {
    if (kDebugMode) {
      print('🔧 Getting supported payment methods...');
    }

    final supportedMethods = <PaymentMethod>[
      PaymentMethod.creditCard,
      PaymentMethod.debitCard,
    ];

    // Add platform-specific payment methods based on availability
    if (await isPaymentMethodAvailable(PaymentMethod.applePay)) {
      supportedMethods.add(PaymentMethod.applePay);
      if (kDebugMode) print('✅ Apple Pay available');
    }

    if (await isPaymentMethodAvailable(PaymentMethod.googlePay)) {
      supportedMethods.add(PaymentMethod.googlePay);
      if (kDebugMode) print('✅ Google Pay available');
    }

    if (await isPaymentMethodAvailable(PaymentMethod.paypal)) {
      supportedMethods.add(PaymentMethod.paypal);
      if (kDebugMode) print('✅ PayPal available');
    }

    if (await isPaymentMethodAvailable(PaymentMethod.bankTransfer)) {
      supportedMethods.add(PaymentMethod.bankTransfer);
      if (kDebugMode) print('✅ Bank Transfer available');
    }

    if (kDebugMode) {
      print(
          '💳 Final supported payment methods: ${supportedMethods.map((m) => m.name).join(', ')}');
    }

    return supportedMethods;
  }

  /// Check if a payment method is available on current platform
  Future<bool> isPaymentMethodAvailable(PaymentMethod method) async {
    switch (method) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return true;

      case PaymentMethod.applePay:
        // Apple Pay is only available on iOS devices
        return Platform.isIOS && await _isApplePaySupported();

      case PaymentMethod.googlePay:
        // Google Pay is primarily for Android, but also available on iOS
        return await _isGooglePaySupported();

      case PaymentMethod.paypal:
        // PayPal is available on all platforms with proper SDK integration
        return _isPayPalSupported();

      case PaymentMethod.bankTransfer:
        // Bank transfer availability depends on region and implementation
        return _isBankTransferSupported();
    }
  }

  /// Check if Apple Pay is supported on the current device
  Future<bool> _isApplePaySupported() async {
    if (!Platform.isIOS) return false;

    try {
      // Check if Apple Pay is available on the device using platform-specific check
      // For now, return true for iOS devices as Apple Pay availability
      // requires device-specific implementation
      return true; // Most modern iOS devices support Apple Pay
    } catch (e) {
      log('Error checking Apple Pay support: $e');
      return false;
    }
  }

  /// Check if Google Pay is supported on the current device
  Future<bool> _isGooglePaySupported() async {
    try {
      // Check if Google Pay is available on the device with proper configuration
      final params = stripe.IsGooglePaySupportedParams();
      final isSupported =
          await stripe.Stripe.instance.isGooglePaySupported(params);

      log('Google Pay availability check: $isSupported (Platform: ${Platform.operatingSystem})');
      return isSupported;
    } catch (e) {
      log('Error checking Google Pay support: $e');
      // Enhanced fallback logic with device capability checks
      if (Platform.isAndroid) {
        // Check Android version (Google Pay requires Android 4.4+)
        return true; // Assume modern Android devices support Google Pay
      } else if (Platform.isIOS) {
        // Google Pay is also available on iOS
        return true; // Available on iOS 12.0+
      }
      return false;
    }
  }

  /// Check if PayPal is supported (requires PayPal SDK integration)
  bool _isPayPalSupported() {
    // For now, return false until PayPal SDK is integrated
    // TODO: Integrate PayPal SDK and implement proper availability check
    return false;
  }

  /// Check if bank transfer is supported in current region
  bool _isBankTransferSupported() {
    // Bank transfer support depends on:
    // 1. Regional availability (SEPA, ACH, etc.)
    // 2. Banking partner integration
    // 3. Regulatory compliance
    // TODO: Implement region-based bank transfer availability
    return false;
  }
}

/// Payment processing status for service layer
enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
  requiresAction,
}

/// Result of payment processing
class PaymentResult {
  final PaymentStatus status;
  final String? paymentIntentId;
  final String? error;
  final PaymentErrorType? errorType;
  final Map<String, dynamic>? metadata;

  PaymentResult({
    required this.status,
    this.paymentIntentId,
    this.error,
    this.errorType,
    this.metadata,
  });

  bool get isSuccess => status == PaymentStatus.succeeded;
  bool get isFailed => status == PaymentStatus.failed;
  bool get requiresAction => status == PaymentStatus.requiresAction;
}

/// Types of payment errors for better error handling
enum PaymentErrorType {
  // Card errors
  cardDeclined,
  insufficientFunds,
  expiredCard,
  incorrectCvc,
  incorrectNumber,

  // Network errors
  networkError,
  timeout,

  // Authentication errors
  authenticationFailed,

  // API errors
  apiError,
  invalidRequest,

  // Generic errors
  unknown,
}
