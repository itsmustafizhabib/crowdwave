import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../call/voice_call_screen.dart';
import '../call/incoming_call_screen.dart';
import '../call/test_fcm_notification_screen.dart';

/// 🧪 Voice Call Test Screen - For testing voice call UI without another user
class VoiceCallTestScreen extends StatelessWidget {
  const VoiceCallTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('common.voice_call_test'.tr()),
        backgroundColor: const Color(0xFF215C5C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.phone,
              size: 80,
              color: Color(0xFF215C5C),
            ),
            const SizedBox(height: 30),
            Text('common.voice_call_test'.tr(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('common.test_the_voice_call_ui_and_functionality'.tr(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VoiceCallScreen(
                      roomID: 'test_room_123',
                      localUserID: 'test_user_1',
                      localUserName: 'Test User',
                      receiverName: 'Test Receiver',
                      receiverAvatar: null,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.phone, color: Colors.white),
              label: Text('common.test_voice_call_ui'.tr(),
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IncomingCallScreen(
                      callId: 'test_call_123',
                      roomId: 'test_room_123',
                      callerName: 'John Doe',
                      callerId: 'test_caller_123',
                      notificationId: 'test_notification_123',
                      callerAvatar: null,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.call_received, color: Colors.white),
              label: Text('common.test_incoming_call_ui'.tr(),
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF215C5C),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TestFCMNotificationScreen(),
                  ),
                );
              },
              icon:
                  const Icon(Icons.notification_important, color: Colors.white),
              label: Text('notifications.test_fcm_notifications'.tr(),
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                      'Test Features:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• Voice call UI layout'),
                    Text('• Mute/unmute controls'),
                    Text('• Speaker toggle'),
                    Text('• Call duration timer'),
                    Text('• End call functionality'),
                    Text('• Connection animations'),
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
