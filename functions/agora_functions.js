const functions = require('firebase-functions');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

// 🔑 Agora Configuration
const AGORA_APP_ID = 'db2ca44a159b4e079483a662e32777e5';
const AGORA_APP_CERTIFICATE = 'e7a1b5ba363d4519bf6fa9e4853aec78';

/**
 * 🔐 Generate Agora RTC Token
 * 
 * This Cloud Function generates a secure Agora token for voice/video calls.
 * The token is generated server-side to keep the App Certificate secure.
 * 
 * @param {Object} data - Request data
 * @param {string} data.channelName - The name of the Agora channel
 * @param {number} data.uid - User ID (0 for auto-assigned)
 * @param {string} data.role - 'publisher' or 'subscriber'
 * @param {number} data.expirationTime - Token expiration time in seconds (optional, default: 3600)
 * 
 * @returns {Object} - { token: string, expiresAt: number }
 */
exports.generateAgoraToken = functions.https.onCall(async (data, context) => {
  try {
    // ✅ Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to generate token'
      );
    }

    // ✅ Validate request data
    const { channelName, uid, role, expirationTime } = data;

    if (!channelName) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Channel name is required'
      );
    }

    // ✅ Set defaults
    const userUid = uid || 0; // 0 means Agora will auto-assign UID
    const userRole = role === 'subscriber' ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;
    const expireTimeInSeconds = expirationTime || 3600; // Default: 1 hour

    // ✅ Calculate expiration timestamp
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expireTimeInSeconds;

    // ✅ Generate token using Agora's official token builder
    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      userUid,
      userRole,
      privilegeExpiredTs
    );

    console.log('✅ Agora token generated successfully:', {
      userId: context.auth.uid,
      channelName,
      uid: userUid,
      role: userRole === RtcRole.PUBLISHER ? 'publisher' : 'subscriber',
      expiresAt: privilegeExpiredTs,
    });

    // ✅ Return token and expiration info
    return {
      token,
      expiresAt: privilegeExpiredTs,
      appId: AGORA_APP_ID,
    };
  } catch (error) {
    console.error('❌ Error generating Agora token:', error);

    // Re-throw HttpsError as-is
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    // Wrap other errors
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate token: ' + error.message
    );
  }
});

/**
 * 🔄 Renew Agora Token
 * 
 * Similar to generateAgoraToken but optimized for token renewal.
 * Can be called when a token is about to expire.
 */
exports.renewAgoraToken = functions.https.onCall(async (data, context) => {
  // Reuse the same logic as generateAgoraToken
  return exports.generateAgoraToken.run(data, context);
});
