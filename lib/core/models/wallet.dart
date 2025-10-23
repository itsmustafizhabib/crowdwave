import 'package:cloud_firestore/cloud_firestore.dart';

/// Wallet model for user financial management
class Wallet {
  final String userId;
  final double balance; // Available balance for withdrawal
  final double pendingBalance; // Held payments awaiting confirmation
  final double totalEarnings; // Total earned from deliveries
  final double totalSpent; // Total spent on bookings
  final double totalWithdrawals; // Total withdrawn to bank
  final String currency; // Currency code (e.g., 'EUR', 'PKR')
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.userId,
    required this.balance,
    required this.pendingBalance,
    required this.totalEarnings,
    required this.totalSpent,
    required this.totalWithdrawals,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create wallet from Firestore document
  factory Wallet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Wallet(
      userId: doc.id,
      balance: (data['balance'] ?? 0.0).toDouble(),
      pendingBalance: (data['pendingBalance'] ?? 0.0).toDouble(),
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      totalSpent: (data['totalSpent'] ?? 0.0).toDouble(),
      totalWithdrawals: (data['totalWithdrawals'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'EUR',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId, // Required by Firestore security rules
      'balance': balance,
      'pendingBalance': pendingBalance,
      'totalEarnings': totalEarnings,
      'totalSpent': totalSpent,
      'totalWithdrawals': totalWithdrawals,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  Wallet copyWith({
    String? userId,
    double? balance,
    double? pendingBalance,
    double? totalEarnings,
    double? totalSpent,
    double? totalWithdrawals,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalSpent: totalSpent ?? this.totalSpent,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create new wallet with default values
  factory Wallet.newWallet({
    required String userId,
    String currency = 'EUR',
  }) {
    final now = DateTime.now();
    return Wallet(
      userId: userId,
      balance: 0.0,
      pendingBalance: 0.0,
      totalEarnings: 0.0,
      totalSpent: 0.0,
      totalWithdrawals: 0.0,
      currency: currency,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get total wallet value (balance + pending)
  double get totalValue => balance + pendingBalance;

  /// Check if user has sufficient balance for amount
  bool hasSufficientBalance(double amount) => balance >= amount;

  /// Check if wallet has any activity
  bool get hasActivity =>
      totalEarnings > 0 || totalSpent > 0 || totalWithdrawals > 0;

  @override
  String toString() {
    return 'Wallet(userId: $userId, balance: €$balance, pending: €$pendingBalance, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wallet && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
