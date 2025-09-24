import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final _countryController = TextEditingController();
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
    {'name': 'Germany', 'code': '+49', 'placeholder': '1234567890'},
    {'name': 'United States', 'code': '+1', 'placeholder': '(555) 123-4567'},
    {'name': 'United Kingdom', 'code': '+44', 'placeholder': '7123 456789'},
    {'name': 'France', 'code': '+33', 'placeholder': '1 23 45 67 89'},
    {'name': 'Italy', 'code': '+39', 'placeholder': '123 456 7890'},
    {'name': 'Spain', 'code': '+34', 'placeholder': '612 34 56 78'},
    {'name': 'Netherlands', 'code': '+31', 'placeholder': '6 12345678'},
    {'name': 'Canada', 'code': '+1', 'placeholder': '(555) 123-4567'},
    {'name': 'Australia', 'code': '+61', 'placeholder': '412 345 678'},
    {'name': 'Japan', 'code': '+81', 'placeholder': '90-1234-5678'},
    {'name': 'Switzerland', 'code': '+41', 'placeholder': '78 123 45 67'},
    {'name': 'Austria', 'code': '+43', 'placeholder': '664 123456'},
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Complete KYC Verification',
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
                title: 'Personal Information',
                icon: Icons.person,
                children: [
                  _buildTextFormField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Gender',
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
                    label: 'Date of Birth',
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
                title: 'Contact Information',
                icon: Icons.contact_phone,
                children: [
                  _buildPhoneNumberField(),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value!)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Address Information Section
              _buildSectionCard(
                title: 'Address Information',
                icon: Icons.location_on,
                children: [
                  _buildTextFormField(
                    controller: _addressController,
                    label: 'Street Address',
                    icon: Icons.home,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your address';
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
                          label: 'City',
                          icon: Icons.location_city,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter your city';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _postalCodeController,
                          label: 'Postal Code',
                          icon: Icons.local_post_office,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter postal code';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _countryController,
                    label: 'Country',
                    icon: Icons.public,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your country';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Document Verification Section
              _buildSectionCard(
                title: 'Document Verification',
                icon: Icons.description,
                children: [
                  _buildDropdownField(
                    label: 'Document Type',
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
                  _buildDocumentUploadButton('Upload Document Front'),
                  const SizedBox(height: 12),
                  _buildDocumentUploadButton('Upload Document Back'),
                  const SizedBox(height: 12),
                  _buildDocumentUploadButton('Upload Selfie'),
                ],
              ),

              const SizedBox(height: 30),

              // Submit Button
              _buildSubmitButton(),

              const SizedBox(height: 20),
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
        const Text(
          'KYC Verification Progress',
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
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue,
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
          borderSide: const BorderSide(color: Colors.blue, width: 2),
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
          'Phone Number',
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
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your phone number';
                  }
                  // Basic phone validation based on country
                  if (_selectedCountryCode == '+49' && value!.length < 10) {
                    return 'German phone numbers should be at least 10 digits';
                  }
                  if ((_selectedCountryCode == '+1') && value!.length < 10) {
                    return 'Phone number should be at least 10 digits';
                  }
                  if (value!.length < 8) {
                    return 'Phone number is too short';
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
          borderSide: const BorderSide(color: Colors.blue, width: 2),
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

  Widget _buildDocumentUploadButton(String label) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue.withOpacity(0.05),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Handle document upload
            _showDocumentUploadDialog(label);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.blue,
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
          backgroundColor: Colors.blue,
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
            : const Text(
                'Submit KYC Application',
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upload $documentType'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle camera capture
                  _handleDocumentCapture('camera', documentType);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle gallery selection
                  _handleDocumentCapture('gallery', documentType);
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
      final XFile? picked =
          await _picker.pickImage(source: imgSource, imageQuality: 85);
      if (picked == null) return;
      final file = File(picked.path);

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
          content: Text('$documentType selected'),
          backgroundColor: Colors.green,
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
      _showErrorMessage('Please select your date of birth');
      return;
    }

    // Check if user is at least 18 years old
    final age =
        DateTime.now().difference(_selectedDateOfBirth!).inDays / 365.25;
    if (age < 18) {
      _showErrorMessage('You must be at least 18 years old to complete KYC');
      return;
    }

    // Validate document uploads
    if (_docFrontFile == null && _docFrontUrl == null) {
      _showErrorMessage('Please upload the front side of your document');
      return;
    }
    if (_selfieFile == null && _selfieUrl == null) {
      _showErrorMessage('Please upload a selfie');
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

      // Upload files if needed
      if (_docFrontUrl == null && _docFrontFile != null) {
        _docFrontUrl = await _kycService.uploadKycFile(
          file: _docFrontFile!,
          userId: uid,
          type: 'documentFront',
        );
      }
      if (_docBackFile != null && _docBackUrl == null) {
        _docBackUrl = await _kycService.uploadKycFile(
          file: _docBackFile!,
          userId: uid,
          type: 'documentBack',
        );
      }
      if (_selfieUrl == null && _selfieFile != null) {
        _selfieUrl = await _kycService.uploadKycFile(
          file: _selfieFile!,
          userId: uid,
          type: 'selfie',
        );
      }

      // Validate required fields
      final fullName = _fullNameController.text.trim();
      final addressLine = _addressController.text.trim();
      final city = _cityController.text.trim();
      final postalCode = _postalCodeController.text.trim();
      final country = _countryController.text.trim();

      if (fullName.isEmpty ||
          addressLine.isEmpty ||
          city.isEmpty ||
          postalCode.isEmpty ||
          country.isEmpty) {
        throw Exception('All personal information fields are required');
      }

      // Submit KYC application to Firestore
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

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showSuccessDialog(applicationId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorMessage('KYC submission failed: ${e.toString()}');
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
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('KYC Submitted'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your KYC application has been submitted for review.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'Application ID: $applicationId',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You will be notified once the verification is complete. This usually takes 1-3 business days.',
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
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
