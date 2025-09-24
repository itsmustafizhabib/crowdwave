import 'package:flutter/material.dart';

void main() {
  runApp(DebugApp());
}

class DebugApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debug CrowdWave',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Debug Screen'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
              SizedBox(height: 20),
              Text(
                'App is Working!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'If you see this, the Flutter app is running correctly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Button works!')),
                  );
                },
                child: Text('Test Button'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
