import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/models/deal_offer.dart';
import '../../core/models/package_request.dart';
import '../../core/models/travel_trip.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 📋 Booking Summary Widget - Shows complete booking details
class BookingSummaryWidget extends StatelessWidget {
  final DealOffer deal;
  final PackageRequest package;
  final TravelTrip trip;

  const BookingSummaryWidget({
    Key? key,
    required this.deal,
    required this.package,
    required this.trip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text('booking.booking_summary'.tr(),
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Deal Information
          _buildSection(
            title: 'booking.deal_details'.tr(),
            icon: Icons.handshake_outlined,
            children: [
              _buildDetailRow(
                  'Offered Price', '€${deal.offeredPrice.toStringAsFixed(2)}'),
              _buildDetailRow('Deal Status', deal.status.name.toUpperCase()),
              if (deal.message?.isNotEmpty ?? false)
                _buildDetailRow('Message', deal.message!, isMultiline: true),
            ],
          ),

          const SizedBox(height: 16),

          // Package Information
          _buildSection(
            title: 'detail.package_detail_title'.tr(),
            icon: Icons.inventory_2_outlined,
            children: [
              _buildDetailRow('From', package.pickupLocation.address),
              _buildDetailRow('To', package.destinationLocation.address),
              _buildDetailRow('Package Type', package.packageDetails.type.name),
              _buildDetailRow(
                  'Weight', '${package.packageDetails.weightKg} kg'),
              _buildDetailRow('Size', package.packageDetails.size.name),
              if (package.specialInstructions?.isNotEmpty ?? false)
                _buildDetailRow('Instructions', package.specialInstructions!,
                    isMultiline: true),
              _buildDetailRow('Preferred Delivery',
                  _formatDate(package.preferredDeliveryDate)),
            ],
          ),

          const SizedBox(height: 16),

          // Trip Information
          _buildSection(
            title: 'detail.trip_detail_title'.tr(),
            icon: Icons.flight_outlined,
            children: [
              _buildDetailRow('Route',
                  '${trip.departureLocation.city ?? trip.departureLocation.country} → ${trip.destinationLocation.city ?? trip.destinationLocation.country}'),
              _buildDetailRow('Departure', _formatDateTime(trip.departureDate)),
              if (trip.arrivalDate != null)
                _buildDetailRow('Arrival', _formatDateTime(trip.arrivalDate!)),
              _buildDetailRow(
                  'Available Space', '${trip.capacity.maxWeightKg} kg'),
              if (trip.notes?.isNotEmpty ?? false)
                _buildDetailRow('Trip Notes', trip.notes!, isMultiline: true),
            ],
          ),

          const SizedBox(height: 16),

          // Price Breakdown
          _buildSection(
            title: 'booking.price_breakdown'.tr(),
            icon: Icons.calculate_outlined,
            children: [
              _buildDetailRow(
                  'Service Fee', '€${deal.offeredPrice.toStringAsFixed(2)}'),
              _buildDetailRow('Platform Fee (10%)',
                  '€${(deal.offeredPrice * 0.1).toStringAsFixed(2)}'),
              const Divider(),
              _buildDetailRow(
                'Total Amount',
                '€${(deal.offeredPrice + (deal.offeredPrice * 0.1)).toStringAsFixed(2)}',
                isTotal: true,
              ),
              _buildDetailRow(
                'Traveler Receives',
                '€${(deal.offeredPrice * 0.9).toStringAsFixed(2)}',
                textColor: AppColors.success,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Important Notes
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 16),
                    const SizedBox(width: 8),
                    Text('common.important_information'.tr(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Payment will be held in escrow until delivery confirmation\n'
                  '• Contact details will be shared after payment\n'
                  '• Please read and agree to the terms before proceeding',
                  style: AppTextStyles.caption.copyWith(color: AppColors.info),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a section with title and children
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.subtitle1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  /// Build a detail row
  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMultiline = false,
    bool isTotal = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.body2.copyWith(
                color: textColor ??
                    (isTotal ? AppColors.primary : AppColors.textPrimary),
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format date time
  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
