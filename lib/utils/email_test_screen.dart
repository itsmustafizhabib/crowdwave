import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/enhanced_firebase_auth_service.dart';
import '../services/custom_email_service.dart';

class EmailTestScreen extends StatefulWidget {
  const EmailTestScreen({Key? key}) : super(key: key);

  @override
  State<EmailTestScreen> createState() => _EmailTestScreenState();
}

class _EmailTestScreenState extends State<EmailTestScreen> {
  final EnhancedFirebaseAuthService _authService =
      EnhancedFirebaseAuthService();
  final CustomEmailService _customEmailService = CustomEmailService();
  final TextEditingController _emailController = TextEditingController();
  final List<String> _testResults = [];
  bool _isLoading = false;
  bool _useCloudFunction =
      true; // Toggle between Cloud Function and Firebase Auth

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

      final success =
          await _authService.sendEmailVerification(forceResend: true);

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
      _addResult(
          '📧 Using: ${_useCloudFunction ? "Cloud Function (Custom Email)" : "Firebase Auth (Default)"}');

      bool success;
      if (_useCloudFunction) {
        // Use Cloud Function with custom email template
        success = await _customEmailService
            .sendPasswordResetEmail(_emailController.text.trim());
      } else {
        // Use Firebase Auth default
        success =
            await _authService.resetPassword(_emailController.text.trim());
      }

      if (success) {
        _addResult('✅ Password reset email sent successfully!');
        _addResult('📧 Check the inbox for: ${_emailController.text.trim()}');
        _addResult('📬 Also check spam/junk folder');
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

  Future<void> _testEmailConfig() async {
    setState(() {
      _isLoading = true;
      _testResults.clear();
    });

    try {
      _addResult('🔄 Testing email configuration...');

      final result = await _customEmailService.testEmailConfig();

      _addResult('📊 Configuration Test Results:');
      _addResult(
          'Status: ${result['success'] == true ? '✅ Success' : '❌ Failed'}');
      _addResult('Message: ${result['message']}');

      if (result['config'] != null) {
        final config = result['config'];
        _addResult('\n📧 SMTP Configuration:');
        _addResult('Host: ${config['host']}');
        _addResult('Port: ${config['port']}');
        _addResult('Secure: ${config['secure']}');
        _addResult('User: ${config['user']}');
      }
    } catch (e) {
      _addResult('💥 Configuration test failed: ${e.toString()}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testDeliveryEmail() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackbar('Please enter an email address first', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _testResults.clear();
    });

    try {
      _addResult('🔄 Testing delivery update email...');

      // Sample package details
      final packageDetails = {
        'trackingNumber': 'CW-TEST-12345',
        'from': 'Berlin, Germany',
        'to': 'Paris, France',
        'estimatedDelivery': DateTime.now()
            .add(const Duration(days: 3))
            .toString()
            .substring(0, 10),
      };

      final success = await _customEmailService.sendDeliveryUpdateEmail(
        recipientEmail: _emailController.text.trim(),
        packageDetails: packageDetails,
        status: 'In Transit',
        trackingUrl: 'https://crowdwave.eu/track/CW-TEST-12345',
      );

      if (success) {
        _addResult('✅ Delivery update email sent successfully!');
        _addResult('📧 Check the inbox for: ${_emailController.text.trim()}');
        _addResult('📦 Sent test package update');
      } else {
        _addResult('❌ Failed to send delivery update email');
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
      _testResults.add(
          '${DateTime.now().toLocal().toString().substring(11, 19)} - $result');
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
        title: Text('debug.email_testing_title'.tr()),
        backgroundColor: Color(0xFF008080),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email method toggle
            Card(
              color: Colors.purple.shade50,
              child: SwitchListTile(
                title: Text('debug.use_cloud_function'.tr()),
                subtitle: Text(_useCloudFunction
                    ? 'Using Zoho SMTP with custom templates'
                    : 'Using Firebase default emails'),
                value: _useCloudFunction,
                onChanged: (value) {
                  setState(() {
                    _useCloudFunction = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),

            // Email input for password reset testing
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'common.test_email_address'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'common.enter_email_address_to_test'.tr(),
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
                    label: Text('debug.verification'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testPasswordReset,
                    icon: const Icon(Icons.lock_reset),
                    label: Text('debug.password_reset'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF008080),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testDeliveryEmail,
                    icon: const Icon(Icons.local_shipping),
                    label: Text('debug.delivery_update'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testEmailConfig,
                    icon: const Icon(Icons.settings),
                    label: Text('debug.test_config'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runDiagnostics,
              icon: const Icon(Icons.bug_report),
              label: Text('debug.run_diagnostics'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text('debug.running_test'.tr()),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
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
                child: Text('debug.clear_results'.tr()),
              ),
          ],
        ),
      ),
    );
  }
}
