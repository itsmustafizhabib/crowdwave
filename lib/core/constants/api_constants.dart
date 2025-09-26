class ApiConstants {
  // Google Maps API Configuration - Environment specific
  static String get googleMapsApiKey {
    switch (EnvironmentConfig.currentEnvironment) {
      case Environment.development:
        return 'AIzaSyC8gJgw5v3LQ2Y7IeTTfWP3ikey-P9xtqI'; // Development key
      case Environment.staging:
        return 'AIzaSyC8gJgw5v3LQ2Y7IeTTfWP3ikey-P9xtqI'; // Same key for staging
      case Environment.production:
        return String.fromEnvironment('GOOGLE_MAPS_API_KEY',
            defaultValue:
                'AIzaSyC8gJgw5v3LQ2Y7IeTTfWP3ikey-P9xtqI'); // Use env var for production
    }
  }

  static const String googleMapsBaseUrl =
      'https://maps.googleapis.com/maps/api';
  static const String googleDirectionsUrl =
      '$googleMapsBaseUrl/directions/json';
  static const String googleDistanceMatrixUrl =
      '$googleMapsBaseUrl/distancematrix/json';
  static const String googlePlacesUrl = '$googleMapsBaseUrl/place';
  static const String googleGeocodingUrl = '$googleMapsBaseUrl/geocode/json';

  // Stripe Payment Configuration
  static const String stripePublishableKey =
      'pk_test_51S64oML7IY4cP40SDnoFhLy05kukbObqCA0yeEwYldDqYzOAVdwr11GAz2bGcow54EGQ61TFyxhpuINdymaKDTyP00tkU4U3Kj'; // Test key for development

  // Stripe Webhook URL - Environment specific
  static String get stripeWebhookUrl {
    switch (EnvironmentConfig.currentEnvironment) {
      case Environment.development:
        return 'https://dev-api.crowdwave.com/webhook/stripe';
      case Environment.staging:
        return 'https://staging-api.crowdwave.com/webhook/stripe';
      case Environment.production:
        return 'https://api.crowdwave.com/webhook/stripe';
    }
  }

  // Firebase Configuration (already configured in firebase_options.dart)
  // Project ID: crowdwave-93d4d

  // Twilio SMS Configuration (Environment-specific)
  static String get twilioAccountSid =>
      String.fromEnvironment('TWILIO_ACCOUNT_SID', defaultValue: '');
  static String get twilioAuthToken =>
      String.fromEnvironment('TWILIO_AUTH_TOKEN', defaultValue: '');
  static String get twilioPhoneNumber =>
      String.fromEnvironment('TWILIO_PHONE_NUMBER', defaultValue: '');

  // WhatsApp Business API (Production notifications - Environment-specific)
  static const String whatsappApiUrl = 'https://graph.facebook.com/v18.0';
  static String get whatsappBusinessPhoneId =>
      String.fromEnvironment('WHATSAPP_BUSINESS_PHONE_ID', defaultValue: '');
  static String get whatsappAccessToken =>
      String.fromEnvironment('WHATSAPP_ACCESS_TOKEN', defaultValue: '');

  // KYC/Verification APIs (Environment-secure configuration)
  // Jumio Identity Verification
  static String get jumioApiUrl {
    switch (EnvironmentConfig.currentEnvironment) {
      case Environment.development:
        return 'https://api.jumio.com'; // Sandbox URL for development
      case Environment.staging:
        return 'https://api.jumio.com'; // Same as dev for staging
      case Environment.production:
        return 'https://api.jumio.com'; // Production URL
    }
  }

  static String get jumioApiKey =>
      String.fromEnvironment('JUMIO_API_KEY', defaultValue: '');

  // Onfido Document Verification
  static String get onfidoApiUrl {
    switch (EnvironmentConfig.currentEnvironment) {
      case Environment.development:
        return 'https://api.eu.onfido.com/v3.6'; // EU region for all envs
      case Environment.staging:
        return 'https://api.eu.onfido.com/v3.6';
      case Environment.production:
        return 'https://api.eu.onfido.com/v3.6';
    }
  }

  static String get onfidoApiKey =>
      String.fromEnvironment('ONFIDO_API_KEY', defaultValue: '');

  // App Configuration
  static const String appVersion = '1.0.0';
  static const String appName = 'CrowdWave';

  // Route Optimization Configuration
  static const double defaultSearchRadiusKm = 50.0;
  static const int maxWaypointsPerRoute = 25; // Google Maps API limit
  static const double maxDetourPercentage =
      0.3; // 30% additional distance allowed

  // Business Logic Constants
  static const double platformFeePercentage = 0.1; // 10% platform fee
  static const int maxPackagesPerTrip = 10;
  static const double minCompensationUSD = 1.0;
  static const double maxCompensationUSD = 1000.0;

  // Notification Settings
  static const bool enablePushNotifications = true;
  static const bool enableSMSNotifications = true;
  static const bool enableEmailNotifications = true;

  // Cache Settings
  static const int locationCacheTimeoutMinutes = 30;
  static const int routeCacheTimeoutMinutes = 15;
}

class ApiEndpoints {
  // Your Backend API Endpoints (if you have a custom backend)
  static const String baseUrl = 'https://your-backend-api.com/v1';

  // Authentication
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String refreshToken = '$baseUrl/auth/refresh';

  // Trip Management
  static const String trips = '$baseUrl/trips';
  static const String optimizeRoute = '$baseUrl/trips/optimize-route';
  static const String checkDetour = '$baseUrl/trips/check-detour';

  // Package Management
  static const String packages = '$baseUrl/packages';
  static const String matchPackages = '$baseUrl/packages/match';

  // Payment
  static const String createPaymentIntent = '$baseUrl/payments/create-intent';
  static const String confirmPayment = '$baseUrl/payments/confirm';
  static const String refundPayment = '$baseUrl/payments/refund';

  // Notifications
  static const String sendNotification = '$baseUrl/notifications/send';
  static const String updateNotificationPreferences =
      '$baseUrl/notifications/preferences';

  // Analytics
  static const String trackEvent = '$baseUrl/analytics/track';
  static const String userAnalytics = '$baseUrl/analytics/user';
}

// Environment-specific configuration
enum Environment { development, staging, production }

class EnvironmentConfig {
  static const Environment currentEnvironment = Environment.development;

  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'https://dev-api.crowdwave.com/v1';
      case Environment.staging:
        return 'https://staging-api.crowdwave.com/v1';
      case Environment.production:
        return 'https://api.crowdwave.com/v1';
    }
  }

  static String get stripePublishableKey {
    switch (currentEnvironment) {
      case Environment.development:
        // For development, use proper test keys from Stripe dashboard
        // Go to: https://dashboard.stripe.com/test/apikeys
        // Replace with your actual test publishable key
        return 'pk_test_51S64oML7IY4cP40SDnoFhLy05kukbObqCA0yeEwYldDqYzOAVdwr11GAz2bGcow54EGQ61TFyxhpuINdymaKDTyP00tkU4U3Kj'; // ✅ CONFIGURED: Your actual test key
      case Environment.staging:
        return 'pk_test_51S64oML7IY4cP40SDnoFhLy05kukbObqCA0yeEwYldDqYzOAVdwr11GAz2bGcow54EGQ61TFyxhpuINdymaKDTyP00tkU4U3Kj'; // Same test keys for staging
      case Environment.production:
        return 'pk_live_51S64nyQ2GpVkQ4xbMXoTvprGUbCCY5yZ3x1Q9nsFIgvP2jvxca0nsMab5VSepBe1P0yM1stF5N6jpazC5dVRrs9M00vgQUcdJh'; // Your live key
    }
  }

  // Stripe Secret Keys (for server-side operations)
  static String get stripeSecretKey {
    switch (currentEnvironment) {
      case Environment.development:
        return String.fromEnvironment('STRIPE_TEST_SECRET_KEY',
            defaultValue:
                'sk_test_your_test_key_here'); // Use environment variable
      case Environment.staging:
        return String.fromEnvironment('STRIPE_TEST_SECRET_KEY',
            defaultValue: 'sk_test_your_test_key_here');
      case Environment.production:
        return String.fromEnvironment(
            'STRIPE_SECRET_KEY'); // Use environment variable for production
    }
  }

  static bool get enableLogging => currentEnvironment != Environment.production;
  static bool get enableAnalytics =>
      currentEnvironment == Environment.production;
}
