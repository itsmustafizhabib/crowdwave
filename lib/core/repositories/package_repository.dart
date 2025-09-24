import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../../services/admin_service.dart';

class PackageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'packageRequests';
  final AdminService _adminService = AdminService();

  // Create a new package request
  Future<String> createPackageRequest(PackageRequest packageRequest) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(packageRequest.toJson());

      // Log the package creation for admin monitoring
      await _adminService.logSystemEvent(
        eventType: 'PACKAGE_CREATED',
        description:
            'New package posted from ${packageRequest.pickupLocation.city ?? packageRequest.pickupLocation.address} to ${packageRequest.destinationLocation.city ?? packageRequest.destinationLocation.address}',
        metadata: {
          'packageId': docRef.id,
          'senderId': packageRequest.senderId,
          'packageType': packageRequest.packageDetails.type.name,
          'packageSize': packageRequest.packageDetails.size.name,
          'compensationOffer': packageRequest.compensationOffer,
          'isUrgent': packageRequest.isUrgent,
        },
        userId: packageRequest.senderId,
        itemId: docRef.id,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create package request: $e');
    }
  }

  // Get package request by ID
  Future<PackageRequest?> getPackageRequest(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Add the document ID to the data
        data['id'] = doc.id;
        return PackageRequest.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get package request: $e');
    }
  }

  // Get packages by sender ID
  Stream<List<PackageRequest>> getPackagesBySender(String senderId) {
    return _firestore
        .collection(_collection)
        .where('senderId', isEqualTo: senderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return PackageRequest.fromJson(data);
            }).toList());
  }

  // Get available packages for matching
  Stream<List<PackageRequest>> getAvailablePackages({
    String? excludeSenderId,
    PackageStatus status = PackageStatus.pending,
  }) {
    Query query = _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true);

    if (excludeSenderId != null) {
      query = query.where('senderId', isNotEqualTo: excludeSenderId);
    }

    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return PackageRequest.fromJson(data);
        }).toList());
  }

  // Update package request
  Future<void> updatePackageRequest(
      String id, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection(_collection).doc(id).update(updates);
    } catch (e) {
      throw Exception('Failed to update package request: $e');
    }
  }

  // Update package status
  Future<void> updatePackageStatus(String id, PackageStatus status) async {
    await updatePackageRequest(id, {'status': status.name});
  }

  // Assign traveler to package
  Future<void> assignTraveler(String packageId, String travelerId) async {
    await updatePackageRequest(packageId, {
      'assignedTravelerId': travelerId,
      'status': PackageStatus.matched.name,
    });
  }

  // Search packages by location and criteria
  Future<List<PackageRequest>> searchPackages({
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    double radiusKm = 50.0,
    DateTime? startDate,
    DateTime? endDate,
    List<PackageType>? packageTypes,
    PackageSize? maxSize,
    double? maxWeight,
  }) async {
    try {
      // Note: For production, you'd want to use GeoFirestore or similar for proper geo queries
      // This is a simplified version
      Query query = _firestore
          .collection(_collection)
          .where('status', isEqualTo: PackageStatus.pending.name);

      if (startDate != null) {
        query = query.where('preferredDeliveryDate',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('preferredDeliveryDate',
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.get();
      final packages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return PackageRequest.fromJson(data);
      }).toList();

      // Filter by additional criteria (in production, use proper geo queries)
      return packages.where((package) {
        // Add distance calculations and other filtering logic here
        bool matches = true;

        if (packageTypes != null && packageTypes.isNotEmpty) {
          matches &= packageTypes.contains(package.packageDetails.type);
        }

        if (maxSize != null) {
          matches &= package.packageDetails.size.index <= maxSize.index;
        }

        if (maxWeight != null) {
          matches &= package.packageDetails.weightKg <= maxWeight;
        }

        return matches;
      }).toList();
    } catch (e) {
      throw Exception('Failed to search packages: $e');
    }
  }

  // Delete package request
  Future<void> deletePackageRequest(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete package request: $e');
    }
  }

  // Get packages assigned to a traveler
  Stream<List<PackageRequest>> getPackagesForTraveler(String travelerId) {
    return _firestore
        .collection(_collection)
        .where('assignedTravelerId', isEqualTo: travelerId)
        .orderBy('preferredDeliveryDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return PackageRequest.fromJson(data);
            }).toList());
  }

  // Get recent packages for feed
  Stream<List<PackageRequest>> getRecentPackages({int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: PackageStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return PackageRequest.fromJson(data);
            }).toList());
  }
}
