# Technical Walkthrough — Multi-Role Hostel Hub

We have successfully implemented the multi-role system matching the final Supabase DDL schema. The application now supports **Warden**, **Student**, **Cleaner**, **Canteen**, and **Maintenance** roles with dynamic database and CMS bindings.

---

## 1. Flow & Screen Architecture

### Entry & Role Selection
- **`RoleSelectionScreen`**: When entering the app, the user is greeted with a sleek "Who are you?" selector.
  - Selecting **Student** routes to `PhoneLoginScreen` (phone number + OTP).
  - Selecting any other staff role routes to `StaffIdLoginScreen` (ID Card login).
- **`StaffIdLoginScreen`**: A premium dark-themed card screen where staff verify themselves using their **ID Card / Staff ID**.

### Swapped Verification Flow
- **Student & Staff Pending Screen**: When students and non-warden staff register, their status is set to `pending`. They are redirected to `PendingVerificationScreen` and cannot log in until approved.
- **Warden Auto-Verification**: Wardens get registered as `verified` directly and bypass the pending screen to log in immediately.

### Dashboards & Scoping
1. **Warden Dashboard (`admin_dashboard.dart`)**:
   - Fetches and displays all registered students on their campus.
   - Lists lost mess card and ID card requests.
   - Allows Warden to verify/approve pending registrations.
   - **Interactive Document Viewer (New)**: Wardens can inspect simulated ID Cards and Mess Cards inside high-fidelity visual overlays.
2. **Cleaner Dashboard (`cleaning_dashboard.dart`)**:
   - Cleaners see and accept room-cleaning requests from students at their college.
   - Can update request status to accepted/completed.
3. **Canteen Dashboard (`canteen_dashboard.dart`)**:
   - Canteen staff see orders placed specifically at their campus canteen (e.g. RVCE canteen staff only see RVCE orders).
   - Allows advancing orders from accepted -> preparing -> ready -> completed.
   - **Menu Management Tab (New)**: Toggles item availability ("In Stock" / "Out of Stock") dynamically, propagating to student night canteen instantly.
4. **Maintenance Dashboard (`maintenance_dashboard.dart`)**:
   - Technicians see electricians and furniture repair requests uploaded by students.
   - Displays student name, room, hostel, and description of broken fans or electrical appliances.
   - **Premium Verified Photo Gradients (New)**: Replaced broken placeholder images with gorgeous styled category tags and dynamic icons.

---

## 2. Dynamic Supabase & Squidex Scoping

- **College Scoping**: Enforced both via RLS policies in the Supabase schema and checked programmatically in the Dart state layer:
  - Canteens filter orders by `college = user.college`.
  - Wardens, Cleaners, and Maintenance only retrieve requests and profiles belonging to their college.
- **Rogue Student Prevention**: Enforced via Supabase RLS policies and implemented in `AppProvider` to ensure students can only view or insert their own requests.
- **Lost Requests Integration**: Student `lost_items_screen.dart` inserts directly to Supabase `lost_requests` which propagates instantly to the Warden Dashboard in real-time.
- **Instant Logout (New)**: Clears all local state instantly and runs Supabase sign-out asynchronously in a background worker, removing the lag completely.

---

## 3. Real-Time Scoping & Dashboard Refresh Fixes (Latest turn)

### 🔓 Cleaner Dashboard Request Visibility Fix (RLS Update)
* **Problem**: The cleaner dashboard fetches `service_requests` joined with the `profiles` table to render student details. Since the database's original `SELECT` policy on the `profiles` table was restricted to wardens and admins, cleaners received `null` profiles. This failed the frontend's safety check (`profile != null`), completely hiding all room cleaning requests from the cleaner's dashboard.
* **Fix**: Updated `profiles` table SELECT policy in `supabase_schema.sql` to explicitly allow all staff roles (warden, admin, cleaner, canteen, and maintenance):
  ```sql
  CREATE POLICY "Staff, Wardens, and Admins view all profiles" ON public.profiles 
    FOR SELECT USING (public.get_user_role(auth.uid()) IN ('warden', 'admin', 'cleaner', 'canteen', 'maintenance'));
  ```

### 🔄 Student Dashboard Refresh Buttons
* **Problem**: Stale order lists and request trackers inside the student dashboard.
* **Fix**: Added high-fidelity **Refresh Icon Buttons** to the student's `MyOrdersScreen` and `MyRequestsScreen` AppBars.
  - Exposed `refreshOrders()` and `refreshRequests()` methods in `AppProvider` to pull the latest state from Supabase, matching the manual refresh flow of other staff dashboards (maintenance, canteen, cleaner).
