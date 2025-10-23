import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import '../../core/models/wallet_transaction.dart';
import '../../services/wallet_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final WalletService _walletService = Get.find<WalletService>();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  WalletTransactionType? _selectedFilter;
  final List<WalletTransactionType> _filterOptions = [
    WalletTransactionType.earning,
    WalletTransactionType.spending,
    WalletTransactionType.withdrawal,
  ];

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('wallet.transaction_history'.tr()),
        ),
        body: Center (
          child: Text('wallet.login_required_transactions'.tr()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('wallet.transaction_history'.tr(),
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // All filter chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('common.all'.tr()),
                      selected: _selectedFilter == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = null;
                        });
                      },
                      selectedColor: const Color(0xFF215C5C).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF215C5C),
                    ),
                  ),
                  // Type filter chips
                  ..._filterOptions.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type.displayName),
                        selected: _selectedFilter == type,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = selected ? type : null;
                          });
                        },
                        selectedColor: const Color(0xFF215C5C).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF215C5C),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Transaction List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Trigger a rebuild
                setState(() {});
              },
              child: StreamBuilder<List<WalletTransaction>>(
                stream: _walletService.streamTransactions(
                  _userId,
                  type: _selectedFilter,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: Text('common.retry'.tr()),
                          ),
                        ],
                      ),
                    );
                  }

                  final transactions = snapshot.data ?? [];

                  if (transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == null
                                ? 'No transactions yet'
                                : 'No ${_selectedFilter!.displayName.toLowerCase()} transactions',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('common.your_transactions_will_appear_here'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction transaction) {
    // Determine icon and color based on transaction type
    IconData icon;
    Color iconColor;

    switch (transaction.type) {
      case WalletTransactionType.earning:
        icon = Icons.attach_money;
        iconColor = Colors.green;
        break;
      case WalletTransactionType.spending:
        icon = Icons.shopping_cart;
        iconColor = Colors.red;
        break;
      case WalletTransactionType.withdrawal:
        icon = Icons.account_balance;
        iconColor = Colors.orange;
        break;
      case WalletTransactionType.refund:
        icon = Icons.refresh;
        iconColor = Color(0xFF008080);
        break;
      case WalletTransactionType.hold:
        icon = Icons.lock_clock;
        iconColor = Colors.amber;
        break;
      case WalletTransactionType.release:
        icon = Icons.lock_open;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.swap_horiz;
        iconColor = Colors.grey;
    }

    // Format amount with sign
    final isPositive = transaction.isCredit;
    final amountStr =
        '${isPositive ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}';

    // Format date and time
    final date = transaction.timestamp;
    final now = DateTime.now();
    final diff = now.difference(date);

    String dateStr;
    if (diff.inDays == 0) {
      dateStr = 'Today';
    } else if (diff.inDays == 1) {
      dateStr = 'Yesterday';
    } else if (diff.inDays < 7) {
      dateStr = '${diff.inDays} days ago';
    } else {
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    // Status badge color
    Color statusColor;
    switch (transaction.status) {
      case WalletTransactionStatus.completed:
        statusColor = Colors.green;
        break;
      case WalletTransactionStatus.pending:
        statusColor = Colors.orange;
        break;
      case WalletTransactionStatus.failed:
        statusColor = Colors.red;
        break;
      case WalletTransactionStatus.cancelled:
        statusColor = Colors.grey;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                transaction.description,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                transaction.status.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '$dateStr at $timeStr',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            if (transaction.bookingId != null) ...[
              const SizedBox(height: 2),
              Text(
                'Booking: ${transaction.bookingId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (transaction.trackingId != null) ...[
              const SizedBox(height: 2),
              Text(
                'Tracking: ${transaction.trackingId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Text(
          amountStr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
