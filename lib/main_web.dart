import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';

import '../services/auth_state_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    return Material(
      child: Container(
        color: Colors.red,
        child: Center(
          child: Text(
            'Error: ${errorDetails.exception}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  };

  runApp(const CrowdWaveWebApp());
}

class CrowdWaveWebApp extends StatelessWidget {
  const CrowdWaveWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthStateService()),
          ],
          child: GetMaterialApp(
            title: 'CrowdWave - Courier Delivery Platform',
            theme: ThemeData(
              primarySwatch: Colors.orange,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: const WebHomePage(),
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}

class WebHomePage extends StatelessWidget {
  const WebHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('CrowdWave'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'CrowdWave',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'Courier Delivery Platform',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Description
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: const Text(
                  'Connect travelers with people who need items delivered worldwide. The future of crowdsourced delivery is here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Download buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDownloadButton(
                    'Download for iOS',
                    Icons.apple,
                    'https://apps.apple.com/app/crowdwave',
                  ),
                  const SizedBox(width: 24),
                  _buildDownloadButton(
                    'Download for Android',
                    Icons.android,
                    'https://play.google.com/store/apps/details?id=com.crowdwave.courier',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(String text, IconData icon, String url) {
    return ElevatedButton.icon(
      onPressed: () {
        // In a real app, you'd open the URL
        // html.window.open(url, '_blank');
      },
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}
