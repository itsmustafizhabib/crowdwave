import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../widgets/enhanced_card_widget.dart';
import '../../widgets/animated_button_widget.dart';

class EnhancedPostPackageScreen extends StatefulWidget {
  const EnhancedPostPackageScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedPostPackageScreen> createState() =>
      _EnhancedPostPackageScreenState();
}

class _EnhancedPostPackageScreenState extends State<EnhancedPostPackageScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Animation Controllers
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardAnimation;

  // Form Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Form State
  String _selectedSize = '';
  String _selectedUrgency = '';
  List<File> _selectedImages = [];
  DateTime? _pickupDate;
  DateTime? _deliveryDate;
  bool _isFragile = false;
  bool _requiresInsurance = false;

  // Options
  final List<String> _sizeOptions = ['Small', 'Medium', 'Large', 'Extra Large'];
  final List<String> _urgencyOptions = ['Low', 'Medium', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _cardAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((image) => File(image.path)).toList();
      });
    }
  }

  Future<void> _selectDate(bool isPickup) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF2D7A6E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
        } else {
          _deliveryDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAnimatedHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicInfoStep(),
                  _buildLocationStep(),
                  _buildDetailsStep(),
                  _buildPhotosStep(),
                  _buildReviewStep(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D7A6E),
                    const Color(0xFF215C5C),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8.w),
                  bottomRight: Radius.circular(8.w),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 6.w,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('post_package.submit_button'.tr(),
                        style: TextStyle(
                          fontSize: 20.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Step ${_currentStep + 1} of $_totalSteps',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          bool isActive = index <= _currentStep;
          bool isCurrent = index == _currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 1.h,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF2D7A6E) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(0.5.h),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2D7A6E).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('post_package.package_information'.tr(),
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 1.h),
                Text('post_package.tell_us_about_your_package'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 3.h),
                EnhancedCardWidget(
                  child: Column(
                    children: [
                      _buildAnimatedTextField(
                        controller: _titleController,
                        label: 'post_package.package_title'.tr(),
                        hint: 'e.g., MacBook Pro 16"',
                        icon: Icons.inventory_2,
                      ),
                      SizedBox(height: 3.h),
                      _buildAnimatedTextField(
                        controller: _descriptionController,
                        label: 'detail.description'.tr(),
                        hint: 'Describe your package in detail...',
                        icon: Icons.description,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),
                EnhancedCardWidget(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('post_package.package_size'.tr(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 2.h),
                      _buildSizeSelector(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup & Delivery',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.h),
          Text('post_package.where_should_your_package_go'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 3.h),
          EnhancedCardWidget(
            child: Column(
              children: [
                _buildAnimatedTextField(
                  controller: _fromController,
                  label: 'post_package.pickup_location'.tr(),
                  hint: 'Enter pickup address',
                  icon: Icons.location_on,
                ),
                SizedBox(height: 3.h),
                _buildAnimatedTextField(
                  controller: _toController,
                  label: 'post_package.delivery_location'.tr(),
                  hint: 'Enter delivery address',
                  icon: Icons.flag,
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          EnhancedCardWidget(
            child: Column(
              children: [
                _buildDateSelector(
                  'Pickup Date',
                  _pickupDate,
                  () => _selectDate(true),
                ),
                SizedBox(height: 2.h),
                _buildDateSelector(
                  'Delivery Date',
                  _deliveryDate,
                  () => _selectDate(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('detail.package_detail_title'.tr(),
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.h),
          Text('post_package.additional_information_about_your_package'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 3.h),
          EnhancedCardWidget(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildAnimatedTextField(
                        controller: _weightController,
                        label: 'post_package.weight_label'.tr(),
                        hint: 'e.g., 2.5',
                        icon: Icons.scale,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: _buildAnimatedTextField(
                        controller: _priceController,
                        label: 'Price (\$)',
                        hint: 'e.g., 50',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          EnhancedCardWidget(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('common.urgency_level'.tr(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 2.h),
                _buildUrgencySelector(),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          EnhancedCardWidget(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Fragile Item',
                  'Handle with extra care',
                  _isFragile,
                  (value) => setState(() => _isFragile = value),
                  Icons.warning,
                ),
                Divider(color: Colors.grey[300]),
                _buildSwitchTile(
                  'Requires Insurance',
                  'Add insurance protection',
                  _requiresInsurance,
                  (value) => setState(() => _requiresInsurance = value),
                  Icons.security,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('post_package.package_photos'.tr(),
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.h),
          Text('post_package.add_photos_to_help_travelers_identify_your_package'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 3.h),
          EnhancedCardWidget(
            onTap: _pickImages,
            child: Container(
              height: 20.h,
              child: _selectedImages.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 15.w,
                          color: const Color(0xFF2D7A6E),
                        ),
                        SizedBox(height: 2.h),
                        Text('common.tap_to_add_photos'.tr(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D7A6E),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'You can add up to 5 photos',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2.w,
                        mainAxisSpacing: 2.w,
                        childAspectRatio: 1,
                      ),
                      itemCount: _selectedImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          return _buildAddMoreButton();
                        }
                        return _buildImageTile(_selectedImages[index], index);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Submit',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.h),
          Text('post_package.please_review_your_package_details'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 3.h),
          _buildReviewCard(),
        ],
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF2D7A6E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF2D7A6E), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSelector() {
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: _sizeOptions.map((size) {
        bool isSelected = _selectedSize == size;
        return GestureDetector(
          onTap: () => setState(() => _selectedSize = size),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2D7A6E) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF2D7A6E) : Colors.grey[300]!,
              ),
            ),
            child: Text(
              size,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUrgencySelector() {
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: _urgencyOptions.map((urgency) {
        bool isSelected = _selectedUrgency == urgency;
        Color color = _getUrgencyColor(urgency);

        return GestureDetector(
          onTap: () => setState(() => _selectedUrgency = urgency),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Text(
              urgency,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 1.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: const Color(0xFF2D7A6E),
                  size: 5.w,
                ),
                SizedBox(width: 3.w),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Select date',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: date != null ? Colors.grey[800] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2D7A6E)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF2D7A6E),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAddMoreButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF2D7A6E),
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.add,
          size: 8.w,
          color: const Color(0xFF2D7A6E),
        ),
      ),
    );
  }

  Widget _buildImageTile(File image, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 1.w,
          right: 1.w,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedImages.removeAt(index);
              });
            },
            child: Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 4.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard() {
    return EnhancedCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewItem('Title', _titleController.text),
          _buildReviewItem('Description', _descriptionController.text),
          _buildReviewItem('From', _fromController.text),
          _buildReviewItem('To', _toController.text),
          _buildReviewItem('Size', _selectedSize),
          _buildReviewItem('Weight', '${_weightController.text} kg'),
          _buildReviewItem('Price', '€${_priceController.text}'),
          _buildReviewItem('Urgency', _selectedUrgency),
          if (_pickupDate != null)
            _buildReviewItem('Pickup Date',
                '${_pickupDate!.day}/${_pickupDate!.month}/${_pickupDate!.year}'),
          if (_deliveryDate != null)
            _buildReviewItem('Delivery Date',
                '${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}'),
          _buildReviewItem('Photos', '${_selectedImages.length} added'),
          if (_isFragile) _buildReviewItem('Special', 'Fragile item'),
          if (_requiresInsurance) _buildReviewItem('Insurance', 'Required'),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    if (value.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: AnimatedButton(
                text: 'common.previous'.tr(),
                type: AnimatedButtonType.outlined,
                onPressed: _previousStep,
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 4.w),
          Expanded(
            child: AnimatedButton(
              text: _currentStep == _totalSteps - 1 ? 'Submit Package' : 'Next',
              type: AnimatedButtonType.gradient,
              onPressed:
                  _currentStep == _totalSteps - 1 ? _submitPackage : _nextStep,
            ),
          ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Color(0xFF008080);
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _submitPackage() {
    // Show success animation and navigate back
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20.w,
            ),
            SizedBox(height: 2.h),
            Text('common.package_posted_successfully'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text('post_package.your_package_has_been_posted_and_travelers_will_st'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          AnimatedButton(
            text: 'common.done'.tr(),
            type: AnimatedButtonType.gradient,
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
