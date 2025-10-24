import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Trans;
import '../../core/models/models.dart';
import '../../services/auth_state_service.dart';
import '../../services/offer_service.dart';
import '../../services/deal_negotiation_service.dart';
import '../../controllers/chat_controller.dart';
import '../../utils/toast_utils.dart';
import '../chat/individual_chat_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class MakeOfferScreen extends StatefulWidget {
  final TravelTrip? trip;
  final PackageRequest? package;

  const MakeOfferScreen({
    Key? key,
    this.trip,
    this.package,
  })  : assert(trip != null || package != null,
            'Either trip or package must be provided'),
        super(key: key);

  @override
  State<MakeOfferScreen> createState() => _MakeOfferScreenState();
}

class _MakeOfferScreenState extends State<MakeOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final AuthStateService _authService = AuthStateService();
  final OfferService _offerService = OfferService();
  final DealNegotiationService _dealService = DealNegotiationService();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with suggested price
    if (widget.trip != null) {
      _priceController.text = widget.trip!.suggestedReward.toStringAsFixed(2);
    } else if (widget.package != null) {
      _priceController.text =
          widget.package!.compensationOffer.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9E9E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF215C5C),
        elevation: 0,
        title: Text('detail.make_offer'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card (Trip or Package)
            _buildInfoCard(),

            const SizedBox(height: 24),

            // Offer Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('booking.your_offer'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price Input
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('common.offer_price'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceController,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            prefixText: '€',
                            hintText: 'booking.enter_offer_price_hint'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF215C5C)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an offer price';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Please enter a valid price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getSuggestedText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notes Input
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Additional Notes (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'common.add_any_special_requirements_or_notes'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF215C5C)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitOffer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D7A6E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text('common.submit_offer'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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

  Widget _buildInfoCard() {
    if (widget.trip != null) {
      return _buildTripInfoCard();
    } else if (widget.package != null) {
      return _buildPackageInfoCard();
    } else {
      return Container(); // Should not happen
    }
  }

  Widget _buildTripInfoCard() {
    final trip = widget.trip!;
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF215C5C).withOpacity(0.1),
                child: trip.travelerPhotoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          trip.travelerPhotoUrl,
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Color(0xFF215C5C),
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.travelerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${trip.fromLocation} → ${trip.toLocation}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                _formatDate(trip.departureDate),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 20),
              Icon(Icons.luggage, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${trip.capacity.maxWeightKg}kg',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageInfoCard() {
    final package = widget.package!;
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF215C5C).withOpacity(0.1),
                child: package.senderPhotoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          package.senderPhotoUrl,
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Color(0xFF215C5C),
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.senderName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${package.pickupLocation.city ?? package.pickupLocation.address} → ${package.destinationLocation.city ?? package.destinationLocation.address}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                _formatDate(package.preferredDeliveryDate),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 20),
              Icon(Icons.category, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                package.packageDetails.type.name,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSuggestedText() {
    if (widget.trip != null) {
      return 'Suggested: \$${widget.trip!.suggestedReward.toStringAsFixed(2)} total';
    } else if (widget.package != null) {
      return 'Requested: \$${widget.package!.compensationOffer.toStringAsFixed(2)} total';
    }
    return '';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return '${difference} days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final price = double.parse(_priceController.text);
      final notes = _notesController.text.trim();

      if (widget.trip != null) {
        // Submit trip offer using the offer service
        final offerId = await _offerService.submitOffer(
          tripId: widget.trip!.id,
          offerAmount: price,
          notes: notes,
        );

        if (kDebugMode) {
          print('Trip offer submitted successfully with ID: $offerId');
        }

        // Show mobile-appropriate success toast
        ToastUtils.show('offer.submitted'.tr());
      } else if (widget.package != null) {
        // Submit package deal offer using the deal negotiation service

        // First create or get conversation
        late ChatController chatController;
        if (Get.isRegistered<ChatController>()) {
          chatController = Get.find<ChatController>();
        } else {
          chatController = Get.put(ChatController());
        }

        final conversationId = await chatController.createOrGetConversation(
          otherUserId: widget.package!.senderId,
          otherUserName: widget.package!.senderName,
          otherUserAvatar: widget.package!.senderPhotoUrl.isNotEmpty
              ? widget.package!.senderPhotoUrl
              : null,
          packageRequestId: widget.package!.id,
        );

        if (conversationId == null) {
          throw Exception('Failed to create conversation');
        }

        // Send the price offer
        await _dealService.sendPriceOffer(
          packageId: widget.package!.id,
          conversationId: conversationId,
          travelerId: currentUser.uid,
          offeredPrice: price,
          message: notes.isNotEmpty ? notes : null,
        );

        if (kDebugMode) {
          print('Package offer submitted successfully');
        }

        // Show mobile-appropriate success toast
        ToastUtils.show('offer.submitted'.tr());

        // Navigate to chat immediately (removed artificial delay for better UX)
        Get.to(() => IndividualChatScreen(
              conversationId: conversationId,
              otherUserName: widget.package!.senderName,
              otherUserId: widget.package!.senderId,
              otherUserAvatar: widget.package!.senderPhotoUrl.isNotEmpty
                  ? widget.package!.senderPhotoUrl
                  : null,
            ));
      }

      // Navigate back
      Navigator.pop(context, true);
    } catch (e) {
      String errorMessage = _getErrorMessage(e.toString());
      ToastUtils.show('error.generic'.tr(args: [errorMessage]));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Helper method to convert technical errors to user-friendly messages
  String _getErrorMessage(String error) {
    if (error.contains('Trip not found')) {
      return 'This travel plan is no longer available. Please refresh and try again.';
    } else if (error.contains('User not authenticated')) {
      return 'Please log in again to continue.';
    } else if (error.contains('not available')) {
      return 'This trip is no longer accepting offers.';
    } else if (error.contains('maximum limit')) {
      return 'You have already submitted 2 offers for this package. Please wait for a response from the sender.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else if (error.contains('Invalid trip')) {
      return 'There seems to be an issue with this trip. Please contact support.';
    } else {
      return 'Something went wrong. Please try again or contact support if the problem persists.';
    }
  }
}
