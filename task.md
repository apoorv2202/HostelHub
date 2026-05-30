# Checklist of Completed Work

- [x] Create visually stunning "Who are you?" landing/role selection screen (`role_selection_screen.dart`)
- [x] Create premium Staff ID Login screen (`staff_id_login_screen.dart`)
- [x] Adapt `UserRole` and `AppUser` in `lib/models/user.dart` to support 5 distinct roles: Warden, Student, Cleaner, Canteen, Maintenance
- [x] Update `UserModel` inside `lib/models/user_model.dart` to include roles and verification status
- [x] Add ID Card login logic (`loginWithIdCard`) inside `AppProvider`
- [x] Scoping and dynamic filters in `AppProvider` requests & orders queries matching Supabase DDL policies
- [x] Connect Canteen Dashboard (`canteen_dashboard.dart`) to live orders scoped dynamically to the canteen's college campus
- [x] Connect Warden Dashboard (`admin_dashboard.dart`) to live student profiles, approvals, and lost card requests scoped to Warden's college campus
- [x] Connect Cleaner Dashboard (`cleaning_dashboard.dart`) to live room cleaning requests scoped by college campus
- [x] Create Maintenance Dashboard (`maintenance_dashboard.dart`) for viewing broken fans and electrical appliance fixes
- [x] Connect Student Lost card payment screen to write directly to Supabase `lost_requests` table
- [x] Update `main.dart` with routing logic based on dynamic authentication states and user roles
- [x] Fix compilation errors related to AppTheme theme property mappings in dashboards
- [x] Fix compilation errors by upgrading CardTheme to CardThemeData in `app_theme.dart`
- [x] Resolve compilation errors by cleaning up deprecated `login_screen.dart` code
- [x] Fix undefined Supabase getter in `lost_items_screen.dart` by adding packages import

## Current Phase: Fine-tuning and Real-time Scoping

- [x] Swap verification flow: Wardens register as `verified` directly; Students and other staff go to pending screen.
- [x] Optimize `logout()` to instantly update UI and signOut asynchronously.
- [x] Implement Canteen Menu tab in Canteen Dashboard for stock ("In Stock" / "Out of Stock") toggles.
- [x] Integrate menu stock status in Student Night Canteen screen.
- [x] Add interactive document viewer (College ID Card & Mess Card) in Warden Approvals.
- [x] Upgrade Maintenance request visual indicators in Maintenance Dashboard.

## Current Phase: Cleaner and Canteen Refresh Fixes

- [x] Update `profiles` select policy in `supabase_schema.sql` to include staff roles (cleaner, canteen, maintenance).
- [x] Add refresh icon button in student MyOrdersScreen and MyRequestsScreen AppBars.
