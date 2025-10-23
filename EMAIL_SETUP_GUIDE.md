# Email Setup and Deployment Guide

## Overview
This guide helps you set up custom email templates for CrowdWave using Cloud Functions and Zoho SMTP.

## Why Custom Email Templates?

### Problems with Default Firebase Emails:
1. ❌ **Non-clickable links** - Default templates sometimes render poorly in email clients
2. ❌ **Spam folder** - Firebase's default emails often go to spam
3. ❌ **Poor branding** - Generic Firebase appearance
4. ❌ **Limited customization** - Can't control email design fully

### Benefits of Custom Cloud Function Emails:
1. ✅ **Professional design** - Beautiful HTML emails with your branding
2. ✅ **Better deliverability** - Using Zoho's trusted SMTP servers
3. ✅ **Clickable buttons** - Properly formatted HTML emails
4. ✅ **Custom content** - Full control over email templates
5. ✅ **Delivery tracking** - Can track email status

## Setup Steps

### 1. Configure Zoho SMTP Password

Edit `functions/.env` file and add your Zoho password:

```bash
SMTP_USER=nauman@crowdwave.eu
SMTP_PASSWORD=your_actual_zoho_password_here
```

**Important:** 
- Use an **App Password** from Zoho, not your regular password
- Generate App Password: Zoho Account → Security → App Passwords

### 2. Install Dependencies

Navigate to functions folder and install nodemailer:

```bash
cd functions
npm install
```

This will install:
- `nodemailer` - For sending emails via SMTP
- All existing dependencies

### 3. Deploy Cloud Functions

Deploy the new email functions to Firebase:

```bash
# Deploy all functions
npm run deploy

# Or deploy only email functions (faster)
firebase deploy --only functions:sendEmailVerification,functions:sendPasswordResetEmail,functions:sendDeliveryUpdateEmail,functions:testEmailConfig
```

### 4. Configure Firebase Email Action Handler

1. Go to Firebase Console → Authentication → Templates
2. Click on "Email address verification"
3. Update the action URL to: `https://crowdwave.eu/__/auth/action`
4. Do the same for "Password reset"

### 5. Configure SPF and DKIM Records (Important!)

To prevent emails from going to spam, add these DNS records to your domain:

#### SPF Record
Add this TXT record to `crowdwave.eu`:
```
v=spf1 include:zoho.eu ~all
```

#### DKIM Record
Get your DKIM key from Zoho:
1. Go to Zoho Mail Admin Console
2. Email Configuration → DKIM Keys
3. Add the DKIM TXT record to your DNS

#### DMARC Record (Optional but recommended)
```
v=DMARC1; p=quarantine; rua=mailto:postmaster@crowdwave.eu
```

### 6. Test the Setup

1. Open the app
2. Go to Debug menu → Email Testing
3. Toggle "Use Cloud Function (Custom SMTP)" ON
4. Enter your email address
5. Click "Test Config" to verify SMTP connection
6. Click "Password Reset" to test password reset email
7. Click "Delivery Update" to test package notification email

## Email Templates

### 1. Email Verification (Auto-sent on signup)
- **Trigger:** When user signs up with email/password
- **Template:** Beautiful gradient header with CrowdWave branding
- **Features:** 
  - Clickable verification button
  - Fallback link
  - Security notice
  - 1-hour expiration warning

### 2. Password Reset
- **Trigger:** Manual via Cloud Function call
- **Template:** Security-focused design
- **Features:**
  - Red-themed reset button
  - Password strength tips
  - Security warnings
  - Contact information

### 3. Delivery Updates
- **Trigger:** When package status changes
- **Template:** Package tracking themed
- **Features:**
  - Status badge
  - Package details card
  - Tracking button
  - Professional layout

## Usage in App

### Password Reset (Updated Method)

Instead of using Firebase Auth directly, use the Cloud Function:

```dart
import 'package:your_app/services/custom_email_service.dart';

final customEmailService = CustomEmailService();

// Send password reset email
try {
  await customEmailService.sendPasswordResetEmail('user@example.com');
  // Show success message
} catch (e) {
  // Handle error
}
```

### Delivery Updates

```dart
// Send delivery update notification
await customEmailService.sendDeliveryUpdateEmail(
  recipientEmail: 'customer@example.com',
  packageDetails: {
    'trackingNumber': 'CW-12345',
    'from': 'Berlin',
    'to': 'Paris',
    'estimatedDelivery': '2025-10-25',
  },
  status: 'In Transit',
  trackingUrl: 'https://crowdwave.eu/track/CW-12345',
);
```

## Email Verification Flow

### Automatic (On Signup)
1. User signs up with email/password
2. Cloud Function automatically triggers
3. Beautiful verification email sent via Zoho
4. User clicks button → Email verified ✅

### Manual (For Testing)
1. Use the Email Test Screen
2. Click "Verification" button
3. Email sent to logged-in user

## Troubleshooting

### Emails Still Going to Spam
1. ✅ Check SPF record is configured
2. ✅ Check DKIM is configured
3. ✅ Warm up your sending domain (send small batches first)
4. ✅ Ask users to whitelist nauman@crowdwave.eu

### Links Not Clickable
1. ✅ Ensure HTML email is being sent (not just plain text)
2. ✅ Test in different email clients
3. ✅ Check email client doesn't block HTML

### Function Deployment Errors
1. ✅ Check Node.js version (should be 20)
2. ✅ Verify .env file has correct credentials
3. ✅ Run `npm install` in functions folder
4. ✅ Check Firebase project permissions

### SMTP Authentication Failed
1. ✅ Use App Password from Zoho, not regular password
2. ✅ Check username is exactly: nauman@crowdwave.eu
3. ✅ Verify .env file is in functions folder
4. ✅ Redeploy functions after updating .env

## Security Notes

### Environment Variables
- Never commit `.env` file to git
- Use Firebase Functions config for production
- Rotate App Passwords regularly

### Email Rate Limits
- Zoho free tier: 250 emails/day
- Zoho paid: Higher limits
- Implement rate limiting in functions if needed

## Monitoring

### Check Function Logs
```bash
firebase functions:log --only sendPasswordResetEmail
```

### Test Email Delivery
1. Check Zoho Mail sent folder
2. Use Email Test Screen in app
3. Monitor Firebase Functions logs

## Production Checklist

- [ ] App Password configured in .env
- [ ] Functions deployed successfully
- [ ] SPF record added to DNS
- [ ] DKIM record added to DNS
- [ ] Email templates tested
- [ ] Links are clickable
- [ ] Emails not going to spam
- [ ] Error handling tested
- [ ] Rate limiting considered

## Support

If you encounter issues:
1. Check Firebase Functions logs
2. Test SMTP config with "Test Config" button
3. Verify DNS records with online tools
4. Contact Zoho support for SMTP issues

## Future Enhancements

- [ ] Add email templates for other notifications
- [ ] Implement email analytics
- [ ] Add multi-language support
- [ ] Create admin dashboard for email monitoring
- [ ] Add email queue system for high volume
