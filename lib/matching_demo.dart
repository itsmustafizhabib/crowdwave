import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import '../controllers/matching_controller.dart';
import '../core/models/models.dart';
import '../presentation/screens/matching/matching_screen.dart';

class MatchingDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Matching System Demo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'CrowdWave Smart Matching System',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'AI-powered matching between packages and travelers with advanced filtering and nearby suggestions.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),

            SizedBox(height: 3.h),

            // Features Section
            _buildFeatureSection(),

            SizedBox(height: 3.h),

            // Demo Actions
            _buildDemoActions(context),

            SizedBox(height: 3.h),

            // How it works
            _buildHowItWorksSection(),

            SizedBox(height: 3.h),

            // Matching Algorithm Details
            _buildAlgorithmDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✨ Key Features',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildFeatureItem(
              Icons.auto_awesome,
              'Auto-Matching',
              'AI algorithm finds the best travelers for your package based on multiple factors',
            ),
            _buildFeatureItem(
              Icons.explore,
              'Manual Browsing',
              'Browse and filter available trips manually with advanced search options',
            ),
            _buildFeatureItem(
              Icons.location_on,
              'Nearby Suggestions',
              'Discover packages and trips in your vicinity with location-based recommendations',
            ),
            _buildFeatureItem(
              Icons.filter_list,
              'Smart Filters',
              'Filter by date, size, rating, transport mode, distance, and verification status',
            ),
            _buildFeatureItem(
              Icons.score,
              'Match Scoring',
              'Each match gets a compatibility score (0-100%) based on multiple criteria',
            ),
            _buildFeatureItem(
              Icons.sync,
              'Real-time Updates',
              'Live notifications when new matches are found or status changes occur',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(Get.context!).primaryColor,
            size: 6.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚀 Try it Out',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),

            // Demo with sample package
            ElevatedButton.icon(
              onPressed: () => _launchMatchingWithSamplePackage(),
              icon: Icon(Icons.inventory),
              label: Text('Demo: Find Matches for Sample Package'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 2.h),

            // Demo as traveler
            ElevatedButton.icon(
              onPressed: () => _launchMatchingForTraveler(),
              icon: Icon(Icons.directions_car),
              label: Text('Demo: Browse as Traveler'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 2.h),

            // View nearby suggestions
            ElevatedButton.icon(
              onPressed: () => _showNearbyDemo(),
              icon: Icon(Icons.near_me),
              label: Text('Demo: Nearby Suggestions'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚙️ How It Works',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildStepItem(1, 'Package Posted',
                'User posts a package with details like size, weight, destination, and preferred delivery date'),
            _buildStepItem(2, 'Auto-Matching Triggered',
                'System automatically searches for suitable travelers based on routes and capacity'),
            _buildStepItem(3, 'Score Calculation',
                'Each potential match gets scored based on distance, date compatibility, traveler rating, and other factors'),
            _buildStepItem(4, 'Match Presentation',
                'Best matches are presented to both sender and traveler with detailed compatibility information'),
            _buildStepItem(5, 'Accept/Negotiate',
                'Users can accept matches, negotiate prices, or reject with reasons for better future matches'),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int step, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: Theme.of(Get.context!).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlgorithmDetails() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧠 Matching Algorithm',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Our smart matching algorithm considers multiple factors to find the best traveler-package combinations:',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 2.h),
            _buildAlgorithmFactor('Distance Match', '40%',
                'Pickup and delivery locations proximity to traveler\'s route'),
            _buildAlgorithmFactor('Date Compatibility', '20%',
                'How well the delivery timeline matches travel dates'),
            _buildAlgorithmFactor('Traveler Rating', '15%',
                'Historical performance and user reviews'),
            _buildAlgorithmFactor('Package Compatibility', '15%',
                'Size and weight compatibility with traveler\'s capacity'),
            _buildAlgorithmFactor('Price Match', '10%',
                'Compensation offered vs traveler\'s expectations'),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    '📊 Match Score Ranges',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreRange('80-100%', 'Excellent', Colors.green),
                      _buildScoreRange('60-79%', 'Good', Colors.orange),
                      _buildScoreRange('30-59%', 'Fair', Colors.red),
                      _buildScoreRange('<30%', 'Poor', Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlgorithmFactor(
      String factor, String weight, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Container(
            width: 20.w,
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Theme.of(Get.context!).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              weight,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(Get.context!).primaryColor,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRange(String range, String label, Color color) {
    return Column(
      children: [
        Text(
          range,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: color,
          ),
        ),
      ],
    );
  }

  // Demo action methods
  void _launchMatchingWithSamplePackage() {
    // Create a sample package request
    final samplePackage = PackageRequest(
      id: 'demo_package_001',
      senderId: 'demo_sender',
      senderName: 'Demo User',
      senderPhotoUrl: 'https://via.placeholder.com/150',
      packageDetails: PackageDetails(
        type: PackageType.documents,
        description: 'Important business documents',
        size: PackageSize.small,
        weightKg: 0.5,
        valueUSD: 100,
        isFragile: false,
      ),
      pickupLocation: Location(
        address: '123 Business Street, San Francisco, CA',
        latitude: 37.7749,
        longitude: -122.4194,
        city: 'San Francisco',
        state: 'California',
        country: 'USA',
      ),
      destinationLocation: Location(
        address: '456 Office Plaza, Los Angeles, CA',
        latitude: 34.0522,
        longitude: -118.2437,
        city: 'Los Angeles',
        state: 'California',
        country: 'USA',
      ),
      preferredDeliveryDate: DateTime.now().add(Duration(days: 3)),
      compensationOffer: 25.0,
      isUrgent: false,
      specialInstructions:
          'Please handle with care - contains sensitive documents',
      status: PackageStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Navigate to matching screen with sample package
    Get.to(() => MatchingScreen(
          packageId: samplePackage.id,
          packageRequest: samplePackage,
        ));

    Get.snackbar(
      'Demo Started',
      'Searching for matches for sample package from SF to LA',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _launchMatchingForTraveler() {
    Get.to(() => MatchingScreen(
          travelerId: 'demo_traveler_001',
        ));

    Get.snackbar(
      'Traveler View',
      'Browsing packages as a traveler',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _showNearbyDemo() {
    Get.to(() => MatchingScreen());

    // Simulate loading nearby suggestions
    final controller = Get.find<MatchingController>();
    controller.loadNearbyPackages(latitude: 37.7749, longitude: -122.4194);
    controller.loadNearbyTrips(latitude: 37.7749, longitude: -122.4194);

    Get.snackbar(
      'Nearby Demo',
      'Showing packages and trips near San Francisco',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }
}
