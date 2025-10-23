# 🧪 Testing Guide: Email Tracking Notifications

## Quick Test Checklist

### ✅ Pre-Deployment Tests

1. **Check Code Compilation**
   ```bash
   flutter analyze lib/services/tracking_service.dart
   ```
   - Should show no errors ✅

2. **Verify Function Syntax**
   ```bash
   cd functions
   npm run lint
   ```
   - Should pass without errors ✅

---

### 🚀 Deployment

1. **Deploy the Cloud Function**
   
   **Windows:**
   ```bash
   deploy_tracking_emails.bat
   ```
   
   **macOS/Linux:**
   ```bash
   bash deploy_tracking_emails.sh
   ```

2. **Verify Deployment**
   ```bash
   firebase functions:list | grep notifyTrackingStatusChange
   ```
   - Should show function as deployed ✅

---

### 📧 Email Notification Tests

#### **Test 1: Status Update via App**

1. **Setup:**
   - Create a test package request
   - Accept it as a traveler
   - Note the tracking ID
   - Ensure sender has valid email in Firestore

2. **Test Picked Up Status:**
   ```
   Actions:
   1. Traveler marks package as "picked up"
   2. Check sender's email inbox
   
   Expected:
   ✅ Email received: "📦 Package Picked Up - CrowdWave"
   ✅ Contains tracking number
   ✅ Contains package details (from, to, description)
   ✅ Has "Track Your Package" button
   ```

3. **Test In Transit Status:**
   ```
   Actions:
   1. Update status to "in transit"
   2. Check sender's email
   
   Expected:
   ✅ Email received: "🚚 Package In Transit - CrowdWave"
   ```

4. **Test Delivered Status:**
   ```
   Actions:
   1. Mark package as delivered
   2. Check sender's email
   
   Expected:
   ✅ Email received: "✅ Package Delivered - CrowdWave"
   ✅ Message mentions confirming delivery
   ```

#### **Test 2: Direct Firestore Update (Backup Trigger)**

1. **Go to Firebase Console** → Firestore Database

2. **Find a tracking document:**
   - Collection: `deliveryTracking`
   - Pick any document with valid `senderId`

3. **Manually change status:**
   ```
   Field: status
   Change from: "pending" 
   Change to: "picked_up"
   ```

4. **Check Results:**
   - ✅ Check Firebase Functions logs
   - ✅ Check sender's email
   - ✅ Verify email arrived

5. **View Logs:**
   ```bash
   firebase functions:log --only notifyTrackingStatusChange --limit 10
   ```

---

### 🔍 Debugging Tests

#### **Test 3: Check Email Sending**

1. **Monitor logs in real-time:**
   ```bash
   firebase functions:log --only notifyTrackingStatusChange
   ```

2. **Look for these messages:**
   ```
   ✅ "Tracking status email sent" - Success
   ❌ "Error sending tracking status email" - Failure
   ⚠️ "Sender email not found" - Missing email
   ⚠️ "Status not significant" - Status doesn't trigger email
   ```

#### **Test 4: Verify Sender Email Exists**

1. **Check Firestore:**
   ```
   Collection: users
   Document: {senderId}
   Field: email
   ```

2. **Ensure email field exists and is valid**

---

### 📊 Expected Behavior

#### **When Status Changes:**

| Status | Email Sent? | Subject |
|--------|-------------|---------|
| pending | ❌ No | - |
| picked_up | ✅ Yes | 📦 Package Picked Up |
| in_transit | ✅ Yes | 🚚 Package In Transit |
| delivered | ✅ Yes | ✅ Package Delivered |
| cancelled | ✅ Yes | ❌ Delivery Cancelled |

#### **Email Should Contain:**

✅ Professional CrowdWave branding  
✅ Clear status message  
✅ Tracking number  
✅ Package details (from, to, description, weight)  
✅ "Track Your Package" button  
✅ Support contact information  
✅ Works on mobile and desktop  

---

### 🐛 Common Issues & Solutions

#### **Issue: No Email Received**

**Check:**
1. ✅ Spam/junk folder
2. ✅ Sender has email in Firestore `users` collection
3. ✅ SMTP credentials configured
4. ✅ Function deployed successfully
5. ✅ Check function logs for errors

**Fix:**
```bash
# Verify SMTP config
firebase functions:config:get smtp

# Should show:
# {
#   "user": "nauman@crowdwave.eu",
#   "password": "***"
# }
```

#### **Issue: Function Not Triggering**

**Check:**
```bash
# List deployed functions
firebase functions:list

# Should include: notifyTrackingStatusChange
```

**Fix:**
```bash
# Redeploy if missing
firebase deploy --only functions:notifyTrackingStatusChange
```

#### **Issue: Email Goes to Spam**

**Solution:**
- Normal for new sending domain
- Ask users to mark as "Not Spam"
- Sender reputation improves over time
- Add crowdwave.eu to contacts

#### **Issue: "Sender email not found"**

**Fix:**
1. Check Firestore `users/{userId}` document
2. Ensure `email` field exists
3. Verify email is valid format

```javascript
// Example user document structure:
{
  email: "user@example.com",  // ← Required!
  displayName: "John Doe",
  // ... other fields
}
```

---

### 📈 Success Metrics

After deployment, monitor:

1. **Email Delivery Rate**
   - Check Firebase Functions logs
   - Count successful vs failed sends

2. **User Feedback**
   - Ask users if they're receiving emails
   - Check spam rates

3. **Function Performance**
   - Monitor execution time
   - Check for timeouts or errors

---

### 🎯 Quick Validation

**Run this checklist after deployment:**

- [ ] Function deployed successfully
- [ ] Function appears in Firebase Console
- [ ] SMTP credentials configured
- [ ] Test email received when status changes
- [ ] Email looks professional on mobile
- [ ] Email looks professional on desktop
- [ ] Tracking link works
- [ ] All status changes trigger emails
- [ ] Logs show successful sends
- [ ] No errors in function logs

---

## 🚨 Emergency Rollback

If emails are causing issues:

```bash
# Disable the function
firebase functions:delete notifyTrackingStatusChange

# Or redeploy without it
# Comment out the export in functions/index.js
```

---

## ✅ Final Verification

**Everything working if:**

✅ Status changes trigger emails  
✅ Emails arrive within 1-2 minutes  
✅ Email content is correct  
✅ Links work properly  
✅ No errors in logs  
✅ Users report receiving updates  

---

**Last Updated:** October 22, 2025  
**Status:** Ready for Testing
