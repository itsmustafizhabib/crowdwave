const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Stripe with better error handling
let stripeKey;
try {
  stripeKey = process.env.STRIPE_SECRET_KEY || functions.config().stripe?.secret_key;
  if (!stripeKey) {
    console.error('❌ STRIPE_SECRET_KEY not found in environment or config');
    throw new Error('Stripe secret key is required');
  }
  console.log('✅ Stripe key loaded successfully');
} catch (error) {
  console.error('❌ Error loading Stripe configuration:', error);
  stripeKey = 'sk_test_placeholder'; // Fallback to prevent crash
}

const stripe = require('stripe')(stripeKey);

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Test Authentication
 * Simple test function to verify auth is working
 */
exports.testAuth = functions.https.onCall(async (data, context) => {
  functions.logger.info('testAuth called', {
    hasAuth: !!context.auth,
    authUid: context.auth?.uid,
    authEmail: context.auth?.token?.email,
    authProvider: context.auth?.token?.firebase?.sign_in_provider,
    tokenExp: context.auth?.token?.exp,
    tokenIat: context.auth?.token?.iat,
    serverTime: Math.floor(Date.now() / 1000),
  });
  
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Not authenticated'
    );
  }
  
  // Check token timing
  const now = Math.floor(Date.now() / 1000);
  const exp = context.auth.token?.exp;
  const iat = context.auth.token?.iat;
  
  return {
    message: 'Authentication successful!',
    uid: context.auth.uid,
    email: context.auth.token?.email,
    provider: context.auth.token?.firebase?.sign_in_provider,
    tokenInfo: {
      issued: iat,
      expires: exp,
      serverTime: now,
      timeToExpiry: exp ? exp - now : null,
      tokenAge: iat ? now - iat : null,
    }
  };
});

/**
 * Debug Payment Authentication
 * Detailed authentication diagnostics for payment issues
 */
exports.debugPaymentAuth = functions.https.onCall(async (data, context) => {
  const debugInfo = {
    timestamp: new Date().toISOString(),
    serverTime: Math.floor(Date.now() / 1000),
    hasAuth: !!context.auth,
    authContext: null,
    headers: null,
    request: null,
  };

  // Log headers for debugging
  if (context.rawRequest) {
    debugInfo.headers = {
      authorization: context.rawRequest.headers?.authorization ? 'present' : 'missing',
      userAgent: context.rawRequest.headers?.['user-agent'],
      origin: context.rawRequest.headers?.origin,
    };
  }

  if (context.auth) {
    debugInfo.authContext = {
      uid: context.auth.uid,
      email: context.auth.token?.email,
      provider: context.auth.token?.firebase?.sign_in_provider,
      emailVerified: context.auth.token?.email_verified,
      tokenExp: context.auth.token?.exp,
      tokenIat: context.auth.token?.iat,
      timeToExpiry: context.auth.token?.exp ? context.auth.token.exp - debugInfo.serverTime : null,
      tokenAge: context.auth.token?.iat ? debugInfo.serverTime - context.auth.token.iat : null,
    };
    
    functions.logger.info('Debug payment auth - success', debugInfo);
    return debugInfo;
  } else {
    functions.logger.error('Debug payment auth - no auth context', debugInfo);
    throw new functions.https.HttpsError(
      'unauthenticated',
      'No authentication context found'
    );
  }
});

/**
 * Create Payment Intent Handler
 * Core logic shared by multiple exported callable names for backward compatibility
 */
const createPaymentIntentHandler = async (data, context) => {
  try {
    // Enhanced authentication verification
    functions.logger.info('Authentication check:', {
      hasAuth: !!context.auth,
      authUid: context.auth?.uid,
      authEmail: context.auth?.token?.email,
      rawAuth: context.rawRequest?.headers?.authorization,
      data: data
    });

    // Verify user is authenticated
    if (!context.auth) {
      functions.logger.error('Authentication failed - no context.auth');
      functions.logger.error('Headers:', context.rawRequest?.headers);
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to create payment intent.'
      );
    }

    const { amount, currency, bookingId, metadata } = data || {};

    // Validate input
    if (!amount || !currency || !bookingId) {
      functions.logger.error('Missing required fields:', { amount, currency, bookingId });
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: amount, currency, bookingId'
      );
    }

    // Create payment intent with Stripe
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(Number(amount) * 100), // Convert to smallest unit
      currency: String(currency).toLowerCase(),
      metadata: {
        bookingId,
        userId: context.auth.uid,
        ...(metadata || {})
      },
      automatic_payment_methods: {
        enabled: true,
      },
    });

    functions.logger.info('Payment intent created', {
      paymentIntentId: paymentIntent.id,
      bookingId,
      userId: context.auth.uid
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id
    };
  } catch (error) {
    functions.logger.error('Error creating payment intent:', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to create payment intent'
    );
  }
};

/**
 * Export callable functions for multiple names for compatibility
 */
exports.createPaymentIntent = functions.https.onCall(createPaymentIntentHandler);
exports.createPaymentIntentFresh = functions.https.onCall(createPaymentIntentHandler);
exports.createMySpecialPaymentIntent = functions.https.onCall(createPaymentIntentHandler);

/**
 * Confirm Payment
 * Called after successful payment to update booking status
 */
exports.confirmPayment = functions.https.onCall(async (data, context) => {
  try {
    functions.logger.info('confirmPayment called', { 
      hasAuth: !!context.auth, 
      authUid: context.auth?.uid,
      authEmail: context.auth?.token?.email,
      rawAuth: context.rawRequest?.headers?.authorization,
      userAgent: context.rawRequest?.headers?.['user-agent'],
      data: data 
    });

    // Enhanced authentication verification
    if (!context.auth) {
      functions.logger.error('Authentication failed - no context.auth');
      functions.logger.error('Request headers:', context.rawRequest?.headers);
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication expired. Please sign in again and retry payment.'
      );
    }

    // Additional auth validation - check token expiry
    if (context.auth.token) {
      const now = Math.floor(Date.now() / 1000); // Current time in seconds
      const exp = context.auth.token.exp; // Token expiry
      const iat = context.auth.token.iat; // Token issued at
      
      functions.logger.info('Token timing check:', {
        serverTime: now,
        tokenExp: exp,
        tokenIat: iat,
        timeToExpiry: exp - now,
        tokenAge: now - iat
      });
      
      if (exp && exp <= now) {
        functions.logger.error('Token expired', {
          expiryTime: exp,
          currentTime: now,
          expiredBy: now - exp
        });
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication token has expired. Please sign in again and retry payment.'
        );
      }
      
      // Check if token is too old (more than 1 hour)
      if (iat && (now - iat) > 3600) {
        functions.logger.warn('Old token detected', {
          issuedAt: iat,
          currentTime: now,
          ageSeconds: now - iat
        });
      }
    }

    const { paymentIntentId, bookingId } = data;

    // Validate required parameters
    if (!paymentIntentId) {
      functions.logger.error('Missing paymentIntentId');
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required field: paymentIntentId'
      );
    }

    functions.logger.info('Starting payment confirmation', { paymentIntentId, bookingId, userId: context.auth.uid });

    // Retrieve payment intent from Stripe to verify it's successful
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (paymentIntent.status === 'succeeded') {
      // Update Firestore with payment confirmation
      const db = admin.firestore();
      
      // If bookingId is provided, update that specific booking
      if (bookingId) {
        // Update booking status
        await db.collection('bookings').doc(bookingId).update({
          paymentStatus: 'paid',
          paymentIntentId: paymentIntentId,
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Update package status to confirmed and create tracking
        const booking = await db.collection('bookings').doc(bookingId).get();
        if (booking.exists) {
          const packageId = booking.data().packageRequestId;
          
          try {
            // Check if package document exists before updating
            const packageRef = db.collection('packageRequests').doc(packageId);
            const packageDoc = await packageRef.get();
            
            if (packageDoc.exists) {
              await packageRef.update({
                status: 'confirmed',
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
              });
              functions.logger.info('Package status updated to confirmed', { packageId });
            } else {
              functions.logger.warn('Package document not found, skipping status update', { packageId });
            }
          } catch (packageUpdateError) {
            functions.logger.error('Failed to update package status', { 
              packageId, 
              error: packageUpdateError.message 
            });
            // Continue with tracking creation even if package update fails
          }

          // 🔥 AUTOMATIC TRACKING CREATION - Create delivery tracking after payment confirmation
          const bookingData = booking.data();
          const trackingId = db.collection('deliveryTracking').doc().id;
          
          await db.collection('deliveryTracking').doc(trackingId).set({
            id: trackingId,
            packageRequestId: packageId,
            travelerId: bookingData.travelerId,
            senderId: bookingData.senderId || context.auth.uid,
            bookingId: bookingId,
            status: 'pending',
            trackingPoints: [],
            currentLocation: null,
            estimatedDelivery: null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            notes: 'Booking confirmed - ready for pickup',
            // Additional fields for comprehensive tracking
            packageInfo: {
              name: bookingData.packageName || 'Package',
              description: bookingData.packageDescription || '',
              weight: bookingData.packageWeight || 0,
              dimensions: bookingData.packageDimensions || {}
            },
            route: {
              from: bookingData.pickupLocation || {},
              to: bookingData.deliveryLocation || {},
              distance: bookingData.distance || 0,
              estimatedDuration: bookingData.estimatedDuration || 0
            },
            pricing: {
              amount: bookingData.agreedPrice || 0,
              currency: bookingData.currency || 'USD',
              paymentStatus: 'paid'
            }
          });

          functions.logger.info('Automatic tracking created', {
            trackingId,
            packageId,
            bookingId,
            travelerId: bookingData.travelerId,
            userId: context.auth.uid
          });
        }
      } else {
        // Fallback: Try to find booking by paymentIntentId in metadata
        const bookingsQuery = await db.collection('bookings')
          .where('paymentIntentId', '==', paymentIntentId)
          .limit(1)
          .get();

        if (!bookingsQuery.empty) {
          const foundBooking = bookingsQuery.docs[0];
          const foundBookingId = foundBooking.id;
          
          // Update the found booking
          await db.collection('bookings').doc(foundBookingId).update({
            paymentStatus: 'paid',
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          functions.logger.info('Payment confirmed via paymentIntentId lookup', {
            paymentIntentId,
            foundBookingId,
            userId: context.auth.uid
          });
        }
      }

      functions.logger.info('Payment confirmed', {
        paymentIntentId,
        bookingId: bookingId || 'not provided',
        userId: context.auth.uid
      });

      return { 
        success: true, 
        status: 'payment_confirmed',
        bookingId: bookingId || 'auto-detected'
      };
    } else {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Payment not successful. Status: ${paymentIntent.status}`
      );
    }

  } catch (error) {
    functions.logger.error('Error confirming payment:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to confirm payment'
    );
  }
});

/**
 * Process Refund
 * Handle refund requests for cancelled bookings
 */
exports.processRefund = functions.https.onCall(async (data, context) => {
  try {
    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated.'
      );
    }

    const { paymentIntentId, amount, reason, bookingId } = data;

    // Create refund in Stripe
    const refund = await stripe.refunds.create({
      payment_intent: paymentIntentId,
      amount: amount ? Math.round(amount * 100) : undefined, // Partial or full refund
      reason: reason || 'requested_by_customer',
      metadata: {
        bookingId,
        userId: context.auth.uid
      }
    });

    // Update Firestore
    const db = admin.firestore();
    await db.collection('bookings').doc(bookingId).update({
      paymentStatus: 'refunded',
      refundId: refund.id,
      refundedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    functions.logger.info('Refund processed', {
      refundId: refund.id,
      paymentIntentId,
      bookingId,
      userId: context.auth.uid
    });

    return {
      success: true,
      refundId: refund.id,
      status: refund.status
    };

  } catch (error) {
    functions.logger.error('Error processing refund:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to process refund'
    );
  }
});

/**
 * Stripe Webhook Handler
 * Handle Stripe webhook events for payment updates
 */
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = functions.config().stripe?.webhook_secret || 'whsec_YOUR_WEBHOOK_SECRET';

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    functions.logger.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  const db = admin.firestore();

  // Handle the event
  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      functions.logger.info('Payment succeeded via webhook:', paymentIntent.id);
      
      // Update booking status if not already updated
      if (paymentIntent.metadata.bookingId) {
        const bookingDoc = await db.collection('bookings').doc(paymentIntent.metadata.bookingId).get();
        
        await db.collection('bookings').doc(paymentIntent.metadata.bookingId).update({
          paymentStatus: 'paid',
          webhookConfirmedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 🔥 WEBHOOK AUTOMATIC TRACKING CREATION - Fallback if direct call failed
        if (bookingDoc.exists) {
          const bookingData = bookingDoc.data();
          const packageId = bookingData.packageRequestId;
          
          // Check if tracking already exists to avoid duplicates
          const existingTracking = await db.collection('deliveryTracking')
            .where('bookingId', '==', paymentIntent.metadata.bookingId)
            .limit(1)
            .get();

          if (existingTracking.empty) {
            const trackingId = db.collection('deliveryTracking').doc().id;
            
            await db.collection('deliveryTracking').doc(trackingId).set({
              id: trackingId,
              packageRequestId: packageId,
              travelerId: bookingData.travelerId,
              senderId: bookingData.senderId,
              bookingId: paymentIntent.metadata.bookingId,
              status: 'pending',
              trackingPoints: [],
              currentLocation: null,
              estimatedDelivery: null,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              notes: 'Booking confirmed via webhook - ready for pickup',
              packageInfo: {
                name: bookingData.packageName || 'Package',
                description: bookingData.packageDescription || '',
                weight: bookingData.packageWeight || 0,
                dimensions: bookingData.packageDimensions || {}
              },
              route: {
                from: bookingData.pickupLocation || {},
                to: bookingData.deliveryLocation || {},
                distance: bookingData.distance || 0,
                estimatedDuration: bookingData.estimatedDuration || 0
              },
              pricing: {
                amount: bookingData.agreedPrice || 0,
                currency: bookingData.currency || 'USD',
                paymentStatus: 'paid'
              }
            });

            functions.logger.info('Automatic tracking created via webhook', {
              trackingId,
              packageId,
              bookingId: paymentIntent.metadata.bookingId,
              travelerId: bookingData.travelerId
            });
          } else {
            functions.logger.info('Tracking already exists, skipping creation', {
              bookingId: paymentIntent.metadata.bookingId
            });
          }
        }
      }
      break;
    
    case 'payment_intent.payment_failed':
      const failedPayment = event.data.object;
      functions.logger.info('Payment failed via webhook:', failedPayment.id);
      
      // Update booking status
      if (failedPayment.metadata.bookingId) {
        await db.collection('bookings').doc(failedPayment.metadata.bookingId).update({
          paymentStatus: 'failed',
          paymentFailedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }
      break;

    default:
      functions.logger.info(`Unhandled event type ${event.type}`);
  }

  res.json({received: true});
});

/**
 * Helper function to determine if notification should use normal priority
 * Offer-related notifications should use normal priority to prevent heads-up overlays
 */
function _shouldUseNormalPriority(notificationData) {
  if (!notificationData || !notificationData.type) {
    return false; // Default to high priority if no type specified
  }
  
  const normalPriorityTypes = [
    'offer_received',
    'offer_accepted', 
    'offer_rejected',
    'trip_update',
    'package_update',
    'general'
  ];
  
  return normalPriorityTypes.includes(notificationData.type);
}

/**
 * Helper function to get appropriate notification channel ID based on type
 */
function _getNotificationChannelId(notificationData) {
  if (!notificationData || !notificationData.type) {
    return 'high_importance_channel';
  }
  
  switch (notificationData.type) {
    case 'offer_received':
    case 'offer_accepted':
    case 'offer_rejected':
      return 'offers';
    case 'trip_update':
    case 'package_update':
      return 'trip_updates';
    case 'message':
      return 'chat_messages';
    case 'voice_call':
      return 'high_importance_channel'; // Voice calls need high priority
    default:
      return 'general';
  }
}

/**
 * Send FCM Notification
 * Reliable server-side FCM notification sending
 */
exports.sendFCMNotification = functions.https.onCall(async (data, context) => {
  try {
    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to send notifications.'
      );
    }

    const { fcmToken, title, body, data: notificationData } = data;

    // Validate input
    if (!fcmToken || !title || !body) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: fcmToken, title, body'
      );
    }

    // ✅ DEBUG: Log notification type and priority decision
    const notificationType = notificationData?.type || 'unknown';
    const useNormalPriority = _shouldUseNormalPriority(notificationData);
    const channelId = _getNotificationChannelId(notificationData);
    
    functions.logger.info('FCM notification details', {
      notificationType,
      useNormalPriority,
      channelId,
      title,
      priority: useNormalPriority ? 'normal' : 'high'
    });

    // Create FCM message with string-only data values
    const message = {
      notification: {
        title: title,
        body: body,
      },
      // Convert all data values to strings (Firebase requirement)
      data: Object.fromEntries(
        Object.entries(notificationData || {}).map(([key, value]) => [
          key,
          String(value)
        ])
      ),
      token: fcmToken,
      android: {
        // ✅ DYNAMIC PRIORITY: Use normal priority for offer notifications to prevent heads-up overlays
        priority: _shouldUseNormalPriority(notificationData) ? 'normal' : 'high',
        notification: {
          sound: 'default',
          // ✅ DYNAMIC PRIORITY: Same for notification priority
          priority: _shouldUseNormalPriority(notificationData) ? 'default' : 'high',
          channelId: _getNotificationChannelId(notificationData),
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    // Send FCM notification using Admin SDK
    const response = await admin.messaging().send(message);

    functions.logger.info('FCM notification sent successfully', {
      messageId: response,
      title,
      userId: context.auth.uid
    });

    return {
      success: true,
      messageId: response
    };

  } catch (error) {
    functions.logger.error('Error sending FCM notification:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send FCM notification'
    );
  }
});
