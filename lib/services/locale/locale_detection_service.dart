import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../translations/supported_locales.dart';

class LocaleDetectionService {
  static const String _keyLanguageDialogShown = 'language_dialog_shown';
  static const String _keySelectedLanguage = 'selected_language';

  /// Check if language dialog has been shown before
  Future<bool> shouldShowLanguageDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(_keyLanguageDialogShown) ?? false;
    return !hasShown;
  }

  /// Mark language dialog as shown
  Future<void> markLanguageDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLanguageDialogShown, true);
  }

  /// Detect user's locale based on device settings and location
  Future<LocaleDetectionResult> detectLocale() async {
    // Try device locale first
    String languageCode = await _getDeviceLanguageCode();
    String countryCode = await _getDeviceCountryCode();

    // Try to get more accurate location if permissions allow
    try {
      final position = await _getUserLocation();
      if (position != null) {
        final countryFromLocation = await _getCountryFromPosition(position);
        if (countryFromLocation != null) {
          countryCode = countryFromLocation;
          // Update language based on location
          languageCode = SupportedLocales.getLanguageFromCountry(countryCode);
        }
      }
    } catch (e) {
      print('Could not get location: $e');
      // Fall back to device settings
    }

    // Get language info
    final languageInfo = SupportedLocales.getLanguageInfo(languageCode) ??
        SupportedLocales.getLanguageInfo('en')!;

    return LocaleDetectionResult(
      languageCode: languageCode,
      countryCode: countryCode,
      countryName: _getCountryName(countryCode),
      languageInfo: languageInfo,
      detectionMethod: 'device_and_location',
    );
  }

  /// Get device language code
  Future<String> _getDeviceLanguageCode() async {
    try {
      // Get from Flutter's platform
      final locale = WidgetsBinding.instance.window.locale;
      final langCode = locale.languageCode;

      // Check if we support this language
      if (SupportedLocales.isSupported(langCode)) {
        return langCode;
      }

      // Default to English
      return 'en';
    } catch (e) {
      return 'en';
    }
  }

  /// Get device country code
  Future<String> _getDeviceCountryCode() async {
    try {
      final locale = WidgetsBinding.instance.window.locale;
      return locale.countryCode ?? 'GB';
    } catch (e) {
      return 'GB';
    }
  }

  /// Get user's location
  Future<Position?> _getUserLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permissions
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get position with timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get country from GPS position
  Future<String?> _getCountryFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        return placemarks.first.isoCountryCode?.toUpperCase();
      }
    } catch (e) {
      print('Error getting country from position: $e');
    }
    return null;
  }

  /// Get country name from code
  String _getCountryName(String countryCode) {
    const countryNames = {
      'GB': 'United Kingdom',
      'US': 'United States',
      'DE': 'Germany',
      'AT': 'Austria',
      'FR': 'France',
      'ES': 'Spain',
      'IT': 'Italy',
      'PL': 'Poland',
      'LT': 'Lithuania',
      'GR': 'Greece',
      'CY': 'Cyprus',
      'NL': 'Netherlands',
      'PT': 'Portugal',
      'RO': 'Romania',
      'CZ': 'Czech Republic',
      'SE': 'Sweden',
    };
    return countryNames[countryCode] ?? 'your country';
  }

  /// Update app locale
  Future<void> updateLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedLanguage, languageCode);
  }

  /// Get saved language
  Future<String?> getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedLanguage);
  }
}

/// Locale detection result
class LocaleDetectionResult {
  final String languageCode;
  final String countryCode;
  final String countryName;
  final LanguageInfo languageInfo;
  final String detectionMethod;

  LocaleDetectionResult({
    required this.languageCode,
    required this.countryCode,
    required this.countryName,
    required this.languageInfo,
    required this.detectionMethod,
  });
}
