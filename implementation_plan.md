# Implementation Plan - Fix Lost Card Status and Squidex Food Photos

This plan outlines the changes required to address the two issues raised by the user:
1. **Lost Card Request Status**: Correctly mapping and displaying the "Approved" status of a student's lost card request when a Warden approves it.
2. **Squidex Food Item Photos**: Correctly fetching and displaying food item images uploaded in Squidex inside the Night Canteen dashboards (both for students and canteen staff).

---

## Proposed Changes

### Component 1: Models and Service Layer (Squidex Image URL Integration)

We will update the model `FoodItem` to include `imageUrl` and parse it dynamically from the Squidex API.

#### [MODIFY] [models.dart](file:///C:/Users/APOORV/OneDrive/Desktop/HostelHub/hostel_hub_updated/lib/models/models.dart)
- Add `final String? imageUrl` to the `FoodItem` class.
- Update the constructor to accept `this.imageUrl`.

#### [MODIFY] [squidex_service.dart](file:///C:/Users/APOORV/OneDrive/Desktop/HostelHub/hostel_hub_updated/lib/services/squidex_service.dart)
- Parse image assets from Squidex response. Check common image field names (`image`, `photo`, `picture`, `imageUrl`, `image_url`) under `fieldData` and construct the public asset URL (`https://cloud.squidex.io/api/assets/{appName}/{assetId}`).
- Support fallback to direct URLs if the field contains a full HTTP link.

---

### Component 2: Application Provider (Real-time and Status Mappings)

#### [MODIFY] [app_provider.dart](file:///C:/Users/APOORV/OneDrive/Desktop/HostelHub/hostel_hub_updated/lib/providers/app_provider.dart)
- Modify `_fetchRequests()` mapping for `lost_requests`:
  - Properly map `status == 'rejected'` to `RequestStatus.rejected` (currently it defaults to `RequestStatus.pending`).
  - Maintain `status == 'approved'` mapping to `RequestStatus.inProgress`.
- Update all instances of `FoodItem` creation (`_getFallbackFoodItems` and stock toggle overrides) to include `imageUrl: old.imageUrl` or `imageUrl: null`.
- Add a new subscription channel `_requestsChannel` in `_subscribeToRequests()` to listen to real-time insert/update/delete events on `service_requests`, `maintenance_requests`, and `lost_requests`. Trigger a fetch on changes to reflect warden/staff updates instantly on the student dashboard.
- Unsubscribe from `_requestsChannel` in the `logout()` method.

---

### Component 3: User Interface (Dashboard Rendering)

We will modify the UI to correctly represent status changes and render images.

#### [MODIFY] [my_requests_screen.dart](file:///C:/Users/APOORV/OneDrive/Desktop/HostelHub/hostel_hub_updated/lib/screens/requests/my_requests_screen.dart)
- Update `_buildStatusChip` inside `_RequestCard`:
  - If `request.category == 'Lost Card'` and `request.status == RequestStatus.inProgress`, display a green chip with the label "Approved" using `StatusChip(label: 'Approved', bgColor: Color(0x2622C55E), textColor: Color(0xFF22C55E), icon: Icons.check_circle_rounded)`.
- Hide the "Staff on their way..." progress bar indicator if `request.category == 'Lost Card'` (i.e. check `request.status == RequestStatus.inProgress && request.category != 'Lost Card'`).

#### [MODIFY] [night_canteen_screen.dart](file:///C:/Users/APOORV/OneDrive/Desktop/HostelHub/hostel_hub_updated/lib/screens/services/night_canteen_screen.dart)
- In `_FoodItemCard`, check if `item.imageUrl` is provided. If so, display it using `Image.network` with a loading spinner and an error fallback that displays the text emoji. Otherwise, show the default emoji.

#### [MODIFY] [canteen_dashboard.dart](file:///C:/Users/APOORV/OneDrive/Desktop/HostelHub/hostel_hub_updated/lib/screens/canteen_dashboard.dart)
- In the canteen dashboard menu tab, similarly replace the static emoji rendering with a container rendering the `Image.network` (with fallback to emoji if null or failed).

#### [MODIFY] [constants.dart](file:///C:/Users/APOORV/OneDrive/Desktop/HostelHub/hostel_hub_updated/lib/utils/constants.dart)
- Update the mock items list (`mockFoodItems`) to include the new `imageUrl` field.

---

## Verification Plan

### Automated / Build Verification
- Build and run the project using standard Flutter build tools to ensure no compilation/syntax issues.

### Manual Verification
- Log in as student to check that the Night Canteen loads images for items with uploaded Squidex assets and falls back to emojis gracefully.
- Log in as Warden, approve a Lost Card request for a student.
- Check the student's My Requests tab: the request status should update in real-time to "Approved" with a green chip, and no "Staff on their way" progress bar should be visible.
