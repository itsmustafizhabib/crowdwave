import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧪 Test FCM Notification via Cloud Functions
class TestFCMNotificationScreen extends StatefulWidget {
  const TestFCMNotificationScreen({Key? key}) : super(key: key);

  @override
  State<TestFCMNotificationScreen> createState() =>
      _TestFCMNotificationScreenState();
}

class _TestFCMNotificationScreenState extends State<TestFCMNotificationScreen> {
  bool _isLoading = false;
  String _result = '';

  Future<void> _testFCMNotification() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      // Get current user's FCM token
      final firestore = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      if (currentUser == null) {
        setState(() {
          _result = '❌ No user logged in';
          _isLoading = false;
        });
        return;
      }

      final userDoc =
          await firestore.collection('users').doc(currentUser.uid).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        setState(() {
          _result = '❌ No FCM token found for current user';
          _isLoading = false;
        });
        return;
      }

      print('🔍 Testing FCM with token: ${fcmToken.substring(0, 20)}...');

      // Call Cloud Function
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendFCMNotification');

      final result = await callable.call({
        'fcmToken': fcmToken,
        'title': '📞 Test Call Notification',
        'body': 'This is a test incoming call notification!',
        'data': {
          'callId': 'test_call_123',
          'roomId': 'test_room_123',
          'callerName': 'Test Caller',
          'callerId': 'test_caller_123',
          'type': 'voice_call',
          'action': 'incoming_call',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      });

      setState(() {
        _result =
            '✅ FCM notification sent successfully!\n\nResult: ${result.data}';
        _isLoading = false;
      });

      print('✅ FCM test result: ${result.data}');
    } catch (e) {
      setState(() {
        _result = '❌ Failed to send FCM notification:\n\n$e';
        _isLoading = false;
      });
      print('❌ FCM test error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test FCM Notifications'),
        backgroundColor: const Color(0xFF0046FF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.notification_important,
              size: 80,
              color: Color(0xFF0046FF),
            ),
            const SizedBox(height: 30),
            const Text(
              'Test FCM Notifications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Test if push notifications work via Cloud Functions',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testFCMNotification,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              label: Text(
                _isLoading ? 'Sending...' : 'Test FCM Notification',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0046FF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _result.startsWith('✅')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  border: Border.all(
                    color: _result.startsWith('✅') ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result,
                  style: TextStyle(
                    color: _result.startsWith('✅')
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to test:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Tap "Test FCM Notification"'),
                    Text('2. You should receive a push notification'),
                    Text(
                        '3. Tap the notification to test incoming call screen'),
                    Text('4. If it works, real calls will work too!'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
