# Tracking Timeline Icons Update

## Summary
Updated the delivery tracking timeline to use more intuitive icons:
- **Picked Up**: Changed from flight_takeoff to handshake icon
- **In Transit**: Now dynamic based on traveler's transportation mode

## Changes Made

### 1. `tracking_timeline_widget.dart`
- Added `TransportMode?` parameter to accept optional transport mode
- Changed "Picked Up" icon from `Icons.flight_takeoff` to `Icons.handshake_outlined`
- Made "In Transit" icon dynamic using new `_getTransportIcon()` method
- Added `_getTransportIcon()` method that returns appropriate icon based on transport mode:
  - Flight: ✈️ `Icons.flight`
  - Train: 🚆 `Icons.train`
  - Bus: 🚌 `Icons.directions_bus`
  - Car: 🚗 `Icons.directions_car`
  - Ship: 🚢 `Icons.directions_boat`
  - Motorcycle: 🏍️ `Icons.motorcycle`
  - Bicycle: 🚲 `Icons.directions_bike`
  - Walking: 🚶 `Icons.directions_walk`
  - Default (if no mode): 🚚 `Icons.local_shipping`

### 2. `package_tracking_screen.dart`
- Added import for `TravelTrip` model
- Added `_travelTrip` state variable to store trip information
- Updated `_loadTrackingData()` to fetch the traveler's active trip
- Queries `travelTrips` collection by `travelerId` and `status: 'active'`
- Passes `transportMode` to `TrackingTimelineWidget`

## How It Works

1. When tracking data loads, the screen fetches the traveler's active trip
2. Extracts the `transportMode` from the trip
3. Passes it to the timeline widget
4. Timeline widget displays the appropriate transport icon in "In Transit" step
5. If no trip is found or transport mode is unavailable, defaults to truck icon

## Benefits

- More intuitive icons that match the actual transportation method
- Handshake icon better represents the pickup moment (agreement/exchange)
- Dynamic transport icons provide better context to users
- Maintains backwards compatibility (falls back to default if no transport mode)

## Testing Notes

- Verify icons appear correctly for all transport modes
- Test with packages that have no associated trip (should show default icon)
- Check that handshake icon appears for "Picked Up" status
- Ensure animations still work smoothly with new icons
