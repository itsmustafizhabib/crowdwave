import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/deal_offer.dart';
import '../../core/models/package_request.dart';
import '../../services/deal_negotiation_service.dart';
import '../../presentation/booking/booking_confirmation_screen.dart';

class OfferCardWidget extends StatefulWidget {
  final DealOffer offer;
  final bool isReceivedOffer; // true if current user received the offer
  final VoidCallback? onOfferUpdated;

  const OfferCardWidget({
    Key? key,
    required this.offer,
    required this.isReceivedOffer,
    this.onOfferUpdated,
  }) : super(key: key);

  @override
  State<OfferCardWidget> createState() => _OfferCardWidgetState();
}

class _OfferCardWidgetState extends State<OfferCardWidget> {
  final DealNegotiationService _dealService = DealNegotiationService();
  bool _isLoading = false;
  PackageRequest? _package;

  @override
  void initState() {
    super.initState();
    _loadRelatedData();
  }

  Future<void> _loadRelatedData() async {
    try {
      // Load package details
      final packageDoc = await FirebaseFirestore.instance
          .collection('packageRequests')
          .doc(widget.offer.packageId)
          .get();

      if (packageDoc.exists && mounted) {
        setState(() {
          _package = PackageRequest.fromJson(packageDoc.data()!);
        });
      }
    } catch (e) {
      debugPrint('Error loading package data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: _getGradientForStatus(widget.offer.status),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColorForStatus(widget.offer.status),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1),
          _buildContent(),
          if (_canShowActions()) ...[
            const Divider(height: 1),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    IconData icon;
    String title;
    Color iconColor = _getIconColorForStatus(widget.offer.status);

    switch (widget.offer.status) {
      case DealStatus.pending:
        icon = Icons.local_offer;
        title = widget.offer.isCounterOffer
            ? (widget.isReceivedOffer
                ? 'Counter Offer Received'
                : 'Counter Offer Sent')
            : (widget.isReceivedOffer ? 'New Offer Received' : 'Offer Sent');
        break;
      case DealStatus.accepted:
        icon = Icons.check_circle;
        title = 'Offer Accepted';
        break;
      case DealStatus.rejected:
        icon = Icons.cancel;
        title = 'Offer Declined';
        break;
      case DealStatus.expired:
        icon = Icons.timer_off;
        title = 'Offer Expired';
        break;
      case DealStatus.cancelled:
        icon = Icons.block;
        title = 'Offer Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _getTextColorForStatus(widget.offer.status),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isReceivedOffer
                      ? 'From: ${widget.offer.senderName}'
                      : 'To: ${widget.offer.travelerId}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          if (widget.offer.isExpired &&
              widget.offer.status == DealStatus.pending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'status.expired'.tr(),
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package Info
          if (_package != null) ...[
            _buildPackageInfo(),
            const SizedBox(height: 16),
          ],

          // Price Section
          Row(
            children: [
              Icon(Icons.monetization_on,
                  size: 20, color: const Color(0xFF215C5C)),
              const SizedBox(width: 8),
              Text(
                'Offer Amount:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '\$${widget.offer.offeredPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF215C5C),
                ),
              ),
            ],
          ),

          // Message if present
          if (widget.offer.message != null &&
              widget.offer.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.offer.message!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Status and Time
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getIconColorForStatus(widget.offer.status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(widget.offer.status),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _getIconColorForStatus(widget.offer.status),
                ),
              ),
              const Spacer(),
              Text(
                _formatTimestamp(widget.offer.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageInfo() {
    if (_package == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                'detail.package_detail_title'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.place, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${_package!.pickupLocation.city} → ${_package!.destinationLocation.city}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.category, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _package!.packageDetails.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _rejectDeal,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.close, size: 18),
              label: Text(
                'common.decline'.tr(),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _acceptDeal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(
                'matching.accept'.tr(),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canShowActions() {
    return widget.isReceivedOffer && widget.offer.canRespond && !_isLoading;
  }

  Future<void> _acceptDeal() async {
    setState(() => _isLoading = true);

    try {
      // Accept deal and get booking data
      final bookingData =
          await _dealService.acceptDealAndGetBookingData(widget.offer.id);

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
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
      );

      // Notify parent to refresh
      widget.onOfferUpdated?.call();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to accept offer: $e',
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
      await _dealService.rejectDeal(widget.offer.id);

      Get.snackbar(
        'Offer Declined',
        'You have declined the offer',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );

      // Notify parent to refresh
      widget.onOfferUpdated?.call();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to decline offer: $e',
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
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case DealStatus.accepted:
        return LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case DealStatus.rejected:
      case DealStatus.expired:
        return LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case DealStatus.cancelled:
        return LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getBorderColorForStatus(DealStatus status) {
    switch (status) {
      case DealStatus.pending:
        return Color(0xFF008080);
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
        return Color(0xFF008080)!;
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
        return Color(0xFF008080);
      case DealStatus.accepted:
        return Colors.green[900]!;
      case DealStatus.rejected:
      case DealStatus.expired:
        return Colors.red[900]!;
      case DealStatus.cancelled:
        return Colors.grey[800]!;
    }
  }

  String _getStatusText(DealStatus status) {
    switch (status) {
      case DealStatus.pending:
        return widget.offer.isExpired ? 'Expired' : 'Awaiting Response';
      case DealStatus.accepted:
        return 'Accepted ✓';
      case DealStatus.rejected:
        return 'Declined';
      case DealStatus.expired:
        return 'Expired';
      case DealStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
