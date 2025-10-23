import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppleSignInDemo extends StatelessWidget {
  const AppleSignInDemo({Key? key}) : super(key: key);

  Future<UserCredential> signInWithApple() async {
    // Step 1: Get Apple credentials (browser flow on Android)
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: WebAuthenticationOptions(
        clientId: "com.crowdwave.service", // ✅ Your Apple Service ID
        redirectUri: Uri.parse(
          "https://crowdwave-93d4d.firebaseapp.com/__/auth/handler", // ✅ Firebase redirect URI
        ),
      ),
    );

    // Step 2: Convert Apple credentials into Firebase credentials
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    // Step 3: Sign in with Firebase
    return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apple Sign-In Demo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Apple Sign-In Configuration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configuration Details:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('🔑 Service ID: com.crowdwave.service'),
                  Text(
                      '🔄 Redirect URI: https://crowdwave-93d4d.firebaseapp.com/__/auth/handler'),
                  Text('📱 Platform: Android APK (Web Flow)'),
                ],
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                try {
                  final userCredential = await signInWithApple();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Signed in: ${userCredential.user?.uid}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  print("Signed in: ${userCredential.user?.uid}");
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Apple sign in failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  print("Apple sign in failed: $e");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.apple, size: 20),
                  SizedBox(width: 8),
                  Text('auth.sign_in_with_apple'.tr()),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              '⚠️ On Android → Apple sign-in will open a web view/browser flow.\nThis is normal behavior.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
