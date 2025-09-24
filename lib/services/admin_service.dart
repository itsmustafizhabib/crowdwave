import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/models.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  final String _adminCollection = 'admin';
  final String _analyticsCollection = 'analytics';
  final String _systemLogsCollection = 'systemLogs';

  // ========== PACKAGE MANAGEMENT ==========

  /// Get all package requests for admin review
  Stream<List<PackageRequest>> getAllPackageRequests({
    PackageStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    Query query = _firestore.collection('packageRequests');

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (startDate != null) {
      query = query.where('createdAt',
          isGreaterThanOrEqualTo: startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.where('createdAt',
          isLessThanOrEqualTo: endDate.toIso8601String());
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return PackageRequest.fromJson(data);
            }).toList());
  }

  /// Get package analytics
  Future<Map<String, dynamic>> getPackageAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('packageRequests');

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.get();
      final packages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return PackageRequest.fromJson(data);
      }).toList();

      // Calculate analytics
      final totalPackages = packages.length;
      final pendingPackages =
          packages.where((p) => p.status == PackageStatus.pending).length;
      final matchedPackages =
          packages.where((p) => p.status == PackageStatus.matched).length;
      final confirmedPackages =
          packages.where((p) => p.status == PackageStatus.confirmed).length;
      final pickedUpPackages =
          packages.where((p) => p.status == PackageStatus.pickedUp).length;
      final inTransitPackages =
          packages.where((p) => p.status == PackageStatus.inTransit).length;
      final deliveredPackages =
          packages.where((p) => p.status == PackageStatus.delivered).length;
      final cancelledPackages =
          packages.where((p) => p.status == PackageStatus.cancelled).length;
      final disputedPackages =
          packages.where((p) => p.status == PackageStatus.disputed).length;

      final totalValue =
          packages.fold<double>(0.0, (sum, p) => sum + p.compensationOffer);
      final avgValue = totalPackages > 0 ? totalValue / totalPackages : 0.0;

      return {
        'totalPackages': totalPackages,
        'pendingPackages': pendingPackages,
        'matchedPackages': matchedPackages,
        'confirmedPackages': confirmedPackages,
        'pickedUpPackages': pickedUpPackages,
        'inTransitPackages': inTransitPackages,
        'deliveredPackages': deliveredPackages,
        'cancelledPackages': cancelledPackages,
        'disputedPackages': disputedPackages,
        'totalValue': totalValue,
        'averageValue': avgValue,
        'completionRate':
            totalPackages > 0 ? (deliveredPackages / totalPackages) * 100 : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get package analytics: $e');
    }
  }

  // ========== TRIP MANAGEMENT ==========

  /// Get all travel trips for admin review
  Stream<List<TravelTrip>> getAllTravelTrips({
    TripStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    Query query = _firestore.collection('travelTrips');

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (startDate != null) {
      query = query.where('createdAt',
          isGreaterThanOrEqualTo: startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.where('createdAt',
          isLessThanOrEqualTo: endDate.toIso8601String());
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                TravelTrip.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get trip analytics
  Future<Map<String, dynamic>> getTripAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('travelTrips');

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.get();
      final trips = snapshot.docs
          .map((doc) => TravelTrip.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Calculate analytics
      final totalTrips = trips.length;
      final activeTrips =
          trips.where((t) => t.status == TripStatus.active).length;
      final fullTrips = trips.where((t) => t.status == TripStatus.full).length;
      final inProgressTrips =
          trips.where((t) => t.status == TripStatus.inProgress).length;
      final completedTrips =
          trips.where((t) => t.status == TripStatus.completed).length;
      final cancelledTrips =
          trips.where((t) => t.status == TripStatus.cancelled).length;

      final totalEarnings =
          trips.fold<double>(0.0, (sum, t) => sum + t.totalEarnings);
      final totalPackagesCarried =
          trips.fold<int>(0, (sum, t) => sum + t.totalPackagesAccepted);

      return {
        'totalTrips': totalTrips,
        'activeTrips': activeTrips,
        'fullTrips': fullTrips,
        'inProgressTrips': inProgressTrips,
        'completedTrips': completedTrips,
        'cancelledTrips': cancelledTrips,
        'totalEarnings': totalEarnings,
        'totalPackagesCarried': totalPackagesCarried,
        'avgPackagesPerTrip':
            totalTrips > 0 ? totalPackagesCarried / totalTrips : 0.0,
        'avgEarningsPerTrip': totalTrips > 0 ? totalEarnings / totalTrips : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get trip analytics: $e');
    }
  }

  // ========== USER MANAGEMENT ==========

  /// Get user statistics
  Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      // Get packages and trips to analyze user activity
      final packagesSnapshot =
          await _firestore.collection('packageRequests').get();
      final tripsSnapshot = await _firestore.collection('travelTrips').get();

      final packages = packagesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PackageRequest.fromJson(data);
      }).toList();

      final trips = tripsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TravelTrip.fromJson(data);
      }).toList();

      // Get unique senders and travelers
      final uniqueSenders = packages.map((p) => p.senderId).toSet();
      final uniqueTravelers = trips.map((t) => t.travelerId).toSet();
      final allUsers = {...uniqueSenders, ...uniqueTravelers};

      return {
        'totalUsers': allUsers.length,
        'totalSenders': uniqueSenders.length,
        'totalTravelers': uniqueTravelers.length,
        'activeSenders': packages
            .where((p) =>
                p.status != PackageStatus.cancelled &&
                p.status != PackageStatus.disputed)
            .map((p) => p.senderId)
            .toSet()
            .length,
        'activeTravelers': trips
            .where((t) => t.status != TripStatus.cancelled)
            .map((t) => t.travelerId)
            .toSet()
            .length,
      };
    } catch (e) {
      throw Exception('Failed to get user analytics: $e');
    }
  }

  // ========== SYSTEM LOGS ==========

  /// Log system events for admin monitoring
  Future<void> logSystemEvent({
    required String eventType,
    required String description,
    Map<String, dynamic>? metadata,
    String? userId,
    String? itemId,
  }) async {
    try {
      await _firestore.collection(_systemLogsCollection).add({
        'eventType': eventType,
        'description': description,
        'metadata': metadata ?? {},
        'userId': userId,
        'itemId': itemId,
        'timestamp': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to log system event: $e');
      // Don't throw here to avoid breaking app flow
    }
  }

  /// Get system logs for admin review
  Stream<List<Map<String, dynamic>>> getSystemLogs({
    String? eventType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) {
    Query query = _firestore.collection(_systemLogsCollection);

    if (eventType != null) {
      query = query.where('eventType', isEqualTo: eventType);
    }

    if (startDate != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.where('timestamp',
          isLessThanOrEqualTo: endDate.toIso8601String());
    }

    return query
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList());
  }

  // ========== REPORTS & ANALYTICS ==========

  /// Generate comprehensive platform analytics
  Future<Map<String, dynamic>> getPlatformAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final packageAnalytics =
          await getPackageAnalytics(startDate: startDate, endDate: endDate);
      final tripAnalytics =
          await getTripAnalytics(startDate: startDate, endDate: endDate);
      final userAnalytics = await getUserAnalytics();

      return {
        'packages': packageAnalytics,
        'trips': tripAnalytics,
        'users': userAnalytics,
        'generatedAt': DateTime.now().toIso8601String(),
        'dateRange': {
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        }
      };
    } catch (e) {
      throw Exception('Failed to generate platform analytics: $e');
    }
  }

  /// Save analytics report
  Future<String> saveAnalyticsReport(Map<String, dynamic> analytics) async {
    try {
      final docRef = await _firestore.collection(_analyticsCollection).add({
        ...analytics,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save analytics report: $e');
    }
  }

  /// Get saved analytics reports
  Stream<List<Map<String, dynamic>>> getAnalyticsReports({int limit = 20}) {
    return _firestore
        .collection(_analyticsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // ========== ADMIN ACTIONS ==========

  /// Suspend or unsuspend a user (future implementation)
  Future<void> updateUserStatus(
      String userId, String status, String reason) async {
    try {
      await _firestore
          .collection(_adminCollection)
          .doc('userActions')
          .collection('suspensions')
          .add({
        'userId': userId,
        'status': status,
        'reason': reason,
        'actionTakenBy': 'admin', // In future, pass actual admin ID
        'timestamp': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log the action
      await logSystemEvent(
        eventType: 'USER_STATUS_CHANGE',
        description: 'User status changed to $status',
        metadata: {'userId': userId, 'status': status, 'reason': reason},
        userId: userId,
      );
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  /// Flag content for review
  Future<void> flagContent({
    required String contentType, // 'package' or 'trip'
    required String contentId,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore
          .collection(_adminCollection)
          .doc('flaggedContent')
          .collection(contentType)
          .add({
        'contentId': contentId,
        'reason': reason,
        'metadata': metadata ?? {},
        'status': 'pending_review',
        'flaggedAt': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log the action
      await logSystemEvent(
        eventType: 'CONTENT_FLAGGED',
        description: '$contentType flagged for review: $reason',
        metadata: {
          'contentType': contentType,
          'contentId': contentId,
          'reason': reason
        },
        itemId: contentId,
      );
    } catch (e) {
      throw Exception('Failed to flag content: $e');
    }
  }

  /// Get flagged content for admin review
  Stream<List<Map<String, dynamic>>> getFlaggedContent(String contentType) {
    return _firestore
        .collection(_adminCollection)
        .doc('flaggedContent')
        .collection(contentType)
        .where('status', isEqualTo: 'pending_review')
        .orderBy('flaggedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}
