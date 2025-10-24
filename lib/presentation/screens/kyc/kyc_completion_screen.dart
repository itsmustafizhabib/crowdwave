import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../services/kyc_service.dart';

class KYCCompletionScreen extends StatefulWidget {
  const KYCCompletionScreen({Key? key}) : super(key: key);

  @override
  State<KYCCompletionScreen> createState() => _KYCCompletionScreenState();
}

class _KYCCompletionScreenState extends State<KYCCompletionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Form state
  String _selectedDocumentType = 'Passport';
  String _selectedGender = 'Male';
  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;

  // Document files
  File? _docFrontFile;
  File? _docBackFile;
  File? _selfieFile;

  // Uploaded URLs (for retry safety)
  String? _docFrontUrl;
  String? _docBackUrl;
  String? _selfieUrl;

  final _picker = ImagePicker();
  final _kycService = KycService();

  // Phone number with country selection
  String _selectedCountryCode = '+49'; // Germany default
  String _selectedCountryName = 'Germany';
  String _phonePlaceholder = '1234567890';

  // Country codes and names (12 countries as requested)
  final List<Map<String, String>> _countries = [
    {'name': 'Germany', 'code': '+49', 'placeholder': '1712345678'},
    {'name': 'United States', 'code': '+1', 'placeholder': '2125551234'},
    {'name': 'United Kingdom', 'code': '+44', 'placeholder': '7123456789'},
    {'name': 'France', 'code': '+33', 'placeholder': '123456789'},
    {'name': 'Italy', 'code': '+39', 'placeholder': '123456789'},
    {'name': 'Spain', 'code': '+34', 'placeholder': '612345678'},
    {'name': 'Netherlands', 'code': '+31', 'placeholder': '612345678'},
    {'name': 'Canada', 'code': '+1', 'placeholder': '4165551234'},
    {'name': 'Australia', 'code': '+61', 'placeholder': '412345678'},
    {'name': 'Japan', 'code': '+81', 'placeholder': '9012345678'},
    {'name': 'Switzerland', 'code': '+41', 'placeholder': '781234567'},
    {'name': 'Austria', 'code': '+43', 'placeholder': '6641234567'},
  ];

  // List of countries for address dropdown
  final List<String> _countryList = [
    'Germany',
    'United States',
    'United Kingdom',
    'France',
    'Italy',
    'Spain',
    'Netherlands',
    'Canada',
    'Australia',
    'Japan',
    'Switzerland',
    'Austria',
    'Belgium',
    'Denmark',
    'Norway',
    'Sweden',
    'Finland',
    'Ireland',
    'Portugal',
    'Greece',
    'Poland',
    'Czech Republic',
    'Hungary',
    'Romania',
    'Bulgaria',
  ];

  String _selectedAddressCountry = 'Germany'; // Default address country

  // Track KYC status
  String? _existingKycStatus;
  bool _isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkExistingKycStatus();
  }

  Future<void> _checkExistingKycStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isCheckingStatus = false;
      });
      return;
    }

    try {
      final status = await _kycService.getKycStatus(user.uid);
      setState(() {
        _existingKycStatus = status;
        _isCheckingStatus = false;
      });
      print('🔍 KYC Completion Screen - Existing Status: $status');
    } catch (e) {
      print('❌ Error checking existing KYC status: $e');
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking status
    if (_isCheckingStatus) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'kyc.complete_title'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF215C5C),
              ),
              SizedBox(height: 16),
              Text(
                'kyc.checking_status'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show status message if KYC is already submitted or approved
    if (_existingKycStatus == 'submitted' || _existingKycStatus == 'pending') {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'kyc.title'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Color(0xFF2D7A6E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_empty,
                    size: 60,
                    color: Color(0xFF2D7A6E),
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'kyc.under_review_title'.tr(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'kyc.under_review_message'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'kyc.under_review_timeline'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF215C5C),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'common.got_it'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_existingKycStatus == 'approved') {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'kyc.title'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'kyc.already_verified_title'.tr(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'kyc.already_verified_message'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF215C5C),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'common.got_it'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show the form for new KYC submission or rejected status

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'kyc.complete_title'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              const SizedBox(height: 30),

              // Personal Information Section
              _buildSectionCard(
                title: 'kyc.personal_info'.tr(),
                icon: Icons.person,
                children: [
                  _buildTextFormField(
                    controller: _fullNameController,
                    label: 'kyc.full_name'.tr(),
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'kyc.error_full_name'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'kyc.gender'.tr(),
                    value: _selectedGender,
                    icon: Icons.wc,
                    items: ['Male', 'Female', 'Other'],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDatePicker(
                    label: 'kyc.date_of_birth'.tr(),
                    icon: Icons.calendar_today,
                    selectedDate: _selectedDateOfBirth,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDateOfBirth = date;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Contact Information Section
              _buildSectionCard(
                title: 'kyc.contact_information'.tr(),
                icon: Icons.contact_phone,
                children: [
                  _buildPhoneNumberField(),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _emailController,
                    label: 'kyc.email_address'.tr(),
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'kyc.error_email_required'.tr();
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value!)) {
                        return 'kyc.error_email_invalid'.tr();
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Address Information Section
              _buildSectionCard(
                title: 'kyc.address_information'.tr(),
                icon: Icons.location_on,
                children: [
                  _buildTextFormField(
                    controller: _addressController,
                    label: 'kyc.street_address'.tr(),
                    icon: Icons.home,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'kyc.error_address_required'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _cityController,
                          label: 'kyc.city'.tr(),
                          icon: Icons.location_city,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'kyc.error_city_required'.tr();
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _postalCodeController,
                          label: 'kyc.zip_code'.tr(),
                          icon: Icons.local_post_office,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'kyc.error_postal_code_required'.tr();
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'kyc.country'.tr(),
                    value: _selectedAddressCountry,
                    icon: Icons.public,
                    items: _countryList,
                    onChanged: (value) {
                      setState(() {
                        _selectedAddressCountry = value!;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Document Verification Section
              _buildSectionCard(
                title: 'kyc.document_verification'.tr(),
                icon: Icons.description,
                children: [
                  // Info banner about automatic compression
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF008080).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xFF008080).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF008080),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'kyc.photo_compression_info'.tr(),
                            style: TextStyle(
                              color: Color(0xFF008080),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'kyc.document_type'.tr(),
                    value: _selectedDocumentType,
                    icon: Icons.card_membership,
                    items: ['Passport', 'National ID', 'Driver\'s License'],
                    onChanged: (value) {
                      setState(() {
                        _selectedDocumentType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentUploadButton('doc_front'),
                  const SizedBox(height: 12),
                  _buildDocumentUploadButton('doc_back'),
                  const SizedBox(height: 12),
                  _buildDocumentUploadButton('selfie'),
                ],
              ),

              const SizedBox(height: 30),

              // Submit Button
              _buildSubmitButton(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'kyc.kyc_verification_progress'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: 0.3,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
          minHeight: 6,
        ),
        const SizedBox(height: 8),
        const Text(
          'Step 1 of 3: Personal Information',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF008080).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Color(0xFF008080),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF008080), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'kyc.phone_number'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country Code Dropdown
            Container(
              width: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  isExpanded: true,
                  items: _countries.map((country) {
                    return DropdownMenuItem<String>(
                      value: country['code'],
                      child: Text(
                        '${country['code']} ${country['name']!.substring(0, 3).toUpperCase()}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCountryCode = newValue;
                        final country = _countries.firstWhere(
                          (c) => c['code'] == newValue,
                        );
                        _selectedCountryName = country['name']!;
                        _phonePlaceholder = country['placeholder']!;
                        _phoneController
                            .clear(); // Clear existing number when country changes
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Phone Number Input
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 15, // Maximum international phone number length
                decoration: InputDecoration(
                  hintText: _phonePlaceholder,
                  prefixIcon: Icon(Icons.phone, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF008080), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  counterText: '', // Hide the character counter
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'kyc.error_phone_required'.tr();
                  }

                  // Remove any spaces, dashes, or parentheses for validation
                  final cleanNumber =
                      value!.replaceAll(RegExp(r'[\s\-\(\)]'), '');

                  // Country-specific validation
                  switch (_selectedCountryCode) {
                    case '+49': // Germany
                      if (cleanNumber.length < 10 || cleanNumber.length > 12) {
                        return 'German phone numbers should be 10-12 digits';
                      }
                      if (!RegExp(r'^[1-9]\d{9,11}$').hasMatch(cleanNumber)) {
                        return 'Invalid German phone number format';
                      }
                      break;

                    case '+1': // US/Canada
                      if (cleanNumber.length != 10) {
                        return 'US/Canadian phone numbers must be 10 digits';
                      }
                      if (!RegExp(r'^[2-9]\d{2}[2-9]\d{6}$')
                          .hasMatch(cleanNumber)) {
                        return 'Invalid US/Canadian phone number format';
                      }
                      break;

                    case '+44': // UK
                      if (cleanNumber.length < 10 || cleanNumber.length > 11) {
                        return 'UK phone numbers should be 10-11 digits';
                      }
                      if (!RegExp(r'^[1-9]\d{9,10}$').hasMatch(cleanNumber)) {
                        return 'Invalid UK phone number format';
                      }
                      break;

                    case '+33': // France
                      if (cleanNumber.length != 10) {
                        return 'French phone numbers must be 10 digits';
                      }
                      if (!RegExp(r'^[1-9]\d{8}$').hasMatch(cleanNumber)) {
                        return 'Invalid French phone number format';
                      }
                      break;

                    case '+39': // Italy
                      if (cleanNumber.length < 9 || cleanNumber.length > 11) {
                        return 'Italian phone numbers should be 9-11 digits';
                      }
                      if (!RegExp(r'^[1-9]\d{8,10}$').hasMatch(cleanNumber)) {
                        return 'Invalid Italian phone number format';
                      }
                      break;

                    case '+34': // Spain
                      if (cleanNumber.length != 9) {
                        return 'Spanish phone numbers must be 9 digits';
                      }
                      if (!RegExp(r'^[6-9]\d{8}$').hasMatch(cleanNumber)) {
                        return 'Invalid Spanish phone number format';
                      }
                      break;

                    case '+31': // Netherlands
                      if (cleanNumber.length != 9) {
                        return 'Dutch phone numbers must be 9 digits';
                      }
                      if (!RegExp(r'^[1-9]\d{8}$').hasMatch(cleanNumber)) {
                        return 'Invalid Dutch phone number format';
                      }
                      break;

                    case '+61': // Australia
                      if (cleanNumber.length != 9) {
                        return 'Australian mobile numbers must be 9 digits';
                      }
                      if (!RegExp(r'^[4-5]\d{8}$').hasMatch(cleanNumber)) {
                        return 'Invalid Australian mobile number format';
                      }
                      break;

                    case '+81': // Japan
                      if (cleanNumber.length < 10 || cleanNumber.length > 11) {
                        return 'Japanese phone numbers should be 10-11 digits';
                      }
                      if (!RegExp(r'^[1-9]\d{9,10}$').hasMatch(cleanNumber)) {
                        return 'Invalid Japanese phone number format';
                      }
                      break;

                    case '+41': // Switzerland
                      if (cleanNumber.length != 9) {
                        return 'Swiss phone numbers must be 9 digits';
                      }
                      if (!RegExp(r'^[1-9]\d{8}$').hasMatch(cleanNumber)) {
                        return 'Invalid Swiss phone number format';
                      }
                      break;

                    case '+43': // Austria
                      if (cleanNumber.length < 10 || cleanNumber.length > 13) {
                        return 'Austrian phone numbers should be 10-13 digits';
                      }
                      if (!RegExp(r'^[1-9]\d{9,12}$').hasMatch(cleanNumber)) {
                        return 'Invalid Austrian phone number format';
                      }
                      break;

                    default:
                      // Generic validation for other countries
                      if (cleanNumber.length < 8 || cleanNumber.length > 15) {
                        return 'Phone number should be 8-15 digits';
                      }
                      if (!RegExp(r'^\d+$').hasMatch(cleanNumber)) {
                        return 'Phone number should contain only digits';
                      }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Selected: $_selectedCountryName ($_selectedCountryCode)',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF008080), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ??
              DateTime.now()
                  .subtract(const Duration(days: 6570)), // 18 years ago
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedDate != null
                    ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                    : label,
                style: TextStyle(
                  color:
                      selectedDate != null ? Colors.black87 : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadButton(String documentType) {
    // Check if this document has been uploaded
    bool isUploaded = false;
    if (documentType == 'doc_front' && _docFrontFile != null) {
      isUploaded = true;
    } else if (documentType == 'doc_back' && _docBackFile != null) {
      isUploaded = true;
    } else if (documentType == 'selfie' && _selfieFile != null) {
      isUploaded = true;
    }

    // Get the proper translation key
    String translationKey = '';
    if (documentType == 'doc_front') {
      translationKey = 'kyc.upload_doc_front';
    } else if (documentType == 'doc_back') {
      translationKey = 'kyc.upload_doc_back';
    } else if (documentType == 'selfie') {
      translationKey = 'kyc.upload_selfie';
    }

    String label = translationKey.tr();

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(
          color: isUploaded ? Colors.green : Color(0xFF008080),
          style: BorderStyle.solid,
          width: isUploaded ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isUploaded
            ? Colors.green.withOpacity(0.1)
            : Color(0xFF008080).withOpacity(0.05),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Handle document upload
            _showDocumentUploadDialog(documentType);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUploaded ? Icons.check_circle : Icons.cloud_upload,
                color: isUploaded ? Colors.green : Color(0xFF008080),
              ),
              const SizedBox(width: 8),
              Text(
                isUploaded ? '$label ✓' : label,
                style: TextStyle(
                  color: isUploaded ? Colors.green : Color(0xFF008080),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitKYC,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF008080),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'kyc.submit_application'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  void _showDocumentUploadDialog(String documentType) {
    // Get the proper display name for the document
    String displayName = '';
    if (documentType == 'doc_front') {
      displayName = 'kyc.upload_doc_front'.tr();
    } else if (documentType == 'doc_back') {
      displayName = 'kyc.upload_doc_back'.tr();
    } else if (documentType == 'selfie') {
      displayName = 'kyc.upload_selfie'.tr();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(displayName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('common.take_photo'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  // Handle camera capture
                  _handleDocumentCapture('camera', documentType);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleDocumentCapture(String source, String documentType) {
    Future<void>(() async {
      final ImageSource imgSource =
          source == 'camera' ? ImageSource.camera : ImageSource.gallery;
      // Aggressive compression for Firestore's 1MB document limit
      // Total base64 size must be under ~700KB for all 3 images combined
      final XFile? picked = await _picker.pickImage(
        source: imgSource,
        imageQuality: 25, // Very aggressive compression (was 50)
        maxWidth: 800, // Smaller dimensions (was 1200)
        maxHeight: 800, // Smaller dimensions (was 1200)
      );
      if (picked == null) return;
      final file = File(picked.path);

      // Get file size
      final fileSize = await file.length();
      final fileSizeKB = (fileSize / 1024).toStringAsFixed(2);

      setState(() {
        if (documentType.contains('Front')) {
          _docFrontFile = file;
          _docFrontUrl = null; // reset cached URL if re-picked
        } else if (documentType.contains('Back')) {
          _docBackFile = file;
          _docBackUrl = null;
        } else if (documentType.contains('Selfie')) {
          _selfieFile = file;
          _selfieUrl = null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'kyc.doc_captured_success'.tr(args: [documentType, fileSizeKB])),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  void _submitKYC() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Please fill in all required fields correctly');
      return;
    }

    // Validate date of birth
    if (_selectedDateOfBirth == null) {
      _showErrorMessage('kyc.error_dob_required'.tr());
      return;
    }

    // Check if user is at least 18 years old
    final age =
        DateTime.now().difference(_selectedDateOfBirth!).inDays / 365.25;
    if (age < 18) {
      _showErrorMessage('kyc.error_age_minimum'.tr());
      return;
    }

    // Validate document uploads
    if (_docFrontFile == null && _docFrontUrl == null) {
      _showErrorMessage('kyc.error_doc_front_required'.tr());
      return;
    }
    if (_selfieFile == null && _selfieUrl == null) {
      _showErrorMessage('kyc.error_selfie_required'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Ensure user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to submit KYC');
      }

      final uid = user.uid;

      print('📤 Starting KYC submission for user: $uid');

      // Upload files if needed
      if (_docFrontUrl == null && _docFrontFile != null) {
        print('📤 Uploading document front...');
        _docFrontUrl = await _kycService.uploadKycFile(
          file: _docFrontFile!,
          userId: uid,
          type: 'documentFront',
        );
        print('✅ Document front uploaded (${_docFrontUrl!.length} chars)');
      }
      if (_docBackFile != null && _docBackUrl == null) {
        print('📤 Uploading document back...');
        _docBackUrl = await _kycService.uploadKycFile(
          file: _docBackFile!,
          userId: uid,
          type: 'documentBack',
        );
        print('✅ Document back uploaded (${_docBackUrl!.length} chars)');
      }
      if (_selfieUrl == null && _selfieFile != null) {
        print('📤 Uploading selfie...');
        _selfieUrl = await _kycService.uploadKycFile(
          file: _selfieFile!,
          userId: uid,
          type: 'selfie',
        );
        print('✅ Selfie uploaded (${_selfieUrl!.length} chars)');
      }

      // Validate required fields
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim();
      final phoneNumber =
          '$_selectedCountryCode${_phoneController.text.trim()}';
      final addressLine = _addressController.text.trim();
      final city = _cityController.text.trim();
      final postalCode = _postalCodeController.text.trim();
      final country = _selectedAddressCountry; // Use dropdown selection

      if (fullName.isEmpty ||
          addressLine.isEmpty ||
          city.isEmpty ||
          postalCode.isEmpty ||
          country.isEmpty) {
        throw Exception('All personal information fields are required');
      }

      print('📝 Preparing KYC data...');
      print('   Full Name: $fullName');
      print('   Email: $email');
      print('   Phone: $phoneNumber');
      print('   Address: $addressLine, $city, $postalCode, $country');
      print('   Date of Birth: $_selectedDateOfBirth');
      print('   Document Type: $_selectedDocumentType');
      print('   Gender: $_selectedGender');

      // Submit KYC application to Firestore
      print('🚀 Submitting to Firestore...');
      final applicationId = await _kycService.submitKyc(
        fullName: fullName,
        dateOfBirth: _selectedDateOfBirth!,
        addressLine: addressLine,
        city: city,
        postalCode: postalCode,
        country: country,
        documentType: _selectedDocumentType,
        documentNumber: null,
        issuingCountry: country,
        expiryDate: null,
        documentFrontBase64: _docFrontUrl!,
        documentBackBase64: _docBackUrl,
        selfieBase64: _selfieUrl!,
      );

      print('✅ KYC submitted successfully! Application ID: $applicationId');

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showSuccessDialog(applicationId);
    } catch (e, stackTrace) {
      print('❌ KYC submission error: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Provide more user-friendly error messages
      String errorMessage = 'KYC submission failed';
      if (e.toString().contains('INVALID_ARGUMENT')) {
        errorMessage =
            'Invalid data format. Please check all fields and try again.';
      } else if (e.toString().contains('network')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please contact support.';
      } else {
        errorMessage = 'KYC submission failed: ${e.toString()}';
      }

      _showErrorMessage(errorMessage);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessDialog(String applicationId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('kyc.submitted_title'.tr()),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'kyc.submitted_message'.tr(),
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                '${'kyc.application_id'.tr()}: $applicationId',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'kyc.submitted_timeline'.tr(),
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Go back with success result
              },
              child: Text('common.ok'.tr()),
            ),
          ],
        );
      },
    );
  }
}
