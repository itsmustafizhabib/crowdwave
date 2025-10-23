const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

/**
 * Email Configuration
 * Using Zoho SMTP settings from Firebase config
 */
const getEmailTransporter = () => {
  const emailConfig = {
    host: 'smtp.zoho.eu',
    port: 465,
    secure: true, // use SSL
    auth: {
      user: process.env.SMTP_USER || functions.config().smtp?.user || 'nauman@crowdwave.eu',
      pass: process.env.SMTP_PASSWORD || functions.config().smtp?.password,
    },
  };

  return nodemailer.createTransport(emailConfig);
};

/**
 * Email Templates
 */
const emailTemplates = {
  verification: (displayName, verificationLink) => ({
    subject: 'Verify your email for CrowdWave',
    html: `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Verify your email</title>
        <style>
          body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background-color: #f5f5f5;
          }
          .email-container {
            max-width: 600px;
            margin: 40px auto;
            background-color: #ffffff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          }
          .email-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 40px 30px;
            text-align: center;
          }
          .email-logo {
            color: #ffffff;
            font-size: 32px;
            font-weight: bold;
            margin: 0;
          }
          .email-body {
            padding: 40px 30px;
          }
          .email-title {
            font-size: 24px;
            font-weight: 600;
            color: #333333;
            margin: 0 0 20px 0;
          }
          .email-text {
            font-size: 16px;
            line-height: 24px;
            color: #666666;
            margin: 0 0 30px 0;
          }
          .email-button {
            display: inline-block;
            padding: 16px 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #ffffff;
            text-decoration: none;
            border-radius: 6px;
            font-weight: 600;
            font-size: 16px;
            margin: 10px 0;
            transition: transform 0.2s;
          }
          .email-button:hover {
            transform: translateY(-2px);
          }
          .email-link {
            word-break: break-all;
            color: #667eea;
            font-size: 14px;
            margin-top: 20px;
            display: block;
          }
          .email-footer {
            background-color: #f9f9f9;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #eeeeee;
          }
          .footer-text {
            font-size: 14px;
            color: #999999;
            margin: 5px 0;
          }
          .warning-box {
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
          }
          .warning-text {
            font-size: 14px;
            color: #856404;
            margin: 0;
          }
        </style>
      </head>
      <body>
        <div class="email-container">
          <div class="email-header">
            <h1 class="email-logo">🌊 CrowdWave</h1>
          </div>
          
          <div class="email-body">
            <h2 class="email-title">Hello ${displayName || 'there'}! 👋</h2>
            
            <p class="email-text">
              Welcome to CrowdWave! We're excited to have you on board. 
              To get started, please verify your email address by clicking the button below:
            </p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="${verificationLink}" class="email-button">
                ✅ Verify Email Address
              </a>
            </div>
            
            <p class="email-text" style="font-size: 14px;">
              Or copy and paste this link into your browser:
            </p>
            <a href="${verificationLink}" class="email-link">${verificationLink}</a>
            
            <div class="warning-box">
              <p class="warning-text">
                ⚠️ <strong>Security Notice:</strong><br>
                • This link expires in 1 hour for your protection<br>
                • If you didn't create a CrowdWave account, please ignore this email<br>
                • Never share this link with anyone
              </p>
            </div>
          </div>
          
          <div class="email-footer">
            <p class="footer-text">
              Questions? Contact us at 
              <a href="mailto:support@crowdwave.eu" style="color: #667eea;">support@crowdwave.eu</a>
            </p>
            <p class="footer-text">
              © ${new Date().getFullYear()} CrowdWave. All rights reserved.
            </p>
            <p class="footer-text" style="font-size: 12px;">
              CrowdWave - Connecting couriers with packages worldwide
            </p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Hello ${displayName || 'there'}!

Welcome to CrowdWave! Please verify your email address by visiting this link:

${verificationLink}

Security Notice:
- This link expires in 1 hour for your protection
- If you didn't create a CrowdWave account, please ignore this email
- Never share this link with anyone

Questions? Email us at support@crowdwave.eu

© ${new Date().getFullYear()} CrowdWave. All rights reserved.
    `.trim(),
  }),

  passwordReset: (displayName, resetLink) => ({
    subject: 'Reset your CrowdWave password',
    html: `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Reset your password</title>
        <style>
          body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background-color: #f5f5f5;
          }
          .email-container {
            max-width: 600px;
            margin: 40px auto;
            background-color: #ffffff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          }
          .email-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 40px 30px;
            text-align: center;
          }
          .email-logo {
            color: #ffffff;
            font-size: 32px;
            font-weight: bold;
            margin: 0;
          }
          .email-body {
            padding: 40px 30px;
          }
          .email-title {
            font-size: 24px;
            font-weight: 600;
            color: #333333;
            margin: 0 0 20px 0;
          }
          .email-text {
            font-size: 16px;
            line-height: 24px;
            color: #666666;
            margin: 0 0 30px 0;
          }
          .email-button {
            display: inline-block;
            padding: 16px 40px;
            background: linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%);
            color: #ffffff;
            text-decoration: none;
            border-radius: 6px;
            font-weight: 600;
            font-size: 16px;
            margin: 10px 0;
            transition: transform 0.2s;
          }
          .email-button:hover {
            transform: translateY(-2px);
          }
          .email-link {
            word-break: break-all;
            color: #667eea;
            font-size: 14px;
            margin-top: 20px;
            display: block;
          }
          .email-footer {
            background-color: #f9f9f9;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #eeeeee;
          }
          .footer-text {
            font-size: 14px;
            color: #999999;
            margin: 5px 0;
          }
          .warning-box {
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
          }
          .warning-text {
            font-size: 14px;
            color: #856404;
            margin: 0;
          }
          .info-box {
            background-color: #e3f2fd;
            border-left: 4px solid #2196F3;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
          }
          .info-text {
            font-size: 14px;
            color: #1565c0;
            margin: 0;
          }
        </style>
      </head>
      <body>
        <div class="email-container">
          <div class="email-header">
            <h1 class="email-logo">🌊 CrowdWave</h1>
          </div>
          
          <div class="email-body">
            <h2 class="email-title">Hi there! 🔐</h2>
            
            <p class="email-text">
              Someone requested a password reset for your CrowdWave account.
            </p>
            
            <p class="email-text">
              If this was you, click the button below to create a new password:
            </p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="${resetLink}" class="email-button">
                🔑 Reset Your Password
              </a>
            </div>
            
            <p class="email-text" style="font-size: 14px;">
              Or copy and paste this link into your browser:
            </p>
            <a href="${resetLink}" class="email-link">${resetLink}</a>
            
            <div class="warning-box">
              <p class="warning-text">
                ⚠️ <strong>Security Notice:</strong><br>
                • This link expires in 1 hour for your protection<br>
                • If you didn't request this reset, please ignore this email<br>
                • Your current password remains unchanged until you create a new one
              </p>
            </div>
            
            <div class="info-box">
              <p class="info-text">
                💡 <strong>For a strong password, include:</strong><br>
                • At least 8 characters<br>
                • Upper and lowercase letters<br>
                • Numbers and symbols
              </p>
            </div>
          </div>
          
          <div class="email-footer">
            <p class="footer-text">
              Questions? Email us at 
              <a href="mailto:security@crowdwave.eu" style="color: #667eea;">security@crowdwave.eu</a>
            </p>
            <p class="footer-text">
              © ${new Date().getFullYear()} CrowdWave. All rights reserved.
            </p>
            <p class="footer-text" style="font-size: 12px;">
              CrowdWave Security Team
            </p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Hi there!

Someone requested a password reset for your CrowdWave account.

If this was you, click the link below to create a new password:

${resetLink}

Security Notice:
- This link expires in 1 hour for your protection
- If you didn't request this reset, please ignore this email
- Your current password remains unchanged until you create a new one

For a strong password, include:
• At least 8 characters
• Upper and lowercase letters
• Numbers and symbols

Questions? Email us at security@crowdwave.eu

© ${new Date().getFullYear()} CrowdWave Security Team
    `.trim(),
  }),

  deliveryUpdate: (packageDetails, status, trackingUrl) => ({
    subject: `📦 Package Update: ${status}`,
    html: `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Delivery Update</title>
        <style>
          body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background-color: #f5f5f5;
          }
          .email-container {
            max-width: 600px;
            margin: 40px auto;
            background-color: #ffffff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          }
          .email-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 40px 30px;
            text-align: center;
          }
          .email-logo {
            color: #ffffff;
            font-size: 32px;
            font-weight: bold;
            margin: 0;
          }
          .email-body {
            padding: 40px 30px;
          }
          .status-badge {
            display: inline-block;
            padding: 8px 20px;
            background-color: #4caf50;
            color: white;
            border-radius: 20px;
            font-weight: 600;
            font-size: 14px;
            margin: 10px 0 20px 0;
          }
          .package-details {
            background-color: #f9f9f9;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
          }
          .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eeeeee;
          }
          .detail-label {
            font-weight: 600;
            color: #666666;
          }
          .detail-value {
            color: #333333;
          }
          .email-button {
            display: inline-block;
            padding: 16px 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #ffffff;
            text-decoration: none;
            border-radius: 6px;
            font-weight: 600;
            font-size: 16px;
            margin: 20px 0;
            transition: transform 0.2s;
          }
          .email-footer {
            background-color: #f9f9f9;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #eeeeee;
          }
          .footer-text {
            font-size: 14px;
            color: #999999;
            margin: 5px 0;
          }
        </style>
      </head>
      <body>
        <div class="email-container">
          <div class="email-header">
            <h1 class="email-logo">🌊 CrowdWave</h1>
          </div>
          
          <div class="email-body">
            <h2>📦 Your Package Has Been Updated!</h2>
            <div class="status-badge">${status}</div>
            
            <div class="package-details">
              ${packageDetails.trackingNumber ? `
                <div class="detail-row">
                  <span class="detail-label">Tracking Number:</span>
                  <span class="detail-value">${packageDetails.trackingNumber}</span>
                </div>
              ` : ''}
              ${packageDetails.from ? `
                <div class="detail-row">
                  <span class="detail-label">From:</span>
                  <span class="detail-value">${packageDetails.from}</span>
                </div>
              ` : ''}
              ${packageDetails.to ? `
                <div class="detail-row">
                  <span class="detail-label">To:</span>
                  <span class="detail-value">${packageDetails.to}</span>
                </div>
              ` : ''}
              ${packageDetails.estimatedDelivery ? `
                <div class="detail-row">
                  <span class="detail-label">Estimated Delivery:</span>
                  <span class="detail-value">${packageDetails.estimatedDelivery}</span>
                </div>
              ` : ''}
            </div>
            
            ${trackingUrl ? `
              <div style="text-align: center;">
                <a href="${trackingUrl}" class="email-button">
                  🔍 Track Your Package
                </a>
              </div>
            ` : ''}
          </div>
          
          <div class="email-footer">
            <p class="footer-text">
              Questions? Contact us at 
              <a href="mailto:support@crowdwave.eu" style="color: #667eea;">support@crowdwave.eu</a>
            </p>
            <p class="footer-text">
              © ${new Date().getFullYear()} CrowdWave. All rights reserved.
            </p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
📦 Your Package Has Been Updated!

Status: ${status}

Package Details:
${packageDetails.trackingNumber ? `Tracking Number: ${packageDetails.trackingNumber}\n` : ''}
${packageDetails.from ? `From: ${packageDetails.from}\n` : ''}
${packageDetails.to ? `To: ${packageDetails.to}\n` : ''}
${packageDetails.estimatedDelivery ? `Estimated Delivery: ${packageDetails.estimatedDelivery}\n` : ''}

${trackingUrl ? `Track your package: ${trackingUrl}\n` : ''}

Questions? Email us at support@crowdwave.eu

© ${new Date().getFullYear()} CrowdWave. All rights reserved.
    `.trim(),
  }),
};

/**
 * Send Email Verification
 * DISABLED: This Firebase Auth trigger was sending duplicate emails.
 * We now use the OTP-based email verification system (sendOTPEmail function).
 * Keeping this commented for reference but disabled to prevent duplicate emails.
 */
// exports.sendEmailVerification = functions.auth.user().onCreate(async (user) => {
//   // Only send verification email for email/password sign-ups
//   const providerData = user.providerData || [];
//   const isEmailPasswordSignup = providerData.some(
//     provider => provider.providerId === 'password'
//   );

//   if (!isEmailPasswordSignup || user.emailVerified) {
//     functions.logger.info('Skipping email verification', {
//       uid: user.uid,
//       emailVerified: user.emailVerified,
//       providers: providerData.map(p => p.providerId),
//     });
//     return null;
//   }

//   try {
//     // Generate email verification link
//     const link = await admin.auth().generateEmailVerificationLink(user.email, {
//       url: 'https://crowdwave.eu/__/auth/action',
//       handleCodeInApp: false,
//     });

//     const transporter = getEmailTransporter();
//     const template = emailTemplates.verification(user.displayName, link);

//     await transporter.sendMail({
//       from: '"CrowdWave Support" <nauman@crowdwave.eu>',
//       to: user.email,
//       replyTo: 'nauman@crowdwave.eu',
//       subject: template.subject,
//       text: template.text,
//       html: template.html,
//     });

//     functions.logger.info('Email verification sent successfully', {
//       uid: user.uid,
//       email: user.email,
//     });

//     return { success: true };
//   } catch (error) {
//     functions.logger.error('Failed to send email verification', {
//       uid: user.uid,
//       email: user.email,
//       error: error.message,
//     });
//     throw error;
//   }
// });

/**
 * Send Password Reset Email
 * Custom function to send password reset emails with better formatting
 */
exports.sendPasswordResetEmail = functions.https.onCall(async (data, context) => {
  const { email } = data;

  if (!email) {
    throw new functions.https.HttpsError('invalid-argument', 'Email is required');
  }

  try {
    // Check if user exists
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
    } catch (error) {
      // Don't reveal if user exists or not for security
      throw new functions.https.HttpsError('not-found', 'If an account exists with this email, a password reset link has been sent.');
    }

    // Generate password reset link
    const link = await admin.auth().generatePasswordResetLink(email, {
      url: 'https://crowdwave.eu/__/auth/action',
      handleCodeInApp: false,
    });

    const transporter = getEmailTransporter();
    const template = emailTemplates.passwordReset(userRecord.displayName, link);

    await transporter.sendMail({
      from: '"CrowdWave Security" <nauman@crowdwave.eu>',
      to: email,
      replyTo: 'security@crowdwave.eu',
      subject: template.subject,
      text: template.text,
      html: template.html,
    });

    functions.logger.info('Password reset email sent successfully', {
      email: email,
    });

    return { 
      success: true,
      message: 'If an account exists with this email, a password reset link has been sent.',
    };
  } catch (error) {
    functions.logger.error('Failed to send password reset email', {
      email: email,
      error: error.message,
    });
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to send password reset email');
  }
});

/**
 * Send Delivery Update Email
 * Called when package status changes
 */
exports.sendDeliveryUpdateEmail = functions.https.onCall(async (data, context) => {
  // Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { recipientEmail, packageDetails, status, trackingUrl } = data;

  if (!recipientEmail || !packageDetails || !status) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  try {
    const transporter = getEmailTransporter();
    const template = emailTemplates.deliveryUpdate(packageDetails, status, trackingUrl);

    await transporter.sendMail({
      from: '"CrowdWave Deliveries" <nauman@crowdwave.eu>',
      to: recipientEmail,
      replyTo: 'support@crowdwave.eu',
      subject: template.subject,
      text: template.text,
      html: template.html,
    });

    functions.logger.info('Delivery update email sent successfully', {
      recipientEmail: recipientEmail,
      status: status,
      trackingNumber: packageDetails.trackingNumber,
    });

    return { success: true };
  } catch (error) {
    functions.logger.error('Failed to send delivery update email', {
      recipientEmail: recipientEmail,
      error: error.message,
    });
    throw new functions.https.HttpsError('internal', 'Failed to send delivery update email');
  }
});

/**
 * Test Email Configuration
 * Utility function to test email setup
 */
exports.testEmailConfig = functions.https.onCall(async (data, context) => {
  // Require authentication for security
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  try {
    const transporter = getEmailTransporter();
    
    // Verify transporter configuration
    await transporter.verify();

    functions.logger.info('Email configuration test successful');

    return {
      success: true,
      message: 'Email configuration is valid',
      config: {
        host: 'smtp.zoho.eu',
        port: 465,
        secure: true,
        user: transporter.options.auth.user,
      },
    };
  } catch (error) {
    functions.logger.error('Email configuration test failed', {
      error: error.message,
    });
    
    throw new functions.https.HttpsError('internal', `Email configuration test failed: ${error.message}`);
  }
});

/**
 * Send OTP Email for Email Verification
 * Sends a 6-digit OTP code to verify email
 */
exports.sendOTPEmail = functions.https.onCall(async (data, context) => {
  // Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { email, otp, type } = data;

  if (!email || !otp) {
    throw new functions.https.HttpsError('invalid-argument', 'Email and OTP are required');
  }

  try {
    const transporter = getEmailTransporter();

    let subject, html, text;

    if (type === 'email_verification') {
      subject = 'Verify your email for CrowdWave';
      html = `
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Verify your email</title>
          <style>
            body {
              margin: 0;
              padding: 0;
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
              background-color: #f5f5f5;
            }
            .email-container {
              max-width: 600px;
              margin: 40px auto;
              background-color: #ffffff;
              border-radius: 8px;
              overflow: hidden;
              box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            }
            .email-header {
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              padding: 40px 30px;
              text-align: center;
            }
            .email-logo {
              color: #ffffff;
              font-size: 36px;
              font-weight: bold;
              margin: 0;
              letter-spacing: 1px;
            }
            .email-tagline {
              color: rgba(255, 255, 255, 0.9);
              font-size: 14px;
              margin-top: 8px;
            }
            .email-body {
              padding: 40px 30px;
            }
            .email-title {
              font-size: 24px;
              font-weight: 600;
              color: #333333;
              margin: 0 0 20px 0;
            }
            .email-text {
              font-size: 16px;
              line-height: 24px;
              color: #666666;
              margin: 0 0 30px 0;
            }
            .otp-container {
              background-color: #f8f9fa;
              border: 2px dashed #667eea;
              border-radius: 8px;
              padding: 30px;
              text-align: center;
              margin: 30px 0;
            }
            .otp-code {
              font-size: 48px;
              font-weight: bold;
              color: #667eea;
              letter-spacing: 8px;
              margin: 0;
              font-family: 'Courier New', monospace;
            }
            .otp-label {
              font-size: 14px;
              color: #999999;
              margin-top: 10px;
            }
            .warning-box {
              background-color: #fff3cd;
              border-left: 4px solid #ffc107;
              padding: 15px;
              margin: 20px 0;
              border-radius: 4px;
            }
            .warning-text {
              font-size: 14px;
              color: #856404;
              margin: 0;
            }
            .email-footer {
              background-color: #f9f9f9;
              padding: 30px;
              text-align: center;
              border-top: 1px solid #eeeeee;
            }
            .footer-text {
              font-size: 14px;
              color: #999999;
              margin: 5px 0;
            }
          </style>
        </head>
        <body>
          <div class="email-container">
            <div class="email-header">
              <img src="https://crowdwave-website-live.vercel.app/assets/images/CrowdWaveLogo.png" alt="CrowdWave Logo" class="email-logo-img">
              <p class="email-tagline">Crowd-Powered Package Delivery</p>
            </div>
            
            <div class="email-body">
              <h2 class="email-title">Verify Your Email Address</h2>
              
              <p class="email-text">
                Welcome to CrowdWave! To complete your registration, please enter this verification code in the app:
              </p>
              
              <div class="otp-container">
                <p class="otp-code">${otp}</p>
                <p class="otp-label">Your 6-digit verification code</p>
              </div>
              
              <p class="email-text" style="text-align: center; font-weight: 600;">
                Enter this code in the app to verify your email address.
              </p>
              
              <div class="warning-box">
                <p class="warning-text">
                  ⚠️ <strong>Security Notice:</strong><br>
                  • This code expires in 10 minutes<br>
                  • If you didn't create a CrowdWave account, please ignore this email<br>
                  • Never share this code with anyone
                </p>
              </div>
            </div>
            
            <div class="email-footer">
              <p class="footer-text">
                Questions? Contact us at 
                <a href="mailto:support@crowdwave.eu" style="color: #667eea;">support@crowdwave.eu</a>
              </p>
              <p class="footer-text">
                © ${new Date().getFullYear()} CrowdWave. All rights reserved.
              </p>
            </div>
          </div>
        </body>
        </html>
      `;

      text = `
Welcome to CrowdWave!

Your email verification code is: ${otp}

Enter this code in the app to verify your email address.

Security Notice:
- This code expires in 10 minutes
- If you didn't create a CrowdWave account, please ignore this email
- Never share this code with anyone

Questions? Email us at support@crowdwave.eu

© ${new Date().getFullYear()} CrowdWave. All rights reserved.
      `.trim();

    } else if (type === 'password_reset') {
      subject = 'Reset your CrowdWave password';
      html = `
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Reset your password</title>
          <style>
            body {
              margin: 0;
              padding: 0;
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
              background-color: #f5f5f5;
            }
            .email-container {
              max-width: 600px;
              margin: 40px auto;
              background-color: #ffffff;
              border-radius: 8px;
              overflow: hidden;
              box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            }
            .email-header {
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              padding: 40px 30px;
              text-align: center;
            }
            .email-logo {
              color: #ffffff;
              font-size: 36px;
              font-weight: bold;
              margin: 0;
              letter-spacing: 1px;
            }
            .email-tagline {
              color: rgba(255, 255, 255, 0.9);
              font-size: 14px;
              margin-top: 8px;
            }
            .email-body {
              padding: 40px 30px;
            }
            .email-title {
              font-size: 24px;
              font-weight: 600;
              color: #333333;
              margin: 0 0 20px 0;
            }
            .email-text {
              font-size: 16px;
              line-height: 24px;
              color: #666666;
              margin: 0 0 30px 0;
            }
            .otp-container {
              background-color: #f8f9fa;
              border: 2px dashed #667eea;
              border-radius: 8px;
              padding: 30px;
              text-align: center;
              margin: 30px 0;
            }
            .otp-code {
              font-size: 48px;
              font-weight: bold;
              color: #667eea;
              letter-spacing: 8px;
              margin: 0;
              font-family: 'Courier New', monospace;
            }
            .otp-label {
              font-size: 14px;
              color: #999999;
              margin-top: 10px;
            }
            .warning-box {
              background-color: #fff3cd;
              border-left: 4px solid #ffc107;
              padding: 15px;
              margin: 20px 0;
              border-radius: 4px;
            }
            .warning-text {
              font-size: 14px;
              color: #856404;
              margin: 0;
            }
            .email-footer {
              background-color: #f9f9f9;
              padding: 30px;
              text-align: center;
              border-top: 1px solid #eeeeee;
            }
            .footer-text {
              font-size: 14px;
              color: #999999;
              margin: 5px 0;
            }
          </style>
        </head>
        <body>
          <div class="email-container">
            <div class="email-header">
              <img src="https://crowdwave-website-live.vercel.app/assets/images/CrowdWaveLogo.png" alt="CrowdWave Logo" class="email-logo-img">
              <p class="email-tagline">Crowd-Powered Package Delivery</p>
            </div>
            
            <div class="email-body">
              <h2 class="email-title">Password Reset Request</h2>
              
              <p class="email-text">
                We received a request to reset your password. Use this code to reset your password:
              </p>
              
              <div class="otp-container">
                <p class="otp-code">${otp}</p>
                <p class="otp-label">Your 6-digit reset code</p>
              </div>
              
              <p class="email-text" style="text-align: center; font-weight: 600;">
                Enter this code in the app to reset your password.
              </p>
              
              <div class="warning-box">
                <p class="warning-text">
                  ⚠️ <strong>Security Notice:</strong><br>
                  • This code expires in 10 minutes<br>
                  • If you didn't request a password reset, please ignore this email<br>
                  • Never share this code with anyone
                </p>
              </div>
            </div>
            
            <div class="email-footer">
              <p class="footer-text">
                Questions? Contact us at 
                <a href="mailto:support@crowdwave.eu" style="color: #667eea;">support@crowdwave.eu</a>
              </p>
              <p class="footer-text">
                © ${new Date().getFullYear()} CrowdWave. All rights reserved.
              </p>
            </div>
          </div>
        </body>
        </html>
      `;

      text = `
Password Reset Request

Your password reset code is: ${otp}

Enter this code in the app to reset your password.

Security Notice:
- This code expires in 10 minutes
- If you didn't request a password reset, please ignore this email
- Never share this code with anyone

Questions? Email us at support@crowdwave.eu

© ${new Date().getFullYear()} CrowdWave. All rights reserved.
      `.trim();
    }

    const mailOptions = {
      from: '"CrowdWave" <nauman@crowdwave.eu>',
      to: email,
      subject: subject,
      text: text,
      html: html,
    };

    await transporter.sendMail(mailOptions);

    functions.logger.info('OTP email sent successfully', {
      email,
      type,
    });

    return { success: true, message: 'OTP email sent successfully' };

  } catch (error) {
    functions.logger.error('Failed to send OTP email', {
      error: error.message,
      email,
      type,
    });
    
    throw new functions.https.HttpsError('internal', `Failed to send OTP email: ${error.message}`);
  }
});

module.exports = {
  // sendEmailVerification: exports.sendEmailVerification, // DISABLED - using OTP system instead
  sendPasswordResetEmail: exports.sendPasswordResetEmail,
  sendDeliveryUpdateEmail: exports.sendDeliveryUpdateEmail,
  testEmailConfig: exports.testEmailConfig,
  sendOTPEmail: exports.sendOTPEmail,
};
