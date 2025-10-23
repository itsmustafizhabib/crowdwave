import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import '../core/models/wallet.dart';
import '../core/models/wallet_transaction.dart';

/// Wallet service for managing user wallets and transactions
class WalletService extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String _walletsCollection = 'wallets';
  static const String _transactionsCollection = 'transactions';

  // Observable wallet data
  final Rx<Wallet?> _currentWallet = Rx<Wallet?>(null);
  final RxList<WalletTransaction> _transactions = <WalletTransaction>[].obs;
  final RxBool _isLoading = false.obs;

  Wallet? get currentWallet => _currentWallet.value;
  List<WalletTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading.value;

  /// Get wallet for a specific user
  Future<Wallet?> getWallet(String userId) async {
    try {
      final doc =
          await _firestore.collection(_walletsCollection).doc(userId).get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('⚠️ Wallet not found for user: $userId');
        }
        return null;
      }

      return Wallet.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting wallet: $e');
      }
      rethrow;
    }
  }

  /// Stream wallet updates in real-time
  Stream<Wallet?> streamWallet(String userId) {
    return _firestore
        .collection(_walletsCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return Wallet.fromFirestore(snapshot);
    });
  }

  /// Create a new wallet for a user
  Future<void> createWallet(String userId, {String currency = 'EUR'}) async {
    try {
      _isLoading.value = true;

      // Check if wallet already exists
      final existingWallet = await getWallet(userId);
      if (existingWallet != null) {
        if (kDebugMode) {
          print('⚠️ Wallet already exists for user: $userId');
        }
        return;
      }

      final wallet = Wallet.newWallet(userId: userId, currency: currency);

      await _firestore
          .collection(_walletsCollection)
          .doc(userId)
          .set(wallet.toFirestore());

      if (kDebugMode) {
        print('✅ Wallet created for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating wallet: $e');
      }
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Add earning to wallet (after delivery confirmation)
  Future<void> addEarning({
    required String userId,
    required double amount,
    required String bookingId,
    String? trackingId,
    String? description,
  }) async {
    try {
      _isLoading.value = true;

      final walletRef = _firestore.collection(_walletsCollection).doc(userId);

      // Update wallet balances
      await _firestore.runTransaction((transaction) async {
        final walletDoc = await transaction.get(walletRef);

        if (!walletDoc.exists) {
          throw Exception('Wallet not found for user: $userId');
        }

        final currentBalance = (walletDoc.data()?['balance'] ?? 0.0).toDouble();
        final currentEarnings =
            (walletDoc.data()?['totalEarnings'] ?? 0.0).toDouble();

        transaction.update(walletRef, {
          'balance': currentBalance + amount,
          'totalEarnings': currentEarnings + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Create transaction record
      await _createTransaction(
        userId: userId,
        type: WalletTransactionType.earning,
        amount: amount,
        status: WalletTransactionStatus.completed,
        bookingId: bookingId,
        trackingId: trackingId,
        description: description ?? 'Payment received for delivery #$bookingId',
      );

      if (kDebugMode) {
        print('✅ Earning added: \$${amount.toStringAsFixed(2)} to $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding earning: $e');
      }
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Add spending to wallet (when sending a package)
  Future<void> addSpending({
    required String userId,
    required double amount,
    required String bookingId,
    String? description,
  }) async {
    try {
      _isLoading.value = true;

      final walletRef = _firestore.collection(_walletsCollection).doc(userId);

      // Update wallet balances
      await _firestore.runTransaction((transaction) async {
        final walletDoc = await transaction.get(walletRef);

        if (!walletDoc.exists) {
          throw Exception('Wallet not found for user: $userId');
        }

        final currentBalance = (walletDoc.data()?['balance'] ?? 0.0).toDouble();
        final currentSpent =
            (walletDoc.data()?['totalSpent'] ?? 0.0).toDouble();

        // Check sufficient balance
        if (currentBalance < amount) {
          throw Exception('Insufficient balance');
        }

        transaction.update(walletRef, {
          'balance': currentBalance - amount,
          'totalSpent': currentSpent + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Create transaction record
      await _createTransaction(
        userId: userId,
        type: WalletTransactionType.spending,
        amount: amount,
        status: WalletTransactionStatus.completed,
        bookingId: bookingId,
        description: description ?? 'Payment for booking #$bookingId',
      );

      if (kDebugMode) {
        print('✅ Spending added: \$${amount.toStringAsFixed(2)} from $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding spending: $e');
      }
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Add spending transaction record for external payments (e.g., Stripe)
  /// This creates a transaction record and updates totalSpent without modifying wallet balance
  /// since payment was already processed externally
  Future<void> addSpendingTransaction({
    required String userId,
    required double amount,
    required String bookingId,
    String? description,
  }) async {
    try {
      _isLoading.value = true;

      if (kDebugMode) {
        print('💳 WalletService.addSpendingTransaction called');
        print('   User ID: $userId');
        print('   Amount: \$${amount.toStringAsFixed(2)}');
        print('   Booking ID: $bookingId');
        print(
            '   Description: ${description ?? 'Payment via Stripe for booking #$bookingId'}');
      }

      // Create transaction record only (no wallet balance change)
      await _createTransaction(
        userId: userId,
        type: WalletTransactionType.spending,
        amount: amount,
        status: WalletTransactionStatus.completed,
        bookingId: bookingId,
        description:
            description ?? 'Payment via Stripe for booking #$bookingId',
        metadata: {
          'payment_method': 'stripe',
          'external_payment': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Update wallet's totalSpent field
      await _firestore.collection(_walletsCollection).doc(userId).update({
        'totalSpent': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ External spending transaction recorded successfully!');
        print('   Collection: $_transactionsCollection');
        print('   User: $userId');
        print('   Amount: \$${amount.toStringAsFixed(2)}');
        print(
            '   Wallet totalSpent incremented by: \$${amount.toStringAsFixed(2)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error recording spending transaction: $e');
        print('   Stack trace: ${StackTrace.current}');
      }
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Hold payment in pending balance (escrow)
  Future<void> holdPayment({
    required String userId,
    required double amount,
    required String bookingId,
    String? description,
  }) async {
    try {
      _isLoading.value = true;

      final walletRef = _firestore.collection(_walletsCollection).doc(userId);

      // Update pending balance
      await _firestore.runTransaction((transaction) async {
        final walletDoc = await transaction.get(walletRef);

        if (!walletDoc.exists) {
          throw Exception('Wallet not found for user: $userId');
        }

        final currentPending =
            (walletDoc.data()?['pendingBalance'] ?? 0.0).toDouble();

        transaction.update(walletRef, {
          'pendingBalance': currentPending + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Create transaction record
      await _createTransaction(
        userId: userId,
        type: WalletTransactionType.hold,
        amount: amount,
        status: WalletTransactionStatus.pending,
        bookingId: bookingId,
        description: description ?? 'Payment held for booking #$bookingId',
      );

      if (kDebugMode) {
        print('✅ Payment held: \$${amount.toStringAsFixed(2)} for $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error holding payment: $e');
      }
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Release payment from pending to available balance
  Future<void> releasePayment({
    required String userId,
    required double amount,
    required String bookingId,
    String? trackingId,
    String? description,
  }) async {
    try {
      _isLoading.value = true;

      final walletRef = _firestore.collection(_walletsCollection).doc(userId);

      // Move from pending to balance
      await _firestore.runTransaction((transaction) async {
        final walletDoc = await transaction.get(walletRef);

        if (!walletDoc.exists) {
          throw Exception('Wallet not found for user: $userId');
        }

        final currentBalance = (walletDoc.data()?['balance'] ?? 0.0).toDouble();
        final currentPending =
            (walletDoc.data()?['pendingBalance'] ?? 0.0).toDouble();
        final currentEarnings =
            (walletDoc.data()?['totalEarnings'] ?? 0.0).toDouble();

        // Check sufficient pending balance
        if (currentPending < amount) {
          throw Exception('Insufficient pending balance');
        }

        transaction.update(walletRef, {
          'balance': currentBalance + amount,
          'pendingBalance': currentPending - amount,
          'totalEarnings': currentEarnings + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Update hold transaction to completed
      await _updateHoldTransaction(
        userId: userId,
        bookingId: bookingId,
        status: WalletTransactionStatus.completed,
      );

      // Create release transaction record
      await _createTransaction(
        userId: userId,
        type: WalletTransactionType.release,
        amount: amount,
        status: WalletTransactionStatus.completed,
        bookingId: bookingId,
        trackingId: trackingId,
        description: description ?? 'Payment released for booking #$bookingId',
      );

      if (kDebugMode) {
        print('✅ Payment released: \$${amount.toStringAsFixed(2)} to $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error releasing payment: $e');
      }
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Process withdrawal to bank account
  Future<void> processWithdrawal({
    required String userId,
    required double amount,
    Map<String, dynamic>? bankDetails,
  }) async {
    try {
      _isLoading.value = true;

      final walletRef = _firestore.collection(_walletsCollection).doc(userId);

      // Update wallet balances
      await _firestore.runTransaction((transaction) async {
        final walletDoc = await transaction.get(walletRef);

        if (!walletDoc.exists) {
          throw Exception('Wallet not found for user: $userId');
        }

        final currentBalance = (walletDoc.data()?['balance'] ?? 0.0).toDouble();
        final currentWithdrawals =
            (walletDoc.data()?['totalWithdrawals'] ?? 0.0).toDouble();

        // Check sufficient balance
        if (currentBalance < amount) {
          throw Exception('Insufficient balance for withdrawal');
        }

        transaction.update(walletRef, {
          'balance': currentBalance - amount,
          'totalWithdrawals': currentWithdrawals + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Create transaction record
      await _createTransaction(
        userId: userId,
        type: WalletTransactionType.withdrawal,
        amount: amount,
        status: WalletTransactionStatus.pending,
        description: 'profile.withdrawal_to_bank_account'.tr(),
        metadata: bankDetails,
      );

      if (kDebugMode) {
        print(
            '✅ Withdrawal initiated: \$${amount.toStringAsFixed(2)} for $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing withdrawal: $e');
      }
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get transaction history for a user
  Future<List<WalletTransaction>> getTransactions(
    String userId, {
    int limit = 50,
    WalletTransactionType? type,
  }) async {
    try {
      Query query = _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => WalletTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting transactions: $e');
      }
      rethrow;
    }
  }

  /// Stream transaction history in real-time
  Stream<List<WalletTransaction>> streamTransactions(
    String userId, {
    int limit = 50,
    WalletTransactionType? type,
  }) {
    Query query = _firestore
        .collection(_transactionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => WalletTransaction.fromFirestore(doc))
          .toList();
    });
  }

  /// Create a transaction record
  Future<void> _createTransaction({
    required String userId,
    required WalletTransactionType type,
    required double amount,
    required WalletTransactionStatus status,
    String? bookingId,
    String? trackingId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    if (kDebugMode) {
      print('📝 _createTransaction called');
      print('   Collection: $_transactionsCollection');
      print('   User ID: $userId');
      print('   Type: ${type.name}');
      print('   Amount: \$${amount.toStringAsFixed(2)}');
      print('   Status: ${status.name}');
      print('   Booking ID: $bookingId');
    }

    final transaction = WalletTransaction(
      id: '', // Will be set by Firestore
      userId: userId,
      type: type,
      amount: amount,
      status: status,
      bookingId: bookingId,
      trackingId: trackingId,
      description: description,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    final docRef = await _firestore
        .collection(_transactionsCollection)
        .add(transaction.toFirestore());

    if (kDebugMode) {
      print('✅ Transaction document created with ID: ${docRef.id}');
      print('   Path: ${docRef.path}');
    }
  }

  /// Update hold transaction status
  Future<void> _updateHoldTransaction({
    required String userId,
    required String bookingId,
    required WalletTransactionStatus status,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: userId)
          .where('bookingId', isEqualTo: bookingId)
          .where('type', isEqualTo: WalletTransactionType.hold.name)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'status': status.name,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error updating hold transaction: $e');
      }
      // Don't rethrow - this is not critical
    }
  }

  /// Load current user's wallet
  Future<void> loadCurrentUserWallet() async {
    final user = _auth.currentUser;
    if (user == null) {
      _currentWallet.value = null;
      return;
    }

    try {
      _isLoading.value = true;
      final wallet = await getWallet(user.uid);
      _currentWallet.value = wallet;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading current user wallet: $e');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load current user's transactions
  Future<void> loadCurrentUserTransactions({int limit = 50}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _transactions.clear();
      return;
    }

    try {
      _isLoading.value = true;
      final txns = await getTransactions(user.uid, limit: limit);
      _transactions.value = txns;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading transactions: $e');
      }
    } finally {
      _isLoading.value = false;
    }
  }
}
