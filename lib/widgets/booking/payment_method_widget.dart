import 'package:flutter/material.dart';
import '../../core/models/transaction.dart';
import '../../core/theme/app_colors.dart';

/// Widget for displaying and selecting a payment method
class PaymentMethodWidget extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback? onSelected;

  const PaymentMethodWidget({
    Key? key,
    required this.method,
    required this.isSelected,
    this.isAvailable = true,
    this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAvailable ? onSelected : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getMethodColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getMethodIcon(),
                color: _getMethodColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMethodTitle(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? null : Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getMethodDescription(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isAvailable ? Colors.grey.shade600 : Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            if (!isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Coming Soon',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon() {
    switch (method) {
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.payment;
      case PaymentMethod.applePay:
        return Icons.apple;
      case PaymentMethod.googlePay:
        return Icons.payment;
      case PaymentMethod.paypal:
        return Icons.account_balance_wallet;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
    }
  }

  Color _getMethodColor() {
    switch (method) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return Colors.blue;
      case PaymentMethod.applePay:
        return Colors.black;
      case PaymentMethod.googlePay:
        return Colors.green;
      case PaymentMethod.paypal:
        return Colors.blue.shade700;
      case PaymentMethod.bankTransfer:
        return Colors.purple;
    }
  }

  String _getMethodTitle() {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  String _getMethodDescription() {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Pay securely with your credit card';
      case PaymentMethod.debitCard:
        return 'Pay directly from your bank account';
      case PaymentMethod.applePay:
        return 'Quick and secure payment with Touch ID';
      case PaymentMethod.googlePay:
        return 'Fast checkout with your Google account';
      case PaymentMethod.paypal:
        return 'Pay with your PayPal account';
      case PaymentMethod.bankTransfer:
        return 'Direct bank transfer payment';
    }
  }
}
