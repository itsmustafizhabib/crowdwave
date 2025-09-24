import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/models/deal_offer.dart';
import '../../core/models/chat_message.dart';
import '../../services/deal_negotiation_service.dart';
import '../../presentation/booking/booking_confirmation_screen.dart';
import 'price_input_widget.dart';

class DealOfferMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final String currentUserId;

  const DealOfferMessageWidget({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<DealOfferMessageWidget> createState() => _DealOfferMessageWidgetState();
}

class _DealOfferMessageWidgetState extends State<DealOfferMessageWidget> {
  final DealNegotiationService _dealService = DealNegotiationService();
  bool _isLoading = false;
  DealOffer? _dealOffer;

  @override
  void initState() {
    super.initState();
    _loadDealOffer();
  }

  Future<void> _loadDealOffer() async {
    final dealOfferId = widget.message.metadata?['dealOfferId'];
    if (dealOfferId != null) {
      final deal = await _dealService.getDealOffer(dealOfferId);
      if (mounted) {
        setState(() {
          _dealOffer = deal;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dealOffer == null) {
      return _buildLoadingWidget();
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: widget.isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              decoration: BoxDecoration(
                gradient: _getGradientForStatus(_dealOffer!.status),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getBorderColorForStatus(_dealOffer!.status),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  SizedBox(height: 8),
                  _buildPriceSection(),
                  if (_dealOffer!.message != null) ...[
                    SizedBox(height: 8),
                    _buildMessageSection(),
                  ],
                  SizedBox(height: 12),
                  _buildStatusSection(),
                  if (_canShowActions()) ...[
                    SizedBox(height: 12),
                    _buildActionButtons(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: widget.isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Loading offer...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    IconData icon;
    String title;

    switch (widget.message.type) {
      case MessageType.deal_offer:
        icon = Icons.local_offer;
        title = _dealOffer!.isCounterOffer ? 'Counter Offer' : 'Price Offer';
        break;
      case MessageType.deal_accepted:
        icon = Icons.check_circle;
        title = 'Deal Accepted';
        break;
      case MessageType.deal_rejected:
        icon = Icons.cancel;
        title = 'Offer Declined';
        break;
      default:
        icon = Icons.handshake;
        title = 'Deal Update';
    }

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: _getIconColorForStatus(_dealOffer!.status),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _getTextColorForStatus(_dealOffer!.status),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_dealOffer!.isExpired) ...[
          SizedBox(width: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'EXPIRED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_money,
            color: Color(0xFF0046FF),
            size: 20,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              '\$${_dealOffer!.offeredPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0046FF),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 4),
          Text(
            'Delivery Fee',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _dealOffer!.message!,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    String statusText;
    Color statusColor;

    switch (_dealOffer!.status) {
      case DealStatus.pending:
        statusText = _dealOffer!.isExpired ? 'Expired' : 'Waiting for response';
        statusColor = _dealOffer!.isExpired ? Colors.red : Colors.orange;
        break;
      case DealStatus.accepted:
        statusText = 'Accepted ✓';
        statusColor = Colors.green;
        break;
      case DealStatus.rejected:
        statusText = 'Declined';
        statusColor = Colors.red;
        break;
      case DealStatus.expired:
        statusText = 'Expired';
        statusColor = Colors.red;
        break;
      case DealStatus.cancelled:
        statusText = 'Cancelled';
        statusColor = Colors.grey;
        break;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: statusColor,
          ),
        ),
        Spacer(),
        Text(
          _formatTimestamp(_dealOffer!.createdAt),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_dealOffer!.senderId == widget.currentUserId) {
      // Current user sent this offer
      return _buildSenderActions();
    } else {
      // Current user received this offer
      return _buildReceiverActions();
    }
  }

  Widget _buildSenderActions() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Waiting for response...',
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildReceiverActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _acceptDeal(),
                icon: Icon(Icons.check, size: 14),
                label: Text(
                  'Accept',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  minimumSize: Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(width: 6),
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _rejectDeal(),
                icon: Icon(Icons.close, size: 14),
                label: Text(
                  'Decline',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  minimumSize: Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        // SizedBox(height: 8),
        // SizedBox(
        //   width: double.infinity,
        //   child: OutlinedButton.icon(
        //     onPressed: _isLoading ? null : () => _showCounterOfferDialog(),
        //     icon: Icon(Icons.reply, size: 14),
        //     label: Text(
        //       'Counter Offer',
        //       style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        //       overflow: TextOverflow.ellipsis,
        //     ),
        //     style: OutlinedButton.styleFrom(
        //       foregroundColor: Color(0xFF0046FF),
        //       padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        //       minimumSize: Size(0, 32),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(8),
        //       ),
        //       side: BorderSide(color: Color(0xFF0046FF)),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  bool _canShowActions() {
    return _dealOffer!.canRespond &&
        _dealOffer!.senderId != widget.currentUserId &&
        !_isLoading;
  }

  Future<void> _acceptDeal() async {
    setState(() => _isLoading = true);

    try {
      // Accept deal and get booking data
      final bookingData =
          await _dealService.acceptDealAndGetBookingData(_dealOffer!.id);

      // Navigate to booking confirmation screen
      Get.to(() => BookingConfirmationScreen(
            acceptedDeal: bookingData['dealOffer'],
            package: bookingData['package'],
            trip: bookingData['trip'],
          ));

      // Show success message
      Get.snackbar(
        'Deal Accepted!',
        'Proceeding to booking confirmation...',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        icon: Icon(Icons.check_circle, color: Colors.white),
        duration: Duration(seconds: 2),
      );

      // Reload deal to update UI
      await _loadDealOffer();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to accept deal: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectDeal() async {
    setState(() => _isLoading = true);

    try {
      await _dealService.rejectDeal(_dealOffer!.id);

      Get.snackbar(
        'Offer Declined',
        'You have declined the offer',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );

      // Reload deal to update UI
      await _loadDealOffer();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to decline deal: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCounterOfferDialog() {
    showDialog(
      context: context,
      builder: (context) => PriceInputWidget(
        title: 'Counter Offer',
        subtitle:
            'Their offer: \$${_dealOffer!.offeredPrice.toStringAsFixed(2)}',
        initialPrice: _dealOffer!.offeredPrice,
        onSubmit: (price, message) async {
          Navigator.pop(context);
          await _sendCounterOffer(price, message);
        },
      ),
    );
  }

  Future<void> _sendCounterOffer(double price, String? message) async {
    setState(() => _isLoading = true);

    try {
      await _dealService.sendCounterOffer(
        originalOfferId: _dealOffer!.id,
        counterPrice: price,
        message: message,
      );

      Get.snackbar(
        'Counter Offer Sent',
        'Your counter offer of \$${price.toStringAsFixed(2)} has been sent',
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
        icon: Icon(Icons.reply, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send counter offer: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Style helper methods
  LinearGradient _getGradientForStatus(DealStatus status) {
    switch (status) {
      case DealStatus.pending:
        return LinearGradient(
          colors: [Colors.blue[100]!, Colors.blue[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case DealStatus.accepted:
        return LinearGradient(
          colors: [Colors.green[100]!, Colors.green[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case DealStatus.rejected:
      case DealStatus.expired:
        return LinearGradient(
          colors: [Colors.red[100]!, Colors.red[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case DealStatus.cancelled:
        return LinearGradient(
          colors: [Colors.grey[200]!, Colors.grey[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getBorderColorForStatus(DealStatus status) {
    switch (status) {
      case DealStatus.pending:
        return Colors.blue[300]!;
      case DealStatus.accepted:
        return Colors.green[300]!;
      case DealStatus.rejected:
      case DealStatus.expired:
        return Colors.red[300]!;
      case DealStatus.cancelled:
        return Colors.grey[400]!;
    }
  }

  Color _getIconColorForStatus(DealStatus status) {
    switch (status) {
      case DealStatus.pending:
        return Colors.blue[600]!;
      case DealStatus.accepted:
        return Colors.green[600]!;
      case DealStatus.rejected:
      case DealStatus.expired:
        return Colors.red[600]!;
      case DealStatus.cancelled:
        return Colors.grey[600]!;
    }
  }

  Color _getTextColorForStatus(DealStatus status) {
    switch (status) {
      case DealStatus.pending:
        return Colors.blue[800]!;
      case DealStatus.accepted:
        return Colors.green[800]!;
      case DealStatus.rejected:
      case DealStatus.expired:
        return Colors.red[800]!;
      case DealStatus.cancelled:
        return Colors.grey[800]!;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
