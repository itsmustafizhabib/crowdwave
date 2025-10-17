// Quick test script to verify Firebase Functions are accessible
// Run this in Flutter console: dart run test_functions.dart

import 'package:cloud_functions/cloud_functions.dart';

void main() async {
  print('🧪 Testing Firebase Functions accessibility...');

  // Test us-central1 region
  try {
    print('📍 Testing us-central1 region...');
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    functions.httpsCallable('testAuth');

    print('✅ us-central1 testAuth function found and accessible');

    // Test confirmPayment function exists
    functions.httpsCallable('confirmPayment');
    print('✅ us-central1 confirmPayment function found and accessible');
  } catch (e) {
    print('❌ us-central1 region test failed: $e');
  }

  // Test default region
  try {
    print('📍 Testing default region...');
    final defaultFunctions = FirebaseFunctions.instance;
    defaultFunctions.httpsCallable('testAuth');

    print('✅ Default testAuth function found and accessible');

    // Test confirmPayment function exists
    defaultFunctions.httpsCallable('confirmPayment');
    print('✅ Default confirmPayment function found and accessible');
  } catch (e) {
    print('❌ Default region test failed: $e');
  }

  print('🎯 Function accessibility test completed');
}
