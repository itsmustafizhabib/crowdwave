import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../../services/admin_service.dart';

class TripRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'travelTrips';
  final AdminService _adminService = AdminService();

  // Create a new travel trip
  Future<String> createTravelTrip(TravelTrip travelTrip) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(travelTrip.toJson());

      // Log the trip creation for admin monitoring
      await _adminService.logSystemEvent(
        eventType: 'TRIP_CREATED',
        description:
            'New trip posted from ${travelTrip.departureLocation.city ?? travelTrip.departureLocation.address} to ${travelTrip.destinationLocation.city ?? travelTrip.destinationLocation.address}',
        metadata: {
          'tripId': docRef.id,
          'travelerId': travelTrip.travelerId,
          'transportMode': travelTrip.transportMode.name,
          'suggestedReward': travelTrip.suggestedReward,
          'maxPackages': travelTrip.capacity.maxPackages,
        },
        userId: travelTrip.travelerId,
        itemId: docRef.id,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create travel trip: $e');
    }
  }

  // Get travel trip by ID
  Future<TravelTrip?> getTravelTrip(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return TravelTrip.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get travel trip: $e');
    }
  }

  // Get trips by traveler ID
  Stream<List<TravelTrip>> getTripsByTraveler(String travelerId) {
    return _firestore
        .collection(_collection)
        .where('travelerId', isEqualTo: travelerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = (doc.data() as Map<String, dynamic>);
              data['id'] = data['id'] ?? doc.id;
              return TravelTrip.fromJson(data);
            }).toList());
  }

  // Get available trips for matching
  Stream<List<TravelTrip>> getAvailableTrips({
    String? excludeTravelerId,
    TripStatus status = TripStatus.active,
  }) {
    Query query = _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true);

    if (excludeTravelerId != null) {
      query = query.where('travelerId', isNotEqualTo: excludeTravelerId);
    }

    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = data['id'] ?? doc.id;
          return TravelTrip.fromJson(data);
        }).toList());
  }

  // Update travel trip
  Future<void> updateTravelTrip(String id, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection(_collection).doc(id).update(updates);
    } catch (e) {
      throw Exception('Failed to update travel trip: $e');
    }
  }

  // Update trip status
  Future<void> updateTripStatus(String id, TripStatus status) async {
    await updateTravelTrip(id, {'status': status.name});
  }

  // Accept package for trip
  Future<void> acceptPackage(String tripId, String packageId) async {
    try {
      // Use array union to add package ID to accepted packages
      await _firestore.collection(_collection).doc(tripId).update({
        'acceptedPackageIds': FieldValue.arrayUnion([packageId]),
        'totalPackagesAccepted': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to accept package: $e');
    }
  }

  // Search trips by location and criteria
  Future<List<TravelTrip>> searchTrips({
    required double departureLat,
    required double departureLng,
    required double destinationLat,
    required double destinationLng,
    double radiusKm = 50.0,
    DateTime? startDate,
    DateTime? endDate,
    List<TransportMode>? transportModes,
    List<PackageType>? acceptedItemTypes,
    double? maxWeightKg,
  }) async {
    try {
      // Note: For production, you'd want to use GeoFirestore or similar for proper geo queries
      // This is a simplified version
      Query query = _firestore
          .collection(_collection)
          .where('status', isEqualTo: TripStatus.active.name);

      if (startDate != null) {
        query = query.where('departureDate',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('departureDate',
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.get();
      final trips = snapshot.docs
          .map((doc) => TravelTrip.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by additional criteria (in production, use proper geo queries)
      return trips.where((trip) {
        bool matches = true;

        if (transportModes != null && transportModes.isNotEmpty) {
          matches &= transportModes.contains(trip.transportMode);
        }

        if (acceptedItemTypes != null && acceptedItemTypes.isNotEmpty) {
          matches &= acceptedItemTypes
              .any((type) => trip.acceptedItemTypes.contains(type));
        }

        if (maxWeightKg != null) {
          matches &= trip.capacity.maxWeightKg >= maxWeightKg;
        }

        return matches;
      }).toList();
    } catch (e) {
      throw Exception('Failed to search trips: $e');
    }
  }

  // Delete travel trip
  Future<void> deleteTravelTrip(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete travel trip: $e');
    }
  }

  // Get trips assigned packages
  Stream<List<TravelTrip>> getTripsWithPackages(String travelerId) {
    return _firestore
        .collection(_collection)
        .where('travelerId', isEqualTo: travelerId)
        .where('totalPackagesAccepted', isGreaterThan: 0)
        .orderBy('departureDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = data['id'] ?? doc.id;
              return TravelTrip.fromJson(data);
            }).toList());
  }

  // Get recent trips for feed
  Stream<List<TravelTrip>> getRecentTrips({int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: TripStatus.active.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = data['id'] ?? doc.id;
              return TravelTrip.fromJson(data);
            }).toList());
  }

  // Update trip earnings
  Future<void> updateTripEarnings(String tripId, double earnings) async {
    await updateTravelTrip(tripId, {
      'totalEarnings': FieldValue.increment(earnings),
    });
  }

  // Remove package from trip
  Future<void> removePackage(String tripId, String packageId) async {
    try {
      await _firestore.collection(_collection).doc(tripId).update({
        'acceptedPackageIds': FieldValue.arrayRemove([packageId]),
        'totalPackagesAccepted': FieldValue.increment(-1),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to remove package: $e');
    }
  }
}
