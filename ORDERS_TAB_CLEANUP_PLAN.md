# Orders Screen Tab Structure Cleanup Plan

## Current Problem
- Orders screen has 4 tabs: Active, Complete, Cancelled, **Tracking**
- The Tracking tab embeds TrackingHistoryScreen which has its own 4 tabs
- This creates confusing nested navigation

## Proposed Solution

### Option 1: Merge Tracking into Order Tabs
Remove the separate "Tracking" tab and integrate tracking info into existing order tabs:

**Orders Screen Tabs (3 instead of 4):**
1. **Active** - Show active orders WITH their tracking status
2. **Complete** - Show completed orders WITH delivery confirmation
3. **Cancelled** - Show cancelled orders

### Option 2: Replace Orders Tabs with Combined View
Completely redesign to have unified order/delivery status:

**Orders Screen Tabs (4 unified tabs):**
1. **Pending** - Orders awaiting pickup/confirmation  
2. **In Transit** - Orders being delivered (with tracking)
3. **Delivered** - Successfully completed orders
4. **Cancelled** - Cancelled orders

### Option 3: Separate Navigation 
Keep Orders and Tracking as separate screens in bottom navigation instead of nested tabs.

## Recommended: Option 1 (Merge Tracking into Orders)

### Benefits:
- Eliminates nested tabs confusion
- Shows tracking info where users expect it (with their orders)
- Cleaner UX - one level of navigation
- More intuitive - users want to see order status, not separate tracking

### Implementation:
1. Remove "Tracking" tab from Orders screen
2. Enhance order cards to show tracking status
3. Add "Track" button on order cards to navigate to detailed tracking
4. Remove TrackingHistoryScreen from Orders tab