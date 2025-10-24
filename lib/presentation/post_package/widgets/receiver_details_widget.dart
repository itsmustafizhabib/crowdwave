import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/app_export.dart';
import '../../../core/models/recipient_details.dart';

class ReceiverDetailsWidget extends StatefulWidget {
  final RecipientDetails? receiverDetails;
  final Function(RecipientDetails?) onReceiverDetailsChanged;

  const ReceiverDetailsWidget({
    Key? key,
    this.receiverDetails,
    required this.onReceiverDetailsChanged,
  }) : super(key: key);

  @override
  State<ReceiverDetailsWidget> createState() => _ReceiverDetailsWidgetState();
}

class _ReceiverDetailsWidgetState extends State<ReceiverDetailsWidget> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;
  late TextEditingController _altPhoneController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.receiverDetails?.name ?? '');
    _phoneController =
        TextEditingController(text: widget.receiverDetails?.phone ?? '');
    _emailController =
        TextEditingController(text: widget.receiverDetails?.email ?? '');
    _notesController =
        TextEditingController(text: widget.receiverDetails?.notes ?? '');
    _altPhoneController = TextEditingController(
        text: widget.receiverDetails?.alternativePhone ?? '');

    // Add listeners to update parent
    _nameController.addListener(_updateReceiverDetails);
    _phoneController.addListener(_updateReceiverDetails);
    _emailController.addListener(_updateReceiverDetails);
    _notesController.addListener(_updateReceiverDetails);
    _altPhoneController.addListener(_updateReceiverDetails);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _altPhoneController.dispose();
    super.dispose();
  }

  void _updateReceiverDetails() {
    if (_nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty) {
      final receiverDetails = RecipientDetails(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        alternativePhone: _altPhoneController.text.trim().isNotEmpty
            ? _altPhoneController.text.trim()
            : null,
      );
      widget.onReceiverDetailsChanged(receiverDetails);
    } else {
      widget.onReceiverDetailsChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomIconWidget(
                    iconName: 'person',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'post_package.receiver_details_title'.tr(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'post_package.receiver_details_subtitle'.tr(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Receiver Name (Required)
            Text(
              'post_package.receiver_name'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'post_package.receiver_name_hint'.tr(),
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.lightTheme.colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'post_package.receiver_name_required'.tr();
                }
                return null;
              },
            ),

            SizedBox(height: 2.h),

            // Receiver Phone (Required)
            Text(
              'post_package.receiver_phone'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: 'post_package.receiver_phone_hint'.tr(),
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.lightTheme.colorScheme.surface,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'post_package.receiver_phone_required'.tr();
                }
                // Basic phone validation
                if (value.trim().replaceAll(RegExp(r'[\s\-()]'), '').length <
                    8) {
                  return 'post_package.receiver_phone_invalid'.tr();
                }
                return null;
              },
            ),

            SizedBox(height: 2.h),

            // Receiver Email (Optional)
            Text(
              'post_package.receiver_email'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'post_package.receiver_email_hint'.tr(),
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.lightTheme.colorScheme.surface,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  // Basic email validation
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value.trim())) {
                    return 'post_package.receiver_email_invalid'.tr();
                  }
                }
                return null;
              },
            ),

            SizedBox(height: 2.h),

            // Alternative Phone (Optional)
            Text(
              'post_package.receiver_alt_phone'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            TextFormField(
              controller: _altPhoneController,
              decoration: InputDecoration(
                hintText: 'post_package.receiver_alt_phone_hint'.tr(),
                prefixIcon: Icon(Icons.phone_android_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.lightTheme.colorScheme.surface,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
              ],
            ),

            SizedBox(height: 2.h),

            // Delivery Notes (Optional)
            Text(
              'post_package.receiver_notes'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'post_package.receiver_notes_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.lightTheme.colorScheme.surface,
              ),
            ),

            SizedBox(height: 2.h),

            // Info Box
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'post_package.receiver_details_info'.tr(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.blue.shade900,
                      ),
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

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }
}
