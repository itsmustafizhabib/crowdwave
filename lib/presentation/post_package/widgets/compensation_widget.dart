import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sizer/sizer.dart';
import 'dart:math';

import '../../../core/app_export.dart';

class CompensationWidget extends StatefulWidget {
  final double compensationOffer;
  final bool insuranceRequired;
  final double? insuranceValue;
  final double? packageValue;
  final double distance;
  final Function(double) onCompensationChanged;
  final Function(bool) onInsuranceChanged;
  final Function(double?) onInsuranceValueChanged;

  const CompensationWidget({
    Key? key,
    required this.compensationOffer,
    required this.insuranceRequired,
    required this.insuranceValue,
    required this.packageValue,
    required this.distance,
    required this.onCompensationChanged,
    required this.onInsuranceChanged,
    required this.onInsuranceValueChanged,
  }) : super(key: key);

  @override
  State<CompensationWidget> createState() => _CompensationWidgetState();
}

class _CompensationWidgetState extends State<CompensationWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  // Suggested compensation amounts
  List<double> get _suggestedAmounts {
    final baseAmount = _calculateBaseAmount();
    return [
      (baseAmount * 0.8).roundToDouble(),
      baseAmount.roundToDouble(),
      (baseAmount * 1.3).roundToDouble(),
      (baseAmount * 1.6).roundToDouble(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  double _calculateBaseAmount() {
    double base = max(10.0, widget.distance * 0.8); // $0.80 per km

    // Add premium for urgency, fragile items, etc.
    if (widget.packageValue != null && widget.packageValue! > 100) {
      base += 5.0; // High-value item premium
    }

    return min(base, 200.0); // Cap at $200
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with pricing insight
            _buildPricingInsightCard(),

            SizedBox(height: 4.h),

            // Suggested amounts
            _buildSectionTitle('Quick Select', Icons.flash_on),
            _buildSuggestedAmounts(),

            SizedBox(height: 4.h),

            // Custom amount slider
            _buildSectionTitle('Custom Amount', Icons.tune),
            _buildCustomAmountSlider(),

            SizedBox(height: 4.h),

            // Current compensation display
            _buildCompensationDisplay(),

            SizedBox(height: 4.h),

            // Insurance section
            _buildSectionTitle('Insurance Protection', Icons.security),
            _buildInsuranceSection(),

            SizedBox(height: 4.h),

            // Cost breakdown
            _buildCostBreakdown(),

            SizedBox(height: 4.h),

            // Tips for better matching
            _buildMatchingTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.lightTheme.primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingInsightCard() {
    final baseAmount = _calculateBaseAmount();
    final distance = widget.distance;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.insights,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text('common.pricing_insights'.tr(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Based on ${distance.toStringAsFixed(1)} km distance',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildInsightItem(
                  'Market Rate',
                  '€${baseAmount.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildInsightItem(
                  'Per KM',
                  '€${(baseAmount / distance).toStringAsFixed(2)}',
                  Icons.straighten,
                  Color(0xFF008080),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildInsightItem(
                  'Success Rate',
                  '${_getSuccessRate()}%',
                  Icons.check_circle,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedAmounts() {
    return Row(
      children: _suggestedAmounts.asMap().entries.map((entry) {
        final index = entry.key;
        final amount = entry.value;
        final isSelected = (widget.compensationOffer - amount).abs() < 0.1;
        final isRecommended = index == 1; // Second option is recommended

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
                right: index < _suggestedAmounts.length - 1 ? 2.w : 0),
            child: AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isSelected ? _bounceAnimation.value : 1.0,
                  child: child,
                );
              },
              child: InkWell(
                onTap: () {
                  widget.onCompensationChanged(amount);
                  _bounceController
                      .forward()
                      .then((_) => _bounceController.reverse());
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.primaryColor
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.primaryColor
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.lightTheme.primaryColor
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      if (isRecommended && !isSelected) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('common.popular'.tr(),
                            style: TextStyle(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 1.h),
                      ],
                      Text(
                        '€${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _getAmountLabel(index),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (isSelected) ...[
                        SizedBox(height: 1.h),
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomAmountSlider() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('common.set_your_amount'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '€${widget.compensationOffer.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.lightTheme.primaryColor,
              inactiveTrackColor: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.3),
              thumbColor: AppTheme.lightTheme.primaryColor,
              overlayColor:
                  AppTheme.lightTheme.primaryColor.withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: widget.compensationOffer.clamp(5.0, 500.0),
              min: 5.0,
              max: 500.0,
              divisions: 99,
              onChanged: widget.onCompensationChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('€5', style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
              Text('€500',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompensationDisplay() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.primaryColor,
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.payments,
              color: Colors.white,
              size: 32,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('booking.your_offer'.tr(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '€${widget.compensationOffer.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getCompetitivenessText(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _getCompetitivenessIcon(),
            color: Colors.white,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('post_package.package_insurance'.tr(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text('post_package.protect_your_package_against_loss_or_damage'.tr(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.insuranceRequired,
                onChanged: widget.onInsuranceChanged,
                activeThumbColor: AppTheme.lightTheme.primaryColor,
              ),
            ],
          ),
          if (widget.insuranceRequired) ...[
            SizedBox(height: 3.h),
            Divider(),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('post_package.insurance_value'.tr(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      TextFormField(
                        initialValue: widget.insuranceValue?.toString() ??
                            widget.packageValue?.toString() ??
                            '',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'common.enter_value'.tr(),
                          prefixText: '€ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: EdgeInsets.all(3.w),
                        ),
                        onChanged: (value) {
                          final doubleValue = double.tryParse(value);
                          widget.onInsuranceValueChanged(doubleValue);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('booking.insurance_fee'.tr(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.lightTheme.primaryColor
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '+\$${_calculateInsuranceFee().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCostBreakdown() {
    final insuranceFee =
        widget.insuranceRequired ? _calculateInsuranceFee() : 0.0;
    final platformFee = widget.compensationOffer * 0.1; // 10% platform fee
    final totalCost = widget.compensationOffer + insuranceFee + platformFee;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('common.cost_breakdown'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildCostItem('Delivery Payment', widget.compensationOffer),
          if (widget.insuranceRequired)
            _buildCostItem('Insurance Fee', insuranceFee),
          _buildCostItem('Platform Fee (10%)', platformFee),
          Divider(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('common.total_cost'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '€${totalCost.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostItem(String label, double amount) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          Text(
            '€${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingTips() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Color(0xFF008080).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF008080).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFF008080), size: 20),
              SizedBox(width: 2.w),
              Text('common.tips_for_better_matching'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF008080),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildTip('💰', 'Competitive offers get matched 3x faster'),
          _buildTip('📷', 'Clear photos increase trust by 40%'),
          _buildTip('⏰', 'Flexible dates improve matching success'),
          _buildTip('🛡️', 'Insurance attracts reliable travelers'),
        ],
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.sp,
                color: Color(0xFF008080),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAmountLabel(int index) {
    switch (index) {
      case 0:
        return 'Budget\nFriendly';
      case 1:
        return 'Market\nRate';
      case 2:
        return 'Premium\nService';
      case 3:
        return 'Express\nDelivery';
      default:
        return '';
    }
  }

  String _getCompetitivenessText() {
    final baseAmount = _calculateBaseAmount();
    final ratio = widget.compensationOffer / baseAmount;

    if (ratio < 0.8) return 'Below market rate - longer wait time';
    if (ratio < 1.0) return 'Good value - competitive offer';
    if (ratio < 1.3) return 'Premium offer - faster matching';
    return 'Express offer - immediate attention';
  }

  IconData _getCompetitivenessIcon() {
    final baseAmount = _calculateBaseAmount();
    final ratio = widget.compensationOffer / baseAmount;

    if (ratio < 0.8) return Icons.schedule;
    if (ratio < 1.0) return Icons.thumb_up;
    if (ratio < 1.3) return Icons.flash_on;
    return Icons.rocket_launch;
  }

  String _getSuccessRate() {
    final baseAmount = _calculateBaseAmount();
    final ratio = widget.compensationOffer / baseAmount;

    if (ratio < 0.8) return '45';
    if (ratio < 1.0) return '75';
    if (ratio < 1.3) return '92';
    return '98';
  }

  double _calculateInsuranceFee() {
    if (!widget.insuranceRequired || widget.insuranceValue == null) return 0.0;
    return max(2.0, widget.insuranceValue! * 0.02); // 2% of value, minimum $2
  }
}
