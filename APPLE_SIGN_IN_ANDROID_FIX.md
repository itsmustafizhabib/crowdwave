# Apple Sign-In Android Configuration Guide

## 🎯 Overview
This guide will help you configure Apple Sign-In for Android in your Flutter app.

## ✅ What I've Done
I've updated your `enhanced_firebase_auth_service.dart` to include the required `webAuthenticationOptions` for Android:

```dart
webAuthenticationOptions: WebAuthenticationOptions(
  clientId: 'com.crowdwave.courier.service',
  redirectUri: Uri.parse(
    'https://crowdwave-courier.firebaseapp.com/__/auth/handler',
  ),
),
```

## 🔧 What You Need to Do

### Step 1: Get Your Firebase Project Details
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your CrowdWave project
3. Note your Firebase Hosting domain (should be something like `crowdwave-courier.firebaseapp.com`)
   - If different, update the `redirectUri` in the code

### Step 2: Configure Apple Developer Portal

#### 2.1 Create/Update Service ID
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** in the left sidebar
4. Click the **+** button or select your existing Service ID
5. Select **Services IDs** and click **Continue**
6. Fill in the details:
   - **Description**: CrowdWave Courier Service
   - **Identifier**: `com.crowdwave.courier.service` (must match the `clientId` in code)
7. Click **Continue** and **Register**

#### 2.2 Configure Sign In with Apple
1. Select your newly created Service ID from the list
2. Check the box next to **Sign In with Apple**
3. Click **Configure** next to "Sign In with Apple"
4. In the configuration window:
   - **Primary App ID**: Select your main iOS app identifier (`com.crowdwave.courier`)
   - **Domains and Subdomains**: Add your Firebase domain:
     ```
     crowdwave-courier.firebaseapp.com
     ```
   - **Return URLs**: Add your redirect URI:
     ```
     https://crowdwave-courier.firebaseapp.com/__/auth/handler
     ```
5. Click **Save**
6. Click **Continue** and **Save** again

#### 2.3 Verify Configuration
1. Go back to your Service ID in the Identifiers list
2. Confirm that "Sign In with Apple" is enabled
3. Click on it to verify:
   - ✅ Primary App ID is set
   - ✅ Domain is correct
   - ✅ Return URL is correct

### Step 3: Update Firebase Console (if using Firebase Auth)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Authentication** → **Sign-in method**
4. Click on **Apple**
5. Make sure it's **Enabled**
6. Add the Service ID:
   - OAuth code flow configuration → Service ID: `com.crowdwave.courier.service`
7. Click **Save**

### Step 4: Update Your Code (if needed)

If your Firebase Hosting domain is different from `crowdwave-courier.firebaseapp.com`, update the code:

1. Open `lib/services/enhanced_firebase_auth_service.dart`
2. Find the `signInWithApple()` method
3. Update the `redirectUri` to match your actual Firebase domain:
   ```dart
   redirectUri: Uri.parse(
     'https://YOUR-PROJECT-ID.firebaseapp.com/__/auth/handler',
   ),
   ```

### Step 5: Test the Implementation

1. Clean and rebuild your app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. Test Apple Sign-In on:
   - ✅ Android device/emulator
   - ✅ iOS device/simulator
   - ✅ Web (if applicable)

## 🔍 Common Issues & Solutions

### Issue 1: "Invalid redirect URI"
**Solution**: Make sure the redirect URI in your code exactly matches the one configured in Apple Developer Portal.

### Issue 2: "Invalid client_id"
**Solution**: Verify that the `clientId` in your code matches the Service ID identifier from Apple Developer Portal.

### Issue 3: "Domain not verified"
**Solution**: 
1. Check that you added the correct domain in Apple Developer Portal
2. Don't include `https://` or trailing slashes in the domain field
3. Wait a few minutes for DNS propagation

### Issue 4: Still getting the error on Android
**Solution**:
1. Make sure you've saved all changes in Apple Developer Portal
2. Try signing out and back in to Apple Developer Portal
3. Wait 5-10 minutes for Apple's servers to propagate changes
4. Clear your app's cache and data on Android
5. Rebuild the app completely

## 📝 Configuration Summary

**Package Name (Android)**: `com.crowdwave.courier`

**Service ID**: `com.crowdwave.courier.service`

**Redirect URI**: `https://crowdwave-courier.firebaseapp.com/__/auth/handler`

**Primary App ID**: `com.crowdwave.courier`

## 🎉 After Configuration

Once everything is configured:
1. The error should disappear
2. Apple Sign-In will work on Android, iOS, and Web
3. Users will see the Apple authentication page in a web view on Android
4. The authentication flow will be seamless

## 📚 Additional Resources

- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Flutter Sign In with Apple Package](https://pub.dev/packages/sign_in_with_apple)
- [Firebase Authentication with Apple](https://firebase.google.com/docs/auth/ios/apple)

## ⚠️ Important Notes

1. **Service ID is required for Android/Web**: iOS uses the App ID, but Android and Web need a separate Service ID.

2. **Redirect URI must be HTTPS**: Apple requires secure connections.

3. **Domain verification**: The domain in your redirect URI must be verified with Apple.

4. **Testing**: Always test on actual Android devices after configuration changes.

5. **Firebase Hosting**: If you're not using Firebase Hosting, you'll need to host your own callback handler or use another authentication backend.

## 🚀 Next Steps

1. ✅ Code has been updated with `webAuthenticationOptions`
2. ⏳ Configure Service ID in Apple Developer Portal
3. ⏳ Test on Android device
4. ⏳ Verify it works on iOS as well
5. ⏳ Document any custom redirect URIs for your team

---

**Need Help?** 
- Check Apple Developer Portal documentation
- Review Firebase Authentication logs
- Test with Firebase Authentication debug mode enabled
