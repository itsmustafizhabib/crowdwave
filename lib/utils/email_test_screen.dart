import 'package:flutter/material.dart';
import '../services/enhanced_firebase_auth_service.dart';

class EmailTestScreen extends StatefulWidget {
  const EmailTestScreen({Key? key}) : super(key: key);

  @override
  State<EmailTestScreen> createState() => _EmailTestScreenState();
}

class _EmailTestScreenState extends State<EmailTestScreen> {
  final EnhancedFirebaseAuthService _authService = EnhancedFirebaseAuthService();
  final TextEditingController _emailController = TextEditingController();
  final List<String> _testResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _testEmailVerification() async {
    setState(() {
      _isLoading = true;
      _testResults.clear();
    });

    try {
      _addResult('🔄 Testing email verification...');
      
      final success = await _authService.sendEmailVerification(forceResend: true);
      
      if (success) {
        _addResult('✅ Email verification sent successfully!');
        _addResult('📧 Check your email inbox (and spam folder)');
      } else {
        _addResult('❌ Failed to send email verification');
      }
    } catch (e) {
      _addResult('💥 Error: ${e.toString()}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testPasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackbar('Please enter an email address first', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _testResults.clear();
    });

    try {
      _addResult('🔄 Testing password reset...');
      
      final success = await _authService.resetPassword(_emailController.text.trim());
      
      if (success) {
        _addResult('✅ Password reset email sent successfully!');
        _addResult('📧 Check the inbox for: ${_emailController.text.trim()}');
      } else {
        _addResult('❌ Failed to send password reset email');
      }
    } catch (e) {
      _addResult('💥 Error: ${e.toString()}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _testResults.clear();
    });

    try {
      _addResult('🔄 Running email diagnostics...');
      
      final results = await _authService.testEmailConnectivity();
      
      _addResult('📊 Diagnostic Results:');
      _addResult('Status: ${results['status']}');
      _addResult('Message: ${results['message']}');
      
      if (results['user_email'] != null) {
        _addResult('User Email: ${results['user_email']}');
        _addResult('Email Verified: ${results['user_verified']}');
        _addResult('Firebase Connection: ${results['firebase_connection']}');
      }
      
    } catch (e) {
      _addResult('💥 Diagnostics failed: ${e.toString()}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _addResult(String result) {
    setState(() {
      _testResults.add('${DateTime.now().toLocal().toString().substring(11, 19)} - $result');
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Testing & Diagnostics'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email input for password reset testing
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Test Email (for password reset)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'Enter email address to test',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testEmailVerification,
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Test Verification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testPasswordReset,
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Test Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runDiagnostics,
              icon: const Icon(Icons.bug_report),
              label: const Text('Run Diagnostics'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Results section
            const Text(
              'Test Results:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Results list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Running test...'),
                        ],
                      ),
                    )
                  : _testResults.isEmpty
                      ? const Center(
                          child: Text(
                            'No test results yet.\nClick a test button to start.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Card(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _testResults.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  _testResults[index],
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),

            // Clear button
            if (_testResults.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _testResults.clear();
                  });
                },
                child: const Text('Clear Results'),
              ),
          ],
        ),
      ),
    );
  }
}
