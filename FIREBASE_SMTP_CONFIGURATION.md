# 🔧 Firebase Console & SMTP Configuration Guide

## Overview
This guide explains how to configure Firebase Console and SMTP settings for the OTP-based email verification system.

---

## 📧 SMTP Configuration (Already Done!)

### ✅ Your Current Setup
You already have SMTP configured with **Zoho SMTP**:

**Location:** `functions/.env`
```env
SMTP_HOST=smtp.zoho.eu
SMTP_PORT=465
SMTP_SECURE=true
SMTP_USER=nauman@crowdwave.eu
SMTP_PASSWORD=[your-password]
```

**Used in:** `functions/email_functions.js`
```javascript
const emailConfig = {
  host: 'smtp.zoho.eu',
  port: 465,
  secure: true,
  auth: {
    user: process.env.SMTP_USER || functions.config().smtp?.user,
    pass: process.env.SMTP_PASSWORD || functions.config().smtp?.password,
  },
};
```

### ✅ SMTP is Working
- Your app already sends emails via Zoho SMTP
- No additional SMTP configuration needed
- Emails are sent from: `nauman@crowdwave.eu`

---

## 🔥 Firebase Console Configuration

### 1. Authentication Settings

#### Enable Email/Password Auth
1. Go to **Firebase Console** → Your Project
2. Navigate to **Authentication** → **Sign-in method**
3. Ensure **Email/Password** is **Enabled**
4. ✅ You should already have this enabled

#### Email Template Settings (Optional)
Firebase has default email templates, but since we're using custom SMTP with OTP codes, Firebase's templates are **NOT used** for:
- ✅ Email Verification (We use OTP codes now)
- ✅ Password Reset (We use OTP codes now)

**Note:** You can still customize Firebase's templates in Console → Authentication → Templates, but they won't be used for OTP flows.

---

### 2. Cloud Functions Configuration

#### Set SMTP Environment Variables
You have two options:

**Option A: Using `.env` file (Current Setup)**
Already configured in `functions/.env`:
```env
SMTP_HOST=smtp.zoho.eu
SMTP_PORT=465
SMTP_SECURE=true
SMTP_USER=nauman@crowdwave.eu
SMTP_PASSWORD=[your-password]
```

**Option B: Using Firebase Config (Alternative)**
```bash
firebase functions:config:set \
  smtp.host="smtp.zoho.eu" \
  smtp.port="465" \
  smtp.user="nauman@crowdwave.eu" \
  smtp.password="your-password"
```

**Recommendation:** Keep using your current `.env` setup ✅

---

### 3. Deploy Cloud Functions

#### Deploy New OTP Email Function
```bash
cd functions
npm install  # Ensure dependencies are installed

# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:sendOTPEmail
```

#### Verify Deployment
1. Go to **Firebase Console** → **Functions**
2. Check that `sendOTPEmail` function is listed
3. Status should show as "Healthy" with green checkmark

---

### 4. Firestore Rules (Already Configured!)

Your Firestore rules for OTP collection are already set:

```javascript
match /otp_codes/{email} {
  allow create: if true;  // Anyone can create (for password reset)
  allow read: if request.auth != null;
  allow update: if request.auth != null;
  allow delete: if request.auth != null;
}
```

**Location:** `firestore.rules`

**Deploy Rules:**
```bash
firebase deploy --only firestore:rules
```

---

## 🎨 Email Template Customization

### Current OTP Email Templates

#### Email Verification Template
- **Subject:** "Verify your email for CrowdWave"
- **Design:** Purple gradient header, large OTP code
- **Features:**
  - 6-digit code in large font
  - Expiration warning (10 minutes)
  - Security notice
  - Responsive design

#### Password Reset Template
- **Subject:** "Reset your CrowdWave password"
- **Design:** Same purple gradient theme
- **Features:**
  - 6-digit reset code
  - 10-minute expiration
  - Security warnings
  - Clear instructions

### Customize Templates
Edit templates in: `functions/email_functions.js`

**Example Customization:**
```javascript
// Change colors
background: linear-gradient(135deg, #YOUR_COLOR1 0%, #YOUR_COLOR2 100%);

// Change logo
<h1 class="email-logo">🌊 YOUR LOGO</h1>

// Change support email
<a href="mailto:your-email@domain.com">your-email@domain.com</a>

// Change company name
© ${new Date().getFullYear()} Your Company Name
```

---

## 🔐 Security Best Practices

### Environment Variables
✅ **DO:**
- Store SMTP credentials in `.env` file
- Add `.env` to `.gitignore`
- Never commit credentials to Git

❌ **DON'T:**
- Hardcode passwords in code
- Share SMTP credentials publicly
- Use weak SMTP passwords

### OTP Security
✅ **Implemented:**
- 6-digit codes only
- 10-minute expiration
- One-time use only
- Rate limiting (60-second cooldown)
- Secure storage in Firestore

---

## 🧪 Testing

### Test OTP Email Sending

#### 1. Test via App
1. Create a new account in the app
2. Check email for 6-digit code
3. Enter code in app
4. Verify success message

#### 2. Test Cloud Function Directly
```bash
# In Firebase Console
Go to Functions → sendOTPEmail → Testing tab

# Test payload:
{
  "email": "your-test-email@gmail.com",
  "otp": "123456",
  "type": "email_verification"
}
```

#### 3. Check SMTP Logs
```bash
# View Cloud Function logs
firebase functions:log --only sendOTPEmail

# Look for:
✅ "OTP email sent successfully"
❌ "Failed to send OTP email"
```

### Test Email Delivery

**Check These:**
- ✅ Email arrives within 30 seconds
- ✅ OTP code is visible and correct
- ✅ Formatting looks good on mobile/desktop
- ✅ Links work (support email)
- ✅ No spam folder delivery

**If Email Not Received:**
1. Check spam folder
2. Verify SMTP credentials
3. Check Firebase Function logs
4. Verify email address is correct
5. Check Zoho SMTP quota/limits

---

## 📊 Firebase Console Monitoring

### Where to Check Things

#### 1. Authentication
**Path:** Firebase Console → Authentication → Users
- View registered users
- Check email verification status
- See sign-in methods

#### 2. Firestore
**Path:** Firebase Console → Firestore Database
- Check `otp_codes` collection
- Verify OTP structure
- Monitor OTP expiration
- Check usage (used: true/false)

#### 3. Functions
**Path:** Firebase Console → Functions
- Check function status
- View execution logs
- Monitor errors
- Check invocation count

#### 4. Logs
**Path:** Firebase Console → Functions → Logs
```
✅ Look for: "OTP email sent successfully"
❌ Look for: "Failed to send OTP email"
ℹ️  Look for: Function execution details
```

---

## 🚀 Deployment Checklist

### Pre-Deployment
- [ ] `.env` file configured with SMTP credentials
- [ ] `functions/.env` added to `.gitignore`
- [ ] Firebase project selected (`firebase use [project-id]`)
- [ ] Node modules installed (`cd functions && npm install`)

### Deploy Steps
```bash
# 1. Deploy Firestore rules
firebase deploy --only firestore:rules

# 2. Deploy Cloud Functions
firebase deploy --only functions

# 3. Verify deployment
firebase functions:list
```

### Post-Deployment
- [ ] Check Firebase Console → Functions
- [ ] Verify `sendOTPEmail` is deployed
- [ ] Test OTP email sending
- [ ] Monitor logs for errors
- [ ] Test complete sign-up flow
- [ ] Test password reset flow

---

## 🐛 Troubleshooting

### Issue: Emails Not Sending

**Possible Causes:**
1. SMTP credentials incorrect
2. Zoho account locked/suspended
3. SMTP port blocked
4. Firebase Function failed

**Solutions:**
```bash
# Check Cloud Function logs
firebase functions:log --only sendOTPEmail

# Test SMTP credentials
# In functions/.env, verify:
SMTP_USER=nauman@crowdwave.eu
SMTP_PASSWORD=[correct-password]

# Redeploy function
firebase deploy --only functions:sendOTPEmail
```

### Issue: OTP Not Valid

**Possible Causes:**
1. OTP expired (> 10 minutes)
2. OTP already used
3. Wrong code entered
4. Code not in Firestore

**Check:**
```
Firebase Console → Firestore → otp_codes → [email]

Verify:
- otp: "123456"
- used: false
- expiresAt: [future timestamp]
```

### Issue: Function Deployment Failed

**Solutions:**
```bash
# Check Node.js version (need v16+ or v18+)
node --version

# Reinstall dependencies
cd functions
rm -rf node_modules package-lock.json
npm install

# Deploy with verbose logging
firebase deploy --only functions --debug
```

---

## 📚 Additional Resources

### Firebase Documentation
- [Cloud Functions](https://firebase.google.com/docs/functions)
- [Authentication](https://firebase.google.com/docs/auth)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

### Email Resources
- [Nodemailer Docs](https://nodemailer.com/)
- [Zoho SMTP Settings](https://www.zoho.com/mail/help/zoho-smtp.html)
- [Email Testing](https://mailtrap.io/)

### Your Current Setup
- SMTP Provider: **Zoho** ✅
- Email From: **nauman@crowdwave.eu** ✅
- Port: **465 (SSL)** ✅
- Template Engine: **Custom HTML** ✅

---

## ✅ Summary

### What's Already Configured
- ✅ SMTP with Zoho
- ✅ Environment variables
- ✅ Email templates
- ✅ Firestore rules
- ✅ OTP service
- ✅ Email verification screen

### What You Need to Do
1. **Deploy Cloud Functions:**
   ```bash
   firebase deploy --only functions
   ```

2. **Deploy Firestore Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **Test:**
   - Create new account
   - Receive OTP email
   - Verify code works
   - Check password reset

4. **Monitor:**
   - Check Firebase Console logs
   - Verify email delivery
   - Monitor error rates

---

**Status:** ✅ Ready to Deploy  
**Last Updated:** October 22, 2025  
**Configuration:** Zoho SMTP + Custom OTP Templates
