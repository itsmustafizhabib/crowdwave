import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// 🔐 Agora Token Generator
///
/// ⚠️ WARNING: This is for DEVELOPMENT/TESTING ONLY!
/// In production, tokens MUST be generated server-side to keep your appCertificate secure.
///
/// Reference: https://docs.agora.io/en/video-calling/develop/authentication-workflow
enum RtcRole {
  publisher, // Can publish and subscribe
  subscriber, // Can only subscribe
}

class AgoraTokenGenerator {
  /// Generate an Agora RTC token
  static String generateRtcToken({
    required String appId,
    required String appCertificate,
    required String channelName,
    required int uid,
    required RtcRole role,
    int expireTime = 86400, // 24 hours in seconds
  }) {
    if (appCertificate.isEmpty) {
      throw Exception('App Certificate is required for token generation');
    }

    final privilege = role == RtcRole.publisher ? 1 : 2;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expireTimestamp = now + expireTime;

    // Build message
    final message = '$appId$channelName$uid$expireTimestamp$privilege';

    // Generate signature using HMAC SHA256
    final key = utf8.encode(appCertificate);
    final bytes = utf8.encode(message);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);

    // Create token
    final token = base64Url.encode(digest.bytes);

    return token;
  }

  /// Generate token with default publisher role
  static String generatePublisherToken({
    required String appId,
    required String appCertificate,
    required String channelName,
    required int uid,
    int expireTime = 86400,
  }) {
    return generateRtcToken(
      appId: appId,
      appCertificate: appCertificate,
      channelName: channelName,
      uid: uid,
      role: RtcRole.publisher,
      expireTime: expireTime,
    );
  }
}
