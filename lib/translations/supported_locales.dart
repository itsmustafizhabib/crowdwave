class SupportedLocales {
  static const Map<String, LanguageInfo> languages = {
    'en': LanguageInfo(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      countryCode: 'GB',
      flag: '🇬🇧',
    ),
    'de': LanguageInfo(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      countryCode: 'DE',
      flag: '🇩🇪',
    ),
    'fr': LanguageInfo(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      countryCode: 'FR',
      flag: '🇫🇷',
    ),
    'es': LanguageInfo(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      countryCode: 'ES',
      flag: '🇪🇸',
    ),
    'it': LanguageInfo(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
      countryCode: 'IT',
      flag: '🇮🇹',
    ),
    'pl': LanguageInfo(
      code: 'pl',
      name: 'Polish',
      nativeName: 'Polski',
      countryCode: 'PL',
      flag: '🇵🇱',
    ),
    'lt': LanguageInfo(
      code: 'lt',
      name: 'Lithuanian',
      nativeName: 'Lietuvių',
      countryCode: 'LT',
      flag: '🇱🇹',
    ),
    'el': LanguageInfo(
      code: 'el',
      name: 'Greek',
      nativeName: 'Ελληνικά',
      countryCode: 'GR',
      flag: '🇬🇷',
    ),
    'nl': LanguageInfo(
      code: 'nl',
      name: 'Dutch',
      nativeName: 'Nederlands',
      countryCode: 'NL',
      flag: '🇳🇱',
    ),
    'pt': LanguageInfo(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      countryCode: 'PT',
      flag: '🇵🇹',
    ),
    'ro': LanguageInfo(
      code: 'ro',
      name: 'Romanian',
      nativeName: 'Română',
      countryCode: 'RO',
      flag: '🇷🇴',
    ),
    'cs': LanguageInfo(
      code: 'cs',
      name: 'Czech',
      nativeName: 'Čeština',
      countryCode: 'CZ',
      flag: '🇨🇿',
    ),
    'sv': LanguageInfo(
      code: 'sv',
      name: 'Swedish',
      nativeName: 'Svenska',
      countryCode: 'SE',
      flag: '🇸🇪',
    ),
    'bg': LanguageInfo(
      code: 'bg',
      name: 'Bulgarian',
      nativeName: 'Български',
      countryCode: 'BG',
      flag: '🇧🇬',
    ),
    'hr': LanguageInfo(
      code: 'hr',
      name: 'Croatian',
      nativeName: 'Hrvatski',
      countryCode: 'HR',
      flag: '🇭🇷',
    ),
    'da': LanguageInfo(
      code: 'da',
      name: 'Danish',
      nativeName: 'Dansk',
      countryCode: 'DK',
      flag: '🇩🇰',
    ),
    'et': LanguageInfo(
      code: 'et',
      name: 'Estonian',
      nativeName: 'Eesti',
      countryCode: 'EE',
      flag: '🇪🇪',
    ),
    'fi': LanguageInfo(
      code: 'fi',
      name: 'Finnish',
      nativeName: 'Suomi',
      countryCode: 'FI',
      flag: '🇫🇮',
    ),
    'hu': LanguageInfo(
      code: 'hu',
      name: 'Hungarian',
      nativeName: 'Magyar',
      countryCode: 'HU',
      flag: '🇭🇺',
    ),
    'ga': LanguageInfo(
      code: 'ga',
      name: 'Irish',
      nativeName: 'Gaeilge',
      countryCode: 'IE',
      flag: '🇮🇪',
    ),
    'lv': LanguageInfo(
      code: 'lv',
      name: 'Latvian',
      nativeName: 'Latviešu',
      countryCode: 'LV',
      flag: '🇱🇻',
    ),
    'mt': LanguageInfo(
      code: 'mt',
      name: 'Maltese',
      nativeName: 'Malti',
      countryCode: 'MT',
      flag: '🇲🇹',
    ),
    'sk': LanguageInfo(
      code: 'sk',
      name: 'Slovak',
      nativeName: 'Slovenčina',
      countryCode: 'SK',
      flag: '🇸🇰',
    ),
    'sl': LanguageInfo(
      code: 'sl',
      name: 'Slovenian',
      nativeName: 'Slovenščina',
      countryCode: 'SI',
      flag: '🇸🇮',
    ),
    'ka': LanguageInfo(
      code: 'ka',
      name: 'Georgian',
      nativeName: 'ქართული',
      countryCode: 'GE',
      flag: '🇬🇪',
    ),
  };

  /// Country to language mapping
  static const Map<String, String> countryToLanguage = {
    'GB': 'en', // United Kingdom
    'US': 'en', // United States
    'DE': 'de', // Germany
    'AT': 'de', // Austria
    'CH': 'de', // Switzerland (German-speaking)
    'FR': 'fr', // France
    'BE': 'fr', // Belgium (French-speaking)
    'LU': 'fr', // Luxembourg
    'ES': 'es', // Spain
    'IT': 'it', // Italy
    'PL': 'pl', // Poland
    'LT': 'lt', // Lithuania
    'GR': 'el', // Greece
    'CY': 'el', // Cyprus
    'NL': 'nl', // Netherlands
    'PT': 'pt', // Portugal
    'BR': 'pt', // Brazil
    'RO': 'ro', // Romania
    'CZ': 'cs', // Czech Republic
    'SE': 'sv', // Sweden
    'BG': 'bg', // Bulgaria
    'HR': 'hr', // Croatia
    'DK': 'da', // Denmark
    'EE': 'et', // Estonia
    'FI': 'fi', // Finland
    'HU': 'hu', // Hungary
    'IE': 'ga', // Ireland
    'LV': 'lv', // Latvia
    'MT': 'mt', // Malta
    'SK': 'sk', // Slovakia
    'SI': 'sl', // Slovenia
    'GE': 'ka', // Georgia
  };

  /// Get language code from country code
  static String getLanguageFromCountry(String countryCode) {
    return countryToLanguage[countryCode.toUpperCase()] ?? 'en';
  }

  /// Get all supported language codes
  static List<String> get supportedLanguageCodes => languages.keys.toList();

  /// Get language info by code
  static LanguageInfo? getLanguageInfo(String code) => languages[code];

  /// Check if language is supported
  static bool isSupported(String code) => languages.containsKey(code);
}

class LanguageInfo {
  final String code;
  final String name;
  final String nativeName;
  final String countryCode;
  final String flag;

  const LanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.countryCode,
    required this.flag,
  });
}
