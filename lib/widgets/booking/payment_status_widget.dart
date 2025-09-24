import 'package:flutter/material.dart';

/// Payment status widget for displaying processing, success, and failure states
class PaymentStatusWidget extends StatelessWidget {
  final PaymentStatus status;
  final String? message;

  const PaymentStatusWidget({
    Key? key,
    required this.status,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(),
              size: 40,
              color: _getStatusColor(),
            ),
          ),

          const SizedBox(height: 24),

          // Status Title
          Text(
            _getStatusTitle(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Status Message
          if (message != null)
            Text(
              message!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case PaymentStatus.processing:
        return Colors.orange;
      case PaymentStatus.success:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case PaymentStatus.processing:
        return Icons.hourglass_empty;
      case PaymentStatus.success:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
    }
  }

  String _getStatusTitle() {
    switch (status) {
      case PaymentStatus.processing:
        return 'Processing Payment';
      case PaymentStatus.success:
        return 'Payment Successful!';
      case PaymentStatus.failed:
        return 'Payment Failed';
    }
  }
}

/// Payment status enum for UI states
enum PaymentStatus {
  processing,
  success,
  failed,
}
