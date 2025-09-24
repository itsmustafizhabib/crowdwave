import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_export.dart';
import '../presentation/trip_detail/trip_detail_screen.dart';
import '../presentation/chat/individual_chat_screen.dart';
import '../presentation/booking/make_offer_screen.dart';
import '../controllers/chat_controller.dart';

class TripCardWidget extends StatelessWidget {
  final TravelTrip trip;
  final int index;
  final bool showActions;
  final VoidCallback? onTap;

  const TripCardWidget({
    Key? key,
    required this.trip,
    required this.index,
    this.showActions = false,
    this.onTap,
  }) : super(key: key);

  // Helper method to check if the trip belongs to the current user
  bool _isCurrentUserTrip() {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      return currentUser != null && currentUser.uid == trip.travelerId;
    } catch (e) {
      // If there's an error, assume it's not the current user's trip to be safe
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripDetailScreen(trip: trip),
              ),
            );
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0046FF).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Avatar or Transport Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0046FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: trip.travelerPhotoUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              trip.travelerPhotoUrl,
                              width: 20,
                              height: 20,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                _getTransportModeIcon(trip.transportMode),
                                color: const Color(0xFF0046FF),
                                size: 20,
                              ),
                            ),
                          )
                        : Icon(
                            _getTransportModeIcon(trip.transportMode),
                            color: const Color(0xFF0046FF),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (trip.rating != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFF8040),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                trip.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${trip.reviewCount ?? 0} reviews)',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Match indicator and verification status
                  Column(
                    children: [
                      if (trip.matchPercentage != null &&
                          trip.matchPercentage! > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.green, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${trip.matchPercentage!.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: trip.isVerified == true
                              ? const Color(0xFF0046FF).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trip.isVerified == true ? 'Verified' : 'Unverified',
                          style: TextStyle(
                            color: trip.isVerified == true
                                ? const Color(0xFF0046FF)
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Route Information
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${trip.departureLocation.city ?? trip.departureLocation.address} → ${trip.destinationLocation.city ?? trip.destinationLocation.address}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Available Space
              Row(
                children: [
                  const Icon(Icons.luggage, color: Colors.grey, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Available: ${trip.availableSpace?.toStringAsFixed(1) ?? '10.0'} kg (${((trip.availableSpace ?? 10.0) * 2.2).toStringAsFixed(1)} lbs)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date and Price Row
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.grey, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(trip.departureDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    trip.pricePerKg != null
                        ? '€${trip.pricePerKg!.toStringAsFixed(2)}/kg'
                        : '\$${trip.suggestedReward}+',
                    style: const TextStyle(
                      color: Color(0xFF0046FF),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              // Action Buttons (only show if showActions is true and trip doesn't belong to current user)
              if (showActions && !_isCurrentUserTrip()) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            // Get or create ChatController (ensure single instance)
                            ChatController chatController;
                            try {
                              chatController = Get.find<ChatController>();
                            } catch (e) {
                              // Put the controller with a permanent tag to ensure it's a singleton
                              chatController =
                                  Get.put(ChatController(), permanent: true);
                            }

                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0046FF),
                                ),
                              ),
                            );

                            // Create or get conversation
                            final conversationId =
                                await chatController.createOrGetConversation(
                              otherUserId: trip.travelerId,
                              otherUserName: trip.travelerName,
                              otherUserAvatar: trip.travelerPhotoUrl,
                            );

                            // Hide loading indicator
                            Navigator.pop(context);

                            if (conversationId != null) {
                              // Navigate to chat screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => IndividualChatScreen(
                                    conversationId: conversationId,
                                    otherUserId: trip.travelerId,
                                    otherUserName: trip.travelerName,
                                    otherUserAvatar: trip.travelerPhotoUrl,
                                  ),
                                ),
                              );
                            } else {
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Failed to start chat. Please try again.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            // Hide loading indicator if still showing
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }

                            // Show error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0046FF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Chat Now',
                          style: TextStyle(
                            color: Color(0xFF0046FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MakeOfferScreen(trip: trip),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8040),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Make Offer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
      case TransportMode.ship:
        return Icons.directions_boat;
      case TransportMode.motorcycle:
        return Icons.motorcycle;
      case TransportMode.bicycle:
        return Icons.directions_bike;
      case TransportMode.walking:
        return Icons.directions_walk;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date TBD';

    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return 'In $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
