import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class TripCompensationWidget extends StatelessWidget {
  final double suggestedReward;
  final Function(double) onRewardChanged;

  const TripCompensationWidget({
    Key? key,
    required this.suggestedReward,
    required this.onRewardChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Suggested Reward
        _buildSectionTitle('Suggested Reward per Package'),
        _buildRewardSelector(),

        SizedBox(height: 3.h),

        // Reward Information
        _buildRewardInfo(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppTheme.lightTheme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildRewardSelector() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
        ),
      ),
      child: Column(
        children: [
          // Slider for reward amount
          Row(
            children: [
              Text(
                '\$${suggestedReward.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
              Text(
                ' per package',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          Slider(
            value: suggestedReward,
            min: 5.0,
            max: 200.0,
            divisions: 39,
            label: '\$${suggestedReward.toStringAsFixed(0)}',
            onChanged: onRewardChanged,
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$5',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              Text(
                '\$200',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Quick select buttons
          Wrap(
            spacing: 2.w,
            children: [15, 25, 50, 75, 100].map((amount) {
              final isSelected = suggestedReward == amount.toDouble();
              return InkWell(
                onTap: () => onRewardChanged(amount.toDouble()),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.primaryColor
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.primaryColor
                          : AppTheme.lightTheme.colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    '\$$amount',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardInfo() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.lightTheme.primaryColor,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'How Rewards Work',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildInfoRow(
            Icons.trending_up,
            'Higher rewards attract more package requests',
          ),
          SizedBox(height: 1.h),
          _buildInfoRow(
            Icons.verified,
            'Payment is released when package is delivered',
          ),
          SizedBox(height: 1.h),
          _buildInfoRow(
            Icons.percent,
            'CrowdWave takes a 10% service fee',
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: Colors.green,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'You\'ll receive \$${(suggestedReward * 0.9).toStringAsFixed(2)} per package after fees',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color:
              AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
          size: 16,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}
