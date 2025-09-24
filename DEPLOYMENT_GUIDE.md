# CrowdWave Production Deployment Guide

## Overview
This guide covers the steps to deploy CrowdWave to Google Play Store and Apple App Store.

## Pre-Deployment Checklist

### ✅ Completed Configurations
- [x] App name updated to "CrowdWave"
- [x] Version set to 1.0.0+1 (ready for first release)
- [x] Android release signing configuration
- [x] Android app bundle optimizations
- [x] iOS deployment settings
- [x] Permission descriptions updated
- [x] App metadata improved

### 📋 Required Actions Before Store Submission

#### 1. Generate Android Release Keystore
```bash
# Navigate to android directory
cd android

# Generate keystore (replace with your details)
keytool -genkey -v -keystore crowdwave-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias crowdwave

# Create key.properties file
cp key.properties.example key.properties
# Edit key.properties with your keystore details
```

#### 2. Build Android App Bundle
```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build release AAB for Play Store
flutter build appbundle --release

# The AAB will be at: build/app/outputs/bundle/release/app-release.aab
```

#### 3. Build iOS App for App Store
```bash
# Build iOS release
flutter build ios --release

# Open Xcode to archive and upload
open ios/Runner.xcworkspace
```

## Store Submission Requirements

### Google Play Store
1. **App Bundle**: Use the generated AAB file
2. **Package Name**: `com.crowdwave.courier`
3. **Target API Level**: 34 (Android 14)
4. **Required Screenshots**: Phone, Tablet, TV (if applicable)
5. **Privacy Policy**: Required for apps with sensitive permissions
6. **App Content Rating**: Complete content questionnaire

### Apple App Store
1. **Bundle Identifier**: Should match your Apple Developer account
2. **iOS Deployment Target**: 12.0+
3. **Required Screenshots**: iPhone, iPad
4. **App Store Connect**: Create app listing
5. **TestFlight**: Test before release

## Important Security Notes

### API Keys and Secrets
- [ ] Review all API keys in the codebase
- [ ] Ensure Firebase configuration is production-ready
- [ ] Update Facebook App ID with production values
- [ ] Verify Google Maps API key restrictions

### Privacy and Permissions
The app requests these permissions:
- **Location**: For delivery tracking and route optimization
- **Camera**: For video calls and package verification
- **Microphone**: For voice calls between users
- **Notifications**: For delivery updates and messages
- **Storage**: For temporary file handling

### Data Handling
- [ ] Implement proper data encryption
- [ ] Review Firestore security rules
- [ ] Ensure GDPR compliance if targeting EU
- [ ] Implement user data deletion functionality

## Production Environment Setup

### Firebase Configuration
- [ ] Create production Firebase project
- [ ] Update google-services.json (Android)
- [ ] Update GoogleService-Info.plist (iOS)
- [ ] Configure production Firestore database
- [ ] Set up Analytics and Crashlytics

### Backend Services
- [ ] Deploy backend services to production
- [ ] Configure production database
- [ ] Set up monitoring and logging
- [ ] Configure backup strategies

## Pre-Launch Testing

### Recommended Testing
1. **Internal Testing**: Test with team members
2. **Closed Beta**: Limited external testing
3. **Open Beta**: Wider testing group
4. **Performance Testing**: Load and stress testing
5. **Security Testing**: Penetration testing

### Critical User Flows to Test
- [ ] User registration and authentication
- [ ] Package posting and matching
- [ ] In-app messaging and calling
- [ ] Payment processing
- [ ] Review and rating system
- [ ] Location tracking and notifications

## Post-Launch Monitoring

### Analytics to Monitor
- User acquisition and retention
- App performance and crash rates
- Feature usage statistics
- User feedback and reviews
- Revenue and transaction metrics

### Update Strategy
- Plan regular updates every 2-4 weeks
- Monitor store reviews for issues
- Implement A/B testing for new features
- Keep dependencies updated

## Support and Maintenance

### Documentation
- [ ] Create user manual/help section
- [ ] Document API endpoints
- [ ] Create troubleshooting guide
- [ ] Set up customer support system

### Legal Requirements
- [ ] Terms of Service
- [ ] Privacy Policy
- [ ] Cookie Policy (if applicable)
- [ ] Accessibility compliance

## Build Commands Summary

```bash
# Android Release Build
flutter build appbundle --release --split-per-abi

# iOS Release Build
flutter build ios --release

# Generate App Bundle with specific architectures
flutter build appbundle --target-platform android-arm,android-arm64,android-x64

# Debug builds for testing
flutter build apk --debug
flutter build ios --debug
```

## Troubleshooting Common Issues

### Android Build Issues
- Ensure Android SDK is up to date
- Check Gradle version compatibility
- Verify keystore configuration
- Review ProGuard rules if minification fails

### iOS Build Issues
- Update Xcode to latest version
- Check iOS deployment target compatibility
- Verify bundle identifier matches Apple Developer account
- Ensure all required capabilities are enabled

---

**Note**: This guide assumes you have proper developer accounts for both Google Play Store and Apple App Store. Make sure to follow each platform's specific guidelines and requirements.