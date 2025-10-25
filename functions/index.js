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

// Import email functions
const emailFunctions = require('./email_functions');
// exports.sendEmailVerification = emailFunctions.sendEmailVerification; // DISABLED - using OTP system
exports.sendPasswordResetEmail = emailFunctions.sendPasswordResetEmail;
exports.sendDeliveryUpdateEmail = emailFunctions.sendDeliveryUpdateEmail;
exports.testEmailConfig = emailFunctions.testEmailConfig;
exports.sendOTPEmail = emailFunctions.sendOTPEmail;

// Import Agora token functions
const agoraFunctions = require('./agora_functions');
exports.generateAgoraToken = agoraFunctions.generateAgoraToken;
exports.renewAgoraToken = agoraFunctions.renewAgoraToken;

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
    // RELAXED: Allow tokens that expired within the last 5 minutes for payment confirmation
    // since the payment already succeeded in Stripe and we just need to record it
    if (context.auth.token) {
      const now = Math.floor(Date.now() / 1000); // Current time in seconds
      const exp = context.auth.token.exp; // Token expiry
      const iat = context.auth.token.iat; // Token issued at
      const graceperiodSeconds = 300; // 5 minutes grace period
      
      functions.logger.info('Token timing check:', {
        serverTime: now,
        tokenExp: exp,
        tokenIat: iat,
        timeToExpiry: exp - now,
        tokenAge: now - iat,
        gracePeriod: graceperiodSeconds
      });
      
      // Only reject if token expired more than 5 minutes ago
      if (exp && (now - exp) > gracePeriodSeconds) {
        functions.logger.error('Token expired beyond grace period', {
          expiryTime: exp,
          currentTime: now,
          expiredBy: now - exp,
          gracePeriod: gracePeriodSeconds
        });
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication token has expired. Please sign in again and retry payment.'
        );
      } else if (exp && exp <= now) {
        functions.logger.warn('Token expired but within grace period - allowing payment confirmation', {
          expiryTime: exp,
          currentTime: now,
          expiredBy: now - exp
        });
      }
      
      // Just log old tokens, don't fail
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
          const packageId = booking.data().packageId; // FIXED: Use packageId instead of packageRequestId
          
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
              currency: bookingData.currency || 'EUR',
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

          // 💰 HOLD PAYMENT IN TRAVELER'S PENDING BALANCE (ESCROW)
          // When payment is made via Stripe, hold the traveler's payout in their pending balance
          try {
            const travelerId = bookingData.travelerId;
            const travelerPayout = bookingData.travelerPayout || bookingData.agreedPrice || 0;

            if (travelerId && travelerPayout > 0) {
              const walletRef = db.collection('wallets').doc(travelerId);
              const walletDoc = await walletRef.get();

              if (walletDoc.exists) {
                // Update traveler's pending balance
                await walletRef.update({
                  pendingBalance: admin.firestore.FieldValue.increment(travelerPayout),
                  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                // Create hold transaction record
                await db.collection('transactions').add({
                  userId: travelerId,
                  type: 'hold',
                  amount: travelerPayout,
                  status: 'pending',
                  bookingId: bookingId,
                  description: `Payment held for booking #${bookingId}`,
                  timestamp: admin.firestore.FieldValue.serverTimestamp(),
                  metadata: {
                    payment_method: 'stripe',
                    payment_intent_id: paymentIntentId,
                  },
                });

                functions.logger.info('Payment held in traveler pending balance', {
                  travelerId,
                  amount: travelerPayout,
                  bookingId,
                  paymentMethod: 'stripe'
                });
              } else {
                functions.logger.warn('Traveler wallet not found, creating wallet', { travelerId });
                
                // Create wallet for traveler if it doesn't exist
                await walletRef.set({
                  userId: travelerId,
                  balance: 0,
                  pendingBalance: travelerPayout,
                  totalEarnings: 0,
                  totalSpent: 0,
                  totalWithdrawals: 0,
                  currency: bookingData.currency || 'EUR',
                  createdAt: admin.firestore.FieldValue.serverTimestamp(),
                  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                // Create hold transaction record
                await db.collection('transactions').add({
                  userId: travelerId,
                  type: 'hold',
                  amount: travelerPayout,
                  status: 'pending',
                  bookingId: bookingId,
                  description: `Payment held for booking #${bookingId}`,
                  timestamp: admin.firestore.FieldValue.serverTimestamp(),
                  metadata: {
                    payment_method: 'stripe',
                    payment_intent_id: paymentIntentId,
                  },
                });

                functions.logger.info('Wallet created and payment held', {
                  travelerId,
                  amount: travelerPayout,
                  bookingId
                });
              }
            }
          } catch (walletError) {
            functions.logger.error('Failed to hold payment in traveler wallet', {
              error: walletError.message,
              bookingId,
              travelerId: bookingData.travelerId
            });
            // Don't throw - payment confirmation succeeded, wallet update is secondary
          }
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
 * Release Payment to Traveler
 * Release payment from escrow to traveler after delivery confirmation
 */
exports.releasePaymentToTraveler = functions.https.onCall(async (data, context) => {
  try {
    functions.logger.info('releasePaymentToTraveler called', { 
      hasAuth: !!context.auth, 
      authUid: context.auth?.uid,
      data 
    });

    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated.'
      );
    }

    const { bookingId, travelerId, amount, reason } = data;

    // Validate input
    if (!bookingId || !travelerId || !amount) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: bookingId, travelerId, amount'
      );
    }

    const db = admin.firestore();

    // Get traveler's wallet
    const walletRef = db.collection('wallets').doc(travelerId);
    const walletDoc = await walletRef.get();

    if (!walletDoc.exists) {
      functions.logger.error('Wallet not found for traveler', { travelerId });
      throw new functions.https.HttpsError(
        'not-found',
        'Traveler wallet not found'
      );
    }

    // Update wallet with transaction
    await db.runTransaction(async (transaction) => {
      const wallet = await transaction.get(walletRef);
      const walletData = wallet.data();

      const currentBalance = (walletData.balance || 0);
      const currentPendingBalance = (walletData.pendingBalance || 0);
      const currentTotalEarnings = (walletData.totalEarnings || 0);

      // Move amount from pending to available balance
      transaction.update(walletRef, {
        balance: currentBalance + amount,
        pendingBalance: Math.max(0, currentPendingBalance - amount),
        totalEarnings: currentTotalEarnings + amount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    // Create transaction record
    const transactionData = {
      userId: travelerId,
      type: 'earning',
      amount: amount,
      status: 'completed',
      bookingId: bookingId,
      description: `Payment received for delivery #${bookingId}`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        payment_method: 'escrow_release',
        reason: reason || 'delivery_confirmed',
        released_by: context.auth.uid,
      },
    };

    await db.collection('transactions').add(transactionData);

    functions.logger.info('Payment released to traveler successfully', {
      travelerId,
      bookingId,
      amount,
      releasedBy: context.auth.uid
    });

    return {
      success: true,
      message: 'Payment released successfully',
      travelerId,
      amount,
    };

  } catch (error) {
    functions.logger.error('Error releasing payment to traveler:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to release payment to traveler'
    );
  }
});

/**
 * Refund Payment to Sender
 * Refund payment from escrow back to sender
 */
exports.refundPaymentToSender = functions.https.onCall(async (data, context) => {
  try {
    functions.logger.info('refundPaymentToSender called', { 
      hasAuth: !!context.auth, 
      authUid: context.auth?.uid,
      data 
    });

    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated.'
      );
    }

    const { bookingId, senderId, amount, reason } = data;

    // Validate input
    if (!bookingId || !senderId || !amount) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: bookingId, senderId, amount'
      );
    }

    const db = admin.firestore();

    // Get sender's wallet
    const walletRef = db.collection('wallets').doc(senderId);
    const walletDoc = await walletRef.get();

    if (!walletDoc.exists) {
      functions.logger.error('Wallet not found for sender', { senderId });
      throw new functions.https.HttpsError(
        'not-found',
        'Sender wallet not found'
      );
    }

    // Update wallet with transaction
    await db.runTransaction(async (transaction) => {
      const wallet = await transaction.get(walletRef);
      const walletData = wallet.data();

      const currentBalance = (walletData.balance || 0);
      const currentTotalSpent = (walletData.totalSpent || 0);

      // Refund amount back to balance
      transaction.update(walletRef, {
        balance: currentBalance + amount,
        totalSpent: Math.max(0, currentTotalSpent - amount),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    // Create transaction record
    const transactionData = {
      userId: senderId,
      type: 'refund',
      amount: amount,
      status: 'completed',
      bookingId: bookingId,
      description: `Refund for booking #${bookingId}: ${reason}`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        payment_method: 'escrow_refund',
        reason: reason,
        refunded_by: context.auth.uid,
      },
    };

    await db.collection('transactions').add(transactionData);

    functions.logger.info('Payment refunded to sender successfully', {
      senderId,
      bookingId,
      amount,
      refundedBy: context.auth.uid
    });

    return {
      success: true,
      message: 'Payment refunded successfully',
      senderId,
      amount,
    };

  } catch (error) {
    functions.logger.error('Error refunding payment to sender:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to refund payment to sender'
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
          const packageId = bookingData.packageId; // FIXED: Use packageId instead of packageRequestId
          
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
                currency: bookingData.currency || 'EUR',
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

    // ✅ PREVENT DUPLICATE NOTIFICATIONS: Check if this notification was already sent
    const notificationId = notificationData?.notificationId || 
      `${notificationData?.type || 'general'}_${notificationData?.relatedEntityId || 'none'}_${context.auth.uid}`;
    
    const duplicateCheck = await admin.firestore()
      .collection('sentNotifications')
      .doc(notificationId)
      .get();
    
    if (duplicateCheck.exists) {
      functions.logger.info('Duplicate notification prevented', { notificationId });
      return { success: true, messageId: 'duplicate_prevented' };
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
          clickAction: 'FLUTTER_NOTIFICATION_CLICK', // Enable deep linking
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

    // ✅ MARK AS SENT to prevent duplicates (expires after 24 hours)
    await admin.firestore()
      .collection('sentNotifications')
      .doc(notificationId)
      .set({
        messageId: response,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        title,
        type: notificationType,
        userId: context.auth.uid,
        // Document will auto-delete after 24 hours
        expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000))
      });

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

/**
 * ✅ FIRESTORE TRIGGER: Notify when deal offer is accepted
 */
exports.notifyDealAccepted = functions.firestore
  .document('dealOffers/{dealId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    
    // Only trigger if status changed to accepted
    if (beforeData.status !== 'accepted' && afterData.status === 'accepted') {
      try {
        const dealId = context.params.dealId;
        
        // Get sender's FCM token to notify them
        const senderDoc = await admin.firestore()
          .collection('users')
          .doc(afterData.senderId)
          .get();
        
        const senderFcmToken = senderDoc.data()?.fcmToken;
        if (!senderFcmToken) {
          functions.logger.info('No FCM token for sender', { senderId: afterData.senderId });
          return null;
        }
        
        // Get package details for context
        const packageDoc = await admin.firestore()
          .collection('packageRequests')
          .doc(afterData.packageId)
          .get();
        
        const packageData = packageDoc.data();
        const packageTitle = packageData ? 
          `Package from ${packageData.fromLocation?.city || 'Unknown'} to ${packageData.toLocation?.city || 'Unknown'}` :
          'Your package delivery';
        
        // Send notification to offer sender
        const message = {
          notification: {
            title: '🎉 Deal Accepted!',
            body: `Your offer of $${afterData.offeredPrice} for ${packageTitle} has been accepted!`,
          },
          data: {
            type: 'deal_accepted',
            dealId: dealId,
            conversationId: afterData.conversationId,
            packageId: afterData.packageId,
            clickAction: 'OPEN_CHAT',
            notificationId: `deal_accepted_${dealId}`,
          },
          token: senderFcmToken,
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              priority: 'high',
              channelId: 'offers',
              clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
        };
        
        const response = await admin.messaging().send(message);
        functions.logger.info('Deal accepted notification sent', { dealId, messageId: response });
        
        return null;
      } catch (error) {
        functions.logger.error('Error sending deal accepted notification:', error);
        return null;
      }
    }
    
    return null;
  });

/**
 * ✅ FIRESTORE TRIGGER: Notify when new message is sent in chat
 */
exports.notifyNewMessage = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const conversationId = context.params.conversationId;
    const messageId = context.params.messageId;
    
    try {
      // Don't send notification for system messages or deal offers (they have their own notifications)
      if (messageData.type === 'system' || messageData.type === 'deal_offer' || messageData.type === 'deal_counter') {
        return null;
      }
      
      // Get conversation details to find recipient
      const conversationDoc = await admin.firestore()
        .collection('conversations')
        .doc(conversationId)
        .get();
      
      if (!conversationDoc.exists) {
        return null;
      }
      
      const conversationData = conversationDoc.data();
      const participants = conversationData.participants || [];
      
      // Find recipient (the user who didn't send the message)
      const recipientId = participants.find(id => id !== messageData.senderId);
      if (!recipientId) {
        return null;
      }
      
      // Get recipient's FCM token
      const recipientDoc = await admin.firestore()
        .collection('users')
        .doc(recipientId)
        .get();
      
      const recipientFcmToken = recipientDoc.data()?.fcmToken;
      if (!recipientFcmToken) {
        functions.logger.info('No FCM token for recipient', { recipientId });
        return null;
      }
      
      // Get sender's name
      const senderName = conversationData.participantNames?.[messageData.senderId] || 'Someone';
      
      // Send notification
      const message = {
        notification: {
          title: senderName,
          body: messageData.content,
        },
        data: {
          type: 'chat_message',
          conversationId: conversationId,
          senderId: messageData.senderId,
          senderName: senderName,
          messageId: messageId,
          clickAction: 'OPEN_CHAT',
          notificationId: `message_${messageId}`,
        },
        token: recipientFcmToken,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            priority: 'high',
            channelId: 'chat_messages',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      };
      
      const response = await admin.messaging().send(message);
      functions.logger.info('New message notification sent', { conversationId, messageId, response });
      
      return null;
    } catch (error) {
      functions.logger.error('Error sending new message notification:', error);
      return null;
    }
  });

/**
 * ✅ FIRESTORE TRIGGER: Send email when delivery tracking status changes
 * Automatically notifies sender via email when package status updates
 */
exports.notifyTrackingStatusChange = functions.firestore
  .document('deliveryTracking/{trackingId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const trackingId = context.params.trackingId;
    
    // Only trigger if status actually changed
    if (beforeData.status === afterData.status) {
      return null;
    }
    
    try {
      const newStatus = afterData.status;
      const senderId = afterData.senderId;
      
      if (!senderId) {
        functions.logger.info('No sender ID found in tracking', { trackingId });
        return null;
      }
      
      // Get sender's email
      const senderDoc = await admin.firestore()
        .collection('users')
        .doc(senderId)
        .get();
      
      if (!senderDoc.exists) {
        functions.logger.info('Sender user not found', { senderId });
        return null;
      }
      
      const senderEmail = senderDoc.data()?.email;
      if (!senderEmail) {
        functions.logger.info('Sender email not found', { senderId });
        return null;
      }
      
      // Get package details
      const packageId = afterData.packageRequestId;
      const packageDoc = await admin.firestore()
        .collection('packageRequests')
        .doc(packageId)
        .get();
      
      if (!packageDoc.exists) {
        functions.logger.info('Package not found', { packageId });
        return null;
      }
      
      const packageData = packageDoc.data();
      
      // Prepare package details for email
      const packageDetails = {
        packageId: packageId,
        trackingNumber: trackingId,
        from: packageData.fromLocation?.city || 'Unknown',
        to: packageData.toLocation?.city || 'Unknown',
        description: packageData.description || 'Package',
        weight: packageData.weight?.toString() || 'N/A',
      };
      
      // Create tracking URL
      const trackingUrl = `https://crowdwave.eu/track/${trackingId}`;
      
      // Only send emails for significant status changes
      const emailStatuses = ['picked_up', 'in_transit', 'delivered', 'cancelled'];
      if (!emailStatuses.includes(newStatus)) {
        functions.logger.info('Status not significant for email', { status: newStatus });
        return null;
      }
      
      // Import nodemailer for direct email sending
      const nodemailer = require('nodemailer');
      
      // Get email transporter
      const transporter = nodemailer.createTransport({
        host: 'smtp.zoho.eu',
        port: 465,
        secure: true,
        auth: {
          user: process.env.SMTP_USER || functions.config().smtp?.user || 'nauman@crowdwave.eu',
          pass: process.env.SMTP_PASSWORD || functions.config().smtp?.password,
        },
      });
      
      // Prepare email content based on status
      let subject, title, message;
      switch (newStatus) {
        case 'picked_up':
          subject = '📦 Package Picked Up - CrowdWave';
          title = 'Package Picked Up!';
          message = 'Your package has been picked up and is on its way!';
          break;
        case 'in_transit':
          subject = '🚚 Package In Transit - CrowdWave';
          title = 'Package In Transit';
          message = 'Your package is currently in transit to its destination.';
          break;
        case 'delivered':
          subject = '✅ Package Delivered - CrowdWave';
          title = 'Package Delivered!';
          message = 'Your package has been successfully delivered! Please confirm receipt in the app.';
          break;
        case 'cancelled':
          subject = '❌ Delivery Cancelled - CrowdWave';
          title = 'Delivery Cancelled';
          message = 'The delivery has been cancelled.';
          break;
        default:
          return null;
      }
      
      // Send email
      const mailOptions = {
        from: '"CrowdWave Deliveries" <nauman@crowdwave.eu>',
        to: senderEmail,
        subject: subject,
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              body { margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f5f5f5; }
              .container { max-width: 600px; margin: 40px auto; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
              .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 30px; text-align: center; color: white; }
              .header h1 { margin: 0; font-size: 32px; }
              .content { padding: 40px 30px; }
              .status-badge { display: inline-block; padding: 12px 24px; background: #667eea; color: white; border-radius: 20px; font-weight: bold; margin: 20px 0; }
              .details { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
              .detail-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #e0e0e0; }
              .detail-label { font-weight: 600; color: #666; }
              .detail-value { color: #333; }
              .button { display: inline-block; padding: 16px 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; border-radius: 6px; font-weight: 600; margin: 20px 0; }
              .footer { background: #f9f9f9; padding: 30px; text-align: center; border-top: 1px solid #eee; color: #999; font-size: 14px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🌊 CrowdWave</h1>
              </div>
              <div class="content">
                <h2>${title}</h2>
                <p>${message}</p>
                <div class="status-badge">${newStatus.replace('_', ' ').toUpperCase()}</div>
                <div class="details">
                  <div class="detail-row">
                    <span class="detail-label">Tracking Number:</span>
                    <span class="detail-value">${trackingId}</span>
                  </div>
                  <div class="detail-row">
                    <span class="detail-label">From:</span>
                    <span class="detail-value">${packageDetails.from}</span>
                  </div>
                  <div class="detail-row">
                    <span class="detail-label">To:</span>
                    <span class="detail-value">${packageDetails.to}</span>
                  </div>
                  <div class="detail-row">
                    <span class="detail-label">Description:</span>
                    <span class="detail-value">${packageDetails.description}</span>
                  </div>
                </div>
                <div style="text-align: center;">
                  <a href="${trackingUrl}" class="button">Track Your Package</a>
                </div>
              </div>
              <div class="footer">
                <p>Questions? Contact us at <a href="mailto:support@crowdwave.eu">support@crowdwave.eu</a></p>
                <p>© ${new Date().getFullYear()} CrowdWave. All rights reserved.</p>
              </div>
            </div>
          </body>
          </html>
        `,
        text: `
${title}

${message}

Tracking Number: ${trackingId}
From: ${packageDetails.from}
To: ${packageDetails.to}
Description: ${packageDetails.description}

Track your package: ${trackingUrl}

Questions? Email us at support@crowdwave.eu
© ${new Date().getFullYear()} CrowdWave. All rights reserved.
        `.trim(),
      };
      
      await transporter.sendMail(mailOptions);
      
      functions.logger.info('Tracking status email sent', {
        trackingId,
        status: newStatus,
        email: senderEmail,
      });
      
      return null;
    } catch (error) {
      functions.logger.error('Error sending tracking status email:', error);
      return null;
    }
  });
