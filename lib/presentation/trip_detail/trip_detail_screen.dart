import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_export.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/matching_service.dart';
import '../../controllers/chat_controller.dart';
import '../chat/individual_chat_screen.dart';
// import '../../models/review_model.dart';
// import '../../services/review_service.dart';
// import '../reviews/review_list_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final TravelTrip trip;

  const TripDetailScreen({
    Key? key,
    required this.trip,
  }) : super(key: key);

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isRequested = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _slideController.forward();
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTripOverview(),
                      SizedBox(height: 24),
                      _buildRouteSection(),
                      SizedBox(height: 24),
                      _buildTravelDetailsSection(),
                      SizedBox(height: 24),
                      _buildCapacitySection(),
                      SizedBox(height: 24),
                      _buildEarningsSection(),
                      SizedBox(height: 24),
                      _buildAcceptedItemsSection(),
                      if (widget.trip.notes?.isNotEmpty == true) ...[
                        SizedBox(height: 24),
                        _buildNotesSection(),
                      ],
                      // SizedBox(height: 24),
                      // _buildReviewsSection(),
                      SizedBox(height: 100), // Space for FAB
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF215C5C),
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'detail.trip_detail_title'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildTripOverview() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFF215C5C).withOpacity(0.1),
                backgroundImage: widget.trip.travelerPhotoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(widget.trip.travelerPhotoUrl)
                    : null,
                child: widget.trip.travelerPhotoUrl.isEmpty
                    ? Icon(Icons.person, color: Color(0xFF215C5C))
                    : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.trip.travelerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'detail.traveler'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(
                _getTransportModeIcon(widget.trip.transportMode),
                color: Color(0xFF215C5C),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                _getTransportModeText(widget.trip.transportMode),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Spacer(),
              if (widget.trip.totalPackagesAccepted > 0) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.trip.totalPackagesAccepted} packages',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color statusColor;
    String statusText;

    switch (widget.trip.status) {
      case TripStatus.active:
        statusColor = Colors.green;
        statusText = 'Active';
        break;
      case TripStatus.full:
        statusColor = Colors.orange;
        statusText = 'Full';
        break;
      case TripStatus.inProgress:
        statusColor = Color(0xFF008080);
        statusText = 'In Progress';
        break;
      case TripStatus.completed:
        statusColor = Colors.green[700]!;
        statusText = 'Completed';
        break;
      case TripStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildRouteSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route & Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildLocationItem(
            icon: Icons.flight_takeoff,
            label: 'detail.departure'.tr(),
            location: widget.trip.departureLocation,
            datetime: widget.trip.departureDate,
            color: Color(0xFF215C5C),
          ),
          SizedBox(height: 16),
          Container(
            margin: EdgeInsets.only(left: 12),
            height: 30,
            width: 2,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          SizedBox(height: 16),
          _buildLocationItem(
            icon: Icons.flight_land,
            label: 'detail.arrival'.tr(),
            location: widget.trip.destinationLocation,
            datetime: widget.trip.arrivalDate,
            color: Colors.green,
          ),
          if (widget.trip.isFlexibleRoute &&
              widget.trip.maxDetourKm != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF008080).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF008080).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.alt_route, color: Color(0xFF008080), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Flexible route up to ${widget.trip.maxDetourKm} km detour',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF008080),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required String label,
    required Location location,
    DateTime? datetime,
    required Color color,
  }) {
    final formatter = DateFormat('MMM dd • hh:mm a');

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                location.address,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              if (location.city != null) ...[
                SizedBox(height: 2),
                Text(
                  '${location.city}, ${location.state}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (datetime != null) ...[
                SizedBox(height: 4),
                Text(
                  formatter.format(datetime),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTravelDetailsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'travel.travel_details'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow(
              'Transport', _getTransportModeText(widget.trip.transportMode)),
          _buildDetailRow('Departure',
              DateFormat('MMM dd, yyyy').format(widget.trip.departureDate)),
          if (widget.trip.arrivalDate != null)
            _buildDetailRow('Arrival',
                DateFormat('MMM dd, yyyy').format(widget.trip.arrivalDate!)),
          if (widget.trip.isFlexibleRoute)
            _buildDetailRow('Route', 'Flexible route available'),
        ],
      ),
    );
  }

  Widget _buildCapacitySection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'common.available_capacity'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCapacityItem(
                  icon: Icons.scale,
                  label: 'detail.package_weight'.tr(),
                  value: '${widget.trip.capacity.maxWeightKg} kg',
                  color: Color(0xFF008080),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCapacityItem(
                  icon: Icons.inventory_2,
                  label: 'trip.packages_label'.tr(),
                  value: '${widget.trip.capacity.maxPackages}',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildDetailRow(
              'Max Volume', '${widget.trip.capacity.maxVolumeLiters} L'),
          if (widget.trip.capacity.acceptedSizes.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'common.accepted_sizes'.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.trip.capacity.acceptedSizes.map((size) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF215C5C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Color(0xFF215C5C).withOpacity(0.3)),
                  ),
                  child: Text(
                    _getPackageSizeText(size),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF215C5C),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCapacityItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.earnings'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF215C5C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.attach_money,
                  color: Color(0xFF215C5C),
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '€${widget.trip.suggestedReward.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF215C5C),
                    ),
                  ),
                  Text(
                    'post_package.suggested_reward_per_package'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (widget.trip.totalEarnings > 0) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Total earned: \$${widget.trip.totalEarnings.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAcceptedItemsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'post_trip.accepted_types'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          if (widget.trip.acceptedItemTypes.isEmpty) ...[
            Text(
              'common.all_item_types_accepted'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.trip.acceptedItemTypes.map((type) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getPackageTypeText(type),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'common.additional_notes'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Text(
            widget.trip.notes!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
            maxLines: null,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildReviewsSection() {
  //   return Container(
  //     width: double.infinity,
  //     padding: EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 10,
  //           offset: Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(
  //               Icons.star_rate,
  //               color: Color(0xFF215C5C),
  //               size: 24,
  //             ),
  //             SizedBox(width: 12),
  //             Text(
  //               'Reviews & Ratings',
  //               style: TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.w700,
  //                 color: Colors.grey[800],
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 16),
  //
  //         // Rating Summary
  //         FutureBuilder<ReviewSummary>(
  //           future: ReviewService().getReviewSummary(widget.trip.id),
  //           builder: (context, snapshot) {
  //             if (snapshot.connectionState == ConnectionState.waiting) {
  //               return Center(
  //                 child: SizedBox(
  //                   height: 40,
  //                   child: CircularProgressIndicator(
  //                     strokeWidth: 2,
  //                     color: Color(0xFF215C5C),
  //                   ),
  //                 ),
  //               );
  //             }
  //
  //             if (snapshot.hasError || !snapshot.hasData) {
  //               return Container(
  //                 padding: EdgeInsets.all(16),
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey[50],
  //                   borderRadius: BorderRadius.circular(12),
  //                   border: Border.all(color: Colors.grey[200]!),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Icon(Icons.star_border, color: Colors.grey[400]),
  //                     SizedBox(width: 8),
  //                     Text(
  //                       'no reviews',
  //                       style: TextStyle(
  //                         color: Colors.grey[600],
  //                         fontSize: 14,
  //                       ),
  //                     ),
  //                     Spacer(),
  //                   ],
  //                 ),
  //               );
  //             }
  //
  //             final summary = snapshot.data!;
  //
  //             if (summary.totalReviews == 0) {
  //               return Container(
  //                 padding: EdgeInsets.all(16),
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey[50],
  //                   borderRadius: BorderRadius.circular(12),
  //                   border: Border.all(color: Colors.grey[200]!),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Icon(Icons.star_border, color: Colors.grey[400]),
  //                     SizedBox(width: 8),
  //                     Text(
  //                       'no reviews',
  //                       style: TextStyle(
  //                         color: Colors.grey[600],
  //                         fontSize: 14,
  //                       ),
  //                     ),
  //                     Spacer(),
  //                   ],
  //                 ),
  //               );
  //             }
  //
  //             return Column(
  //               children: [
  //                 // Compact Rating Display
  //                 Row(
  //                   children: [
  //                     Icon(
  //                       Icons.star,
  //                       color: Color(0xFF2D7A6E),
  //                       size: 20,
  //                     ),
  //                     SizedBox(width: 6),
  //                     Text(
  //                       summary.averageRating.toStringAsFixed(1),
  //                       style: TextStyle(
  //                         fontSize: 16,
  //                         fontWeight: FontWeight.w600,
  //                         color: Colors.grey[800],
  //                       ),
  //                     ),
  //                     SizedBox(width: 6),
  //                     Text(
  //                       '(${summary.totalReviews} reviews)',
  //                       style: TextStyle(
  //                         fontSize: 14,
  //                         color: Colors.grey[600],
  //                       ),
  //                     ),
  //                     Spacer(),
  //                     Icon(
  //                       Icons.chevron_right,
  //                       color: Colors.grey[400],
  //                     ),
  //                   ],
  //                 ),
  //
  //                 if (summary.verifiedReviewsCount > 0) ...[
  //                   SizedBox(height: 8),
  //                   Row(
  //                     children: [
  //                       Container(
  //                         padding:
  //                             EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  //                         decoration: BoxDecoration(
  //                           color: Colors.green[100],
  //                           borderRadius: BorderRadius.circular(10),
  //                         ),
  //                         child: Text(
  //                           '${summary.verifiedReviewsCount} verified',
  //                           style: TextStyle(
  //                             fontSize: 11,
  //                             color: Colors.green[700],
  //                             fontWeight: FontWeight.w500,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ],
  //             );
  //           },
  //         ),
  //
  //         SizedBox(height: 16),
  //
  //         // Action Button
  //         Center(
  //           child: ElevatedButton.icon(
  //             onPressed: _navigateToReviewList,
  //             icon: Icon(Icons.list, size: 18),
  //             label: Text('reviews.view_all_reviews'.tr()),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Color(0xFF215C5C),
  //               foregroundColor: Colors.white,
  //               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // void _navigateToReviewList() {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (context) => ReviewListScreen(
  //         targetId: widget.trip.id,
  //         reviewType: ReviewType.trip,
  //         targetName: '${widget.trip.fromLocation} → ${widget.trip.toLocation}',
  //       ),
  //     ),
  //   );
  // }

  Widget _buildActionButton() {
    // Debug logging to check values
    final currentUserId = _authService.currentUser?.uid;
    final travelerId = widget.trip.travelerId;

    print('=== TRIP DETAIL DEBUG ===');
    print('Current User ID: $currentUserId');
    print('Traveler ID: $travelerId');
    print('Are they equal? ${currentUserId == travelerId}');
    print('========================');

    // Don't show button if user is the traveler
    if (currentUserId == travelerId) {
      print('HIDING BUTTONS: User is the trip owner');
      return SizedBox.shrink();
    }

    // Don't show button if trip is not active
    if (widget.trip.status != TripStatus.active) {
      print('HIDING BUTTONS: Trip is not active');
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Chat Button
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: "chat_button_${widget.trip.id}",
              onPressed: _startChatWithTraveler,
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
              elevation: 6,
              icon: Icon(Icons.chat_bubble_outline),
              label: Text(
                'nav.chat'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          // Match Request Button
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: "match_button_${widget.trip.id}",
              onPressed: _isLoading ? null : _handleMatchRequest,
              backgroundColor: _isRequested ? Colors.green : Color(0xFF215C5C),
              foregroundColor: Colors.white,
              elevation: 6,
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(_isRequested ? Icons.check : Icons.local_shipping),
              label: Text(
                _isRequested ? 'Request Sent' : 'Request Match',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMatchRequest() async {
    if (_isRequested) return;

    setState(() {
      _isLoading = true;
    });

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    try {
      // Implement actual matching logic
      final matchingService = MatchingService();
      final currentUserId = FirebaseAuthService().currentUser?.uid;

      if (currentUserId == null) {
        throw Exception('You must be logged in to request matches');
      }

      // Create a match request by finding this specific trip as a match
      await _createMatchRequest(matchingService, currentUserId);

      // Pre-create conversation for seamless chat experience
      try {
        late ChatController chatController;
        if (Get.isRegistered<ChatController>()) {
          chatController = Get.find<ChatController>();
        } else {
          chatController = Get.put(ChatController());
        }

        // Create conversation linked to this trip
        await chatController.createOrGetConversation(
          otherUserId: widget.trip.travelerId,
          otherUserName: widget.trip.travelerName,
          otherUserAvatar: widget.trip.travelerPhotoUrl.isNotEmpty
              ? widget.trip.travelerPhotoUrl
              : null,
          packageRequestId:
              widget.trip.id, // Link the conversation to this trip
        );
      } catch (e) {
        // Don't fail the match request if chat creation fails
        print('Failed to pre-create conversation: $e');
      }

      setState(() {
        _isRequested = true;
        _isLoading = false;
      });

      // Show success feedback with chat option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('matching.request_sent'.tr(args: [widget.trip.travelerName])),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'detail.chat_now'.tr(),
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _startChatWithTraveler();
            },
          ),
          duration: Duration(seconds: 5),
        ),
      );

      // Also show a dialog for better visibility
      Future.delayed(Duration(milliseconds: 1500), () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    SizedBox(width: 12),
                    Text('detail.request_sent'.tr()),
                  ],
                ),
                content: Text(
                  'Your match request has been sent to ${widget.trip.travelerName}. Would you like to start chatting now?',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('home.later'.tr()),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _startChatWithTraveler();
                    },
                    icon: Icon(Icons.chat_bubble_outline),
                    label: Text('chat.start_chat'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF215C5C),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              );
            },
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('detail.request_failed'.tr()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _startChatWithTraveler() async {
    try {
      // Get or initialize ChatController
      late ChatController chatController;
      if (Get.isRegistered<ChatController>()) {
        chatController = Get.find<ChatController>();
      } else {
        chatController = Get.put(ChatController());
      }

      // Create or get conversation with traveler
      final conversationId = await chatController.createOrGetConversation(
        otherUserId: widget.trip.travelerId,
        otherUserName: widget.trip.travelerName,
        otherUserAvatar: widget.trip.travelerPhotoUrl.isNotEmpty
            ? widget.trip.travelerPhotoUrl
            : null,
        packageRequestId: null, // This is for a trip, not a specific package
      );

      if (conversationId != null) {
        // Navigate to individual chat screen
        Get.to(() => IndividualChatScreen(
              conversationId: conversationId,
              otherUserName: widget.trip.travelerName,
              otherUserId: widget.trip.travelerId,
              otherUserAvatar: widget.trip.travelerPhotoUrl.isNotEmpty
                  ? widget.trip.travelerPhotoUrl
                  : null,
            ));
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('chat.start_failed'.tr()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('chat.start_failed'.tr(args: [e.toString()])),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  IconData _getTransportModeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.flight:
        return Icons.flight;
      case TransportMode.train:
        return Icons.train;
      case TransportMode.bus:
        return Icons.directions_bus;
      case TransportMode.car:
        return Icons.directions_car;
      case TransportMode.motorcycle:
        return Icons.motorcycle;
      case TransportMode.bicycle:
        return Icons.pedal_bike;
      case TransportMode.walking:
        return Icons.directions_walk;
      case TransportMode.ship:
        return Icons.directions_boat;
    }
  }

  String _getTransportModeText(TransportMode mode) {
    switch (mode) {
      case TransportMode.flight:
        return 'Flight';
      case TransportMode.train:
        return 'Train';
      case TransportMode.bus:
        return 'Bus';
      case TransportMode.car:
        return 'Car';
      case TransportMode.motorcycle:
        return 'Motorcycle';
      case TransportMode.bicycle:
        return 'Bicycle';
      case TransportMode.walking:
        return 'Walking';
      case TransportMode.ship:
        return 'Ship';
    }
  }

  String _getPackageTypeText(PackageType type) {
    switch (type) {
      case PackageType.documents:
        return 'Documents';
      case PackageType.electronics:
        return 'Electronics';
      case PackageType.clothing:
        return 'Clothing';
      case PackageType.food:
        return 'Food';
      case PackageType.medicine:
        return 'Medicine';
      case PackageType.gifts:
        return 'Gifts';
      case PackageType.books:
        return 'Books';
      case PackageType.cosmetics:
        return 'Cosmetics';
      case PackageType.other:
        return 'Other';
    }
  }

  String _getPackageSizeText(PackageSize size) {
    switch (size) {
      case PackageSize.small:
        return 'Small';
      case PackageSize.medium:
        return 'Medium';
      case PackageSize.large:
        return 'Large';
      case PackageSize.extraLarge:
        return 'XL';
    }
  }

  /// Create a match request for this trip
  Future<void> _createMatchRequest(
      MatchingService matchingService, String currentUserId) async {
    try {
      // For now, we'll create a simple match record indicating user interest
      // In a full implementation, this might create a package request first
      // or directly notify the traveler of interest

      final matchData = {
        'tripId': widget.trip.id,
        'travelerId': widget.trip.travelerId,
        'interestedUserId': currentUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'matchScore': 75.0, // Default score for manual requests
        'requestType': 'manual', // Manual vs automatic matching
        'tripDetails': {
          'origin': widget.trip.fromLocation,
          'destination': widget.trip.toLocation,
          'departureTime': widget.trip.departureDate.toIso8601String(),
          'availableSpace': widget.trip.availableSpace,
          'maxWeightKg': widget.trip.capacity.maxWeightKg,
        },
      };

      // Save to Firestore matches collection
      await FirebaseFirestore.instance.collection('matches').add(matchData);

      // Create notification for the traveler
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': widget.trip.travelerId,
        'type': 'match_request',
        'title': 'New Match Request',
        'message':
            'Someone is interested in your trip from ${widget.trip.fromLocation} to ${widget.trip.toLocation}',
        'data': {
          'tripId': widget.trip.id,
          'matchId': 'pending', // Will be updated with actual match ID
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Match request created successfully for trip: ${widget.trip.id}');
    } catch (e) {
      print('Failed to create match request: $e');
      throw Exception('Failed to send match request: $e');
    }
  }
}
