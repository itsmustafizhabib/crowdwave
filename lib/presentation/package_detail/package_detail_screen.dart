import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart' hide Trans;

import '../../core/app_export.dart';
import '../../services/firebase_auth_service.dart';
// import '../../services/booking_service.dart';
import '../../controllers/chat_controller.dart';
import '../chat/individual_chat_screen.dart';
import '../booking/make_offer_screen.dart';
// import '../../models/review_model.dart';
// import '../../services/review_service.dart';
import '../../widgets/enhanced_snackbar.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// import '../reviews/review_list_screen.dart';
// import '../reviews/create_review_screen.dart';

class PackageDetailScreen extends StatefulWidget {
  final PackageRequest package;

  const PackageDetailScreen({
    Key? key,
    required this.package,
  }) : super(key: key);

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final FirebaseAuthService _authService = FirebaseAuthService();
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
                      _buildPackageOverview(),
                      SizedBox(height: 24),
                      _buildLocationSection(),
                      SizedBox(height: 24),
                      _buildPackageDetailsSection(),
                      SizedBox(height: 24),
                      _buildDeliveryPreferences(),
                      SizedBox(height: 24),
                      _buildCompensationSection(),
                      if (widget.package.photoUrls.isNotEmpty) ...[
                        SizedBox(height: 24),
                        _buildPhotosSection(),
                      ],
                      if (widget.package.specialInstructions?.isNotEmpty ==
                          true) ...[
                        SizedBox(height: 24),
                        _buildSpecialInstructions(),
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
          'detail.package_detail_title'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildPackageOverview() {
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
                backgroundImage: widget.package.senderPhotoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(widget.package.senderPhotoUrl)
                    : null,
                child: widget.package.senderPhotoUrl.isEmpty
                    ? Icon(Icons.person, color: Color(0xFF215C5C))
                    : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.package.senderName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'post_package.package_sender'.tr(),
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
          Text(
            'common.description'.tr(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.package.packageDetails.description,
            style: TextStyle(
              fontSize: 16,
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

  Widget _buildStatusChip() {
    Color statusColor;
    String statusText;

    switch (widget.package.status) {
      case PackageStatus.pending:
        statusColor = Colors.amber;
        statusText = 'Pending';
        break;
      case PackageStatus.matched:
        statusColor = Color(0xFF008080);
        statusText = 'Matched';
        break;
      case PackageStatus.confirmed:
        statusColor = Colors.green;
        statusText = 'Confirmed';
        break;
      case PackageStatus.delivered:
        statusColor = Colors.green[700]!;
        statusText = 'Delivered';
        break;
      case PackageStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
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

  Widget _buildLocationSection() {
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
            'detail.route'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildLocationItem(
            icon: Icons.location_on,
            label: 'package.pickup'.tr(),
            location: widget.package.pickupLocation,
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
            icon: Icons.flag,
            label: 'package.destination'.tr(),
            location: widget.package.destinationLocation,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required String label,
    required Location location,
    required Color color,
  }) {
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageDetailsSection() {
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
            'detail.package_detail_title'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow(
              'Type', _getPackageTypeText(widget.package.packageDetails.type)),
          _buildDetailRow(
              'Size', _getPackageSizeText(widget.package.packageDetails.size)),
          _buildDetailRow(
              'Weight', '${widget.package.packageDetails.weightKg} kg'),
          if (widget.package.packageDetails.valueUSD != null)
            _buildDetailRow('Value',
                '€${widget.package.packageDetails.valueUSD!.toStringAsFixed(2)}'),
          if (widget.package.packageDetails.brand?.isNotEmpty == true)
            _buildDetailRow('Brand', widget.package.packageDetails.brand!),
          if (widget.package.packageDetails.isFragile ||
              widget.package.packageDetails.isPerishable ||
              widget.package.packageDetails.requiresRefrigeration) ...[
            SizedBox(height: 12),
            Text(
              'common.special_requirements'.tr(),
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
              children: [
                if (widget.package.packageDetails.isFragile)
                  _buildRequirementChip('Fragile', Icons.warning, Colors.amber),
                if (widget.package.packageDetails.isPerishable)
                  _buildRequirementChip(
                      'Perishable', Icons.schedule, Colors.red),
                if (widget.package.packageDetails.requiresRefrigeration)
                  _buildRequirementChip(
                      'Refrigeration', Icons.ac_unit, Color(0xFF008080)),
              ],
            ),
          ],
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

  Widget _buildRequirementChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPreferences() {
    final formatter = DateFormat('MMM dd, yyyy');

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
            'post_package.step_preferences'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow('Preferred Date',
              formatter.format(widget.package.preferredDeliveryDate)),
          if (widget.package.flexibleDateStart != null &&
              widget.package.flexibleDateEnd != null) ...[
            _buildDetailRow(
              'Flexible Range',
              '${formatter.format(widget.package.flexibleDateStart!)} - ${formatter.format(widget.package.flexibleDateEnd!)}',
            ),
          ],
          if (widget.package.isUrgent)
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.priority_high, size: 14, color: Colors.red),
                  SizedBox(width: 4),
                  Text(
                    'post_package.urgent_delivery'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompensationSection() {
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
            'detail.compensation'.tr(),
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
                    '€${widget.package.compensationOffer.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF215C5C),
                    ),
                  ),
                  Text(
                    'tracking.offered_for_delivery'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (widget.package.insuranceRequired) ...[
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
                  Icon(Icons.security, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Insured for \$${widget.package.insuranceValue?.toStringAsFixed(2) ?? 'TBD'}',
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

  Widget _buildPhotosSection() {
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
            'post_package.package_photos'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.package.photoUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 12),
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.package.photoUrls[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions() {
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
            'detail.special_instructions'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Text(
            widget.package.specialInstructions!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
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
  //           future: ReviewService().getReviewSummary(widget.package.id),
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
  //                       'No reviews yet',
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
  //                       'No reviews yet',
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
  //           child: OutlinedButton.icon(
  //             onPressed: _navigateToReviewList,
  //             icon: Icon(Icons.list, size: 16),
  //             label: Text(
  //               'View All Reviews',
  //               style: TextStyle(fontSize: 14),
  //             ),
  //             style: OutlinedButton.styleFrom(
  //               foregroundColor: Color(0xFF215C5C),
  //               side: BorderSide(color: Color(0xFF215C5C)),
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
  //         targetId: widget.package.id,
  //         reviewType: ReviewType.package,
  //         targetName: widget.package.packageDetails.description,
  //       ),
  //     ),
  //   );
  // }

  // void _navigateToCreateReview() async {
  //   final hasHandled = await _checkIfUserHandledPackage();
  //
  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (context) => CreateReviewScreen(
  //         targetId: widget.package.id,
  //         reviewType: ReviewType.package,
  //         targetName: widget.package.packageDetails.description,
  //         targetImageUrl: widget.package.photoUrls.isNotEmpty
  //             ? widget.package.photoUrls.first
  //             : null,
  //         isVerifiedBooking: hasHandled,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildActionButton() {
    // Debug logging to check values
    final currentUserId = _authService.currentUser?.uid;
    final senderId = widget.package.senderId;

    print('=== PACKAGE DETAIL DEBUG ===');
    print('Current User ID: $currentUserId');
    print('Sender ID: $senderId');
    print('Are they equal? ${currentUserId == senderId}');
    print('============================');

    // Don't show button if user is the sender
    if (currentUserId == senderId) {
      print('HIDING BUTTONS: User is the package owner');
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Chat Button
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: "chat_button_${widget.package.id}",
              onPressed: _openChatWithSender,
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
          // Interest Button
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: "interest_button_${widget.package.id}",
              onPressed: _isLoading ? null : _navigateToMakeOfferScreen,
              backgroundColor: Color(0xFF215C5C),
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
                  : Icon(Icons.monetization_on),
              label: Text(
                'detail.make_offer'.tr(),
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

  // Navigate to make offer screen
  void _navigateToMakeOfferScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MakeOfferScreen(
          package: widget.package,
        ),
      ),
    );

    // If offer was submitted successfully, show success message
    if (result == true) {
      EnhancedSnackBar.showSuccess(context, 'Offer sent successfully!');
    }
  }

  // Open chat with sender without creating interest records
  void _openChatWithSender() async {
    try {
      // Get current user
      final currentUserId = FirebaseAuthService().currentUser?.uid;
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('chat.login_required'.tr()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }

      // Get or initialize ChatController
      late ChatController chatController;
      if (Get.isRegistered<ChatController>()) {
        chatController = Get.find<ChatController>();
      } else {
        chatController = Get.put(ChatController());
      }

      // Create or get conversation with sender
      final conversationId = await chatController.createOrGetConversation(
        otherUserId: widget.package.senderId,
        otherUserName: widget.package.senderName,
        otherUserAvatar: widget.package.senderPhotoUrl.isNotEmpty
            ? widget.package.senderPhotoUrl
            : null,
        packageRequestId: widget.package.id,
      );

      if (conversationId != null) {
        // Navigate to individual chat screen
        Get.to(() => IndividualChatScreen(
              conversationId: conversationId,
              otherUserName: widget.package.senderName,
              otherUserId: widget.package.senderId,
              otherUserAvatar: widget.package.senderPhotoUrl.isNotEmpty
                  ? widget.package.senderPhotoUrl
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
          content: Text('chat.start_failed'.tr()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // /// Check if the current user has handled (booked) this package
  // Future<bool> _checkIfUserHandledPackage() async {
  //   try {
  //     final bookingService = BookingService();
  //     return await bookingService.hasUserBookedPackage(widget.package.id);
  //   } catch (e) {
  //     print('Error checking package handling status: $e');
  //     return false; // Default to false if error
  //   }
  // }

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
        return 'Small (Pocket/Small bag)';
      case PackageSize.medium:
        return 'Medium (Shoebox size)';
      case PackageSize.large:
        return 'Large (Suitcase space)';
      case PackageSize.extraLarge:
        return 'Extra Large (Special item)';
    }
  }
}
