// Simple Node.js backend for Stripe payments
// Deploy this to Vercel, Netlify, or Heroku

const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY); // Use environment variable
const cors = require('cors');

const app = express();

// Middleware
app.use(express.json());
app.use(cors());

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ status: 'CrowdWave Stripe Backend Running' });
});

// Create payment intent
app.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency, bookingId, metadata } = req.body;

    // Validate input
    if (!amount || !currency || !bookingId) {
      return res.status(400).json({ 
        error: 'Missing required fields: amount, currency, bookingId' 
      });
    }

    // Create payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency: currency.toLowerCase(),
      metadata: {
        bookingId,
        ...metadata
      },
      automatic_payment_methods: {
        enabled: true,
      },
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id
    });

  } catch (error) {
    console.error('Error creating payment intent:', error);
    res.status(500).json({ error: error.message });
  }
});

// Confirm payment (called after successful payment)
app.post('/confirm-payment', async (req, res) => {
  try {
    const { paymentIntentId, bookingId } = req.body;

    // Retrieve payment intent to verify it's successful
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (paymentIntent.status === 'succeeded') {
      // Update database - booking is now paid
      try {
        await updateBookingPaymentStatus(bookingId, {
          status: 'paid',
          paymentIntentId: paymentIntentId,
          paymentConfirmedAt: new Date().toISOString(),
          paymentAmount: paymentIntent.amount / 100, // Convert from cents
          paymentCurrency: paymentIntent.currency
        });
        
        console.log(`Payment confirmed for booking: ${bookingId}`);
        
        // Send confirmation notification (implement as needed)
        await sendPaymentConfirmationNotification(bookingId, paymentIntent);
        
        res.json({ 
          success: true, 
          status: 'payment_confirmed',
          bookingId 
        });
      } catch (dbError) {
        console.error('Database update failed:', dbError);
        res.status(500).json({ 
          success: false, 
          error: 'Payment succeeded but database update failed' 
        });
      }
    } else {
      res.status(400).json({ 
        error: 'Payment not successful', 
        status: paymentIntent.status 
      });
    }

  } catch (error) {
    console.error('Error confirming payment:', error);
    res.status(500).json({ error: error.message });
  }
});

// Handle refunds
app.post('/refund-payment', async (req, res) => {
  try {
    const { paymentIntentId, amount, reason } = req.body;

    const refund = await stripe.refunds.create({
      payment_intent: paymentIntentId,
      amount: amount ? Math.round(amount * 100) : undefined, // Partial or full refund
      reason: reason || 'requested_by_customer'
    });

    res.json({
      success: true,
      refundId: refund.id,
      status: refund.status
    });

  } catch (error) {
    console.error('Error processing refund:', error);
    res.status(500).json({ error: error.message });
  }
});

// Stripe webhook handler
app.post('/webhook/stripe', express.raw({type: 'application/json'}), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || 'whsec_YOUR_WEBHOOK_SECRET';

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      console.log('Payment succeeded:', paymentIntent.id);
      
      // Update database for successful payment
      try {
        const bookingId = paymentIntent.metadata?.bookingId;
        if (bookingId) {
          await updateBookingPaymentStatus(bookingId, {
            status: 'paid',
            paymentIntentId: paymentIntent.id,
            paymentConfirmedAt: new Date().toISOString(),
            paymentAmount: paymentIntent.amount / 100,
            paymentCurrency: paymentIntent.currency
          });
          
          await sendPaymentConfirmationNotification(bookingId, paymentIntent);
        }
      } catch (error) {
        console.error('Webhook database update failed:', error);
      }
      break;
    
    case 'payment_intent.payment_failed':
      const failedPayment = event.data.object;
      console.log('Payment failed:', failedPayment.id);
      
      // Handle failed payment
      try {
        const bookingId = failedPayment.metadata?.bookingId;
        if (bookingId) {
          await updateBookingPaymentStatus(bookingId, {
            status: 'payment_failed',
            paymentIntentId: failedPayment.id,
            paymentFailedAt: new Date().toISOString(),
            failureReason: failedPayment.last_payment_error?.message || 'Payment failed'
          });
          
          // Notify user of payment failure and provide retry options
          await sendPaymentFailureNotification(bookingId, failedPayment);
        }
      } catch (error) {
        console.error('Failed payment handling error:', error);
      }
      break;

    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.json({received: true});
});

// Helper functions for database operations
async function updateBookingPaymentStatus(bookingId, paymentData) {
  // TODO: Implement your database update logic here
  // This could be Firebase Firestore, MongoDB, PostgreSQL, etc.
  console.log(`Updating booking ${bookingId} with payment data:`, paymentData);
  
  // Example for Firestore (uncomment and adapt as needed):
  // const admin = require('firebase-admin');
  // const db = admin.firestore();
  // await db.collection('bookings').doc(bookingId).update(paymentData);
}

async function sendPaymentConfirmationNotification(bookingId, paymentIntent) {
  // TODO: Implement notification sending (email, push notification, etc.)
  console.log(`Sending payment confirmation for booking ${bookingId}`);
  
  // Example implementation:
  // - Send email confirmation
  // - Send push notification
  // - Update user notifications in database
}

async function sendPaymentFailureNotification(bookingId, failedPayment) {
  // TODO: Implement failure notification sending
  console.log(`Sending payment failure notification for booking ${bookingId}`);
  
  // Example implementation:
  // - Send email with retry instructions
  // - Send push notification with failure reason
  // - Update booking status to allow retry
}

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`CrowdWave Stripe backend running on port ${PORT}`);
});

module.exports = app;
