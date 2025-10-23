import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/models/delivery_tracking.dart';
import '../../services/tracking_service.dart';
import './delivery_feedback_screen.dart';

class SenderConfirmationScreen extends StatefulWidget {
  final DeliveryTracking tracking;

  const SenderConfirmationScreen({
    Key? key,
    required this.tracking,
  }) : super(key: key);

  @override
  State<SenderConfirmationScreen> createState() =>
      _SenderConfirmationScreenState();
}

class _SenderConfirmationScreenState extends State<SenderConfirmationScreen> {
  final TrackingService _trackingService = Get.find<TrackingService>();
  bool _isConfirming = false;

  Future<void> _confirmDelivery() async {
    try {
      setState(() => _isConfirming = true);

      await _trackingService.confirmDeliveryAsSender(
        trackingId: widget.tracking.id,
      );

      // Show success message
      Get.snackbar(
        '✅ Delivery Confirmed',
        'Payment has been released to the traveler',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );

      // Navigate to feedback screen
      Get.off(() => DeliveryFeedbackScreen(tracking: widget.tracking));
    } catch (e) {
      Get.snackbar(
        '❌ Error',
        'Failed to confirm delivery: $e',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() => _isConfirming = false);
    }
  }

  void _reportIssue() {
    // TODO: Implement dispute system navigation
    Get.snackbar(
      'Report Issue',
      'Dispute system will be available soon',
      backgroundColor: Colors.orange.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryTime = widget.tracking.deliveryTime ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(deliveryTime);
    final formattedTime = DateFormat('h:mm a').format(deliveryTime);
    final address =
        widget.tracking.currentLocation?.address ?? 'Location not available';

    return Scaffold(
      appBar: AppBar(
        title: Text('tracking.delivery_confirmation'.tr()),
        backgroundColor: const Color(0xFF6A5AE0),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Delivery Photo
            if (widget.tracking.deliveryPhotoUrl != null)
              Hero(
                tag: 'delivery_photo_${widget.tracking.id}',
                child: Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: CachedNetworkImage(
                    imageUrl: widget.tracking.deliveryPhotoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error, size: 50, color: Colors.red),
                    ),
                  ),
                ),
              ),

            // Delivery Details Card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'notifications.package_delivered'.tr(),
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Date and Time
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'wallet.transaction_date'.tr(),
                    value: formattedDate,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.access_time,
                    label: 'common.time'.tr(),
                    value: formattedTime,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'tracking.location'.tr(),
                    value: address,
                    valueMaxLines: 2,
                  ),

                  // Traveler's Note
                  if (widget.tracking.notes != null &&
                      widget.tracking.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      '📝 Traveler\'s Note:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.tracking.notes!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Confirm Delivery Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isConfirming ? null : _confirmDelivery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A5AE0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isConfirming
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'tracking.confirm_delivery'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Report Issue Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isConfirming ? null : _reportIssue,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFFF6B6B),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'tracking.report_issue'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B6B),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Info Text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF008080),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFF008080), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFF008080), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'common.by_confirming_delivery_you_agree_that_the_package_'
                                .tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF008080),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    int valueMaxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6A5AE0)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: valueMaxLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
