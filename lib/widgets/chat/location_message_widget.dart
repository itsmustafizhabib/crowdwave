import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/chat_message.dart';
import '../../services/location_service.dart';

class LocationMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;

  const LocationMessageWidget({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final latitude = message.metadata?['latitude'] as double?;
    final longitude = message.metadata?['longitude'] as double?;
    final address = message.metadata?['address'] as String?;
    final isLiveLocation = message.metadata?['isLiveLocation'] as bool? ?? false;

    if (latitude == null || longitude == null) {
      return _buildErrorWidget();
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFF215C5C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map preview with clickable overlay
          GestureDetector(
            onTap: () => _openInGoogleMaps(latitude, longitude, address),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Image.network(
                      _getStaticMapUrl(latitude, longitude),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.location_on,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFF215C5C),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Live location indicator
                if (isLiveLocation)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Play button overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Location details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: isCurrentUser ? Colors.white : const Color(0xFF215C5C),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address ?? 'Location',
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  LocationService().formatCoordinates(latitude, longitude),
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openInGoogleMaps(latitude, longitude, address),
                        icon: Icon(
                          Icons.map,
                          size: 16,
                          color: isCurrentUser ? Colors.white : const Color(0xFF215C5C),
                        ),
                        label: Text(
                          'Open',
                          style: TextStyle(
                            color: isCurrentUser ? Colors.white : const Color(0xFF215C5C),
                            fontSize: 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isCurrentUser ? Colors.white : const Color(0xFF215C5C),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _getDirections(latitude, longitude),
                        icon: Icon(
                          Icons.directions,
                          size: 16,
                          color: isCurrentUser ? Colors.white : const Color(0xFF215C5C),
                        ),
                        label: Text(
                          'Directions',
                          style: TextStyle(
                            color: isCurrentUser ? Colors.white : const Color(0xFF215C5C),
                            fontSize: 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isCurrentUser ? Colors.white : const Color(0xFF215C5C),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFF215C5C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: isCurrentUser ? Colors.white : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            'Location unavailable',
            style: TextStyle(
              color: isCurrentUser ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _getStaticMapUrl(double latitude, double longitude) {
    // Using Google Static Maps API
    // Note: In production, you should use your own API key
    final zoom = 15;
    final size = '600x300';
    final marker = 'color:red%7C$latitude,$longitude';
    
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$latitude,$longitude&'
        'zoom=$zoom&'
        'size=$size&'
        'markers=$marker&'
        'key=YOUR_API_KEY'; // Replace with actual API key or use alternative
    
    // Alternative: OpenStreetMap static map (no API key needed)
    // return 'https://www.openstreetmap.org/export/embed.html?bbox=${longitude - 0.01},${latitude - 0.01},${longitude + 0.01},${latitude + 0.01}&layer=mapnik&marker=$latitude,$longitude';
  }

  Future<void> _openInGoogleMaps(double latitude, double longitude, String? address) async {
    final url = LocationService().getGoogleMapsUrl(latitude, longitude, label: address);
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _getDirections(double latitude, double longitude) async {
    final url = LocationService().getDirectionsUrl(latitude, longitude);
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
