# Implementation Plan - Fix Cleaner Dashboard Requests and Student Order List Refresh

This plan details the technical steps to address two critical bugs in the Hostel Hub codebase:
1. **Cleaning requests are not appearing on the cleaner dashboard**.
2. **The student dashboard's order list does not refresh when an order is updated (e.g., marked as delivered) in the canteen staff dashboard**.

---

## User Review Required

> [!IMPORTANT]
> To fix the **cleaner dashboard requests visibility**, a Supabase Row-Level Security (RLS) policy update is required. Currently, staff roles (`'cleaner'`, `'canteen'`, `'maintenance'`) do not have SELECT permission on the `profiles` table for other users.
>
> When the cleaner dashboard fetches cleaning requests joined with student profiles, Supabase returns `null` for the `profiles` object, which fails the `profile != null` check in `cleaning_dashboard.dart`, filtering out all requests.
>
> **Action Required**: You will need to run a quick SQL command in the Supabase SQL Editor. The exact SQL script is provided below in the proposed changes.

---

## Open Questions

*No open questions. The technical causes and solutions have been fully mapped out.*

---

## Proposed Changes

### 1. Supabase Database Schema & RLS Policies

#### [MODIFY] [supabase_schema.sql](file:///C:/Users/APOORV/OneDrive/Desktop/HostelHub/hostel_hub_updated/supabase_schema.sql)
- Update the `profiles` SELECT policy to allow all staff roles (`'warden'`, `'admin'`, `'cleaner'`, `'canteen'`, `'maintenance'`) to view student profile fields. This allows the cleaner dashboard and canteen/maintenance portals to read student names, hostel names, room numbers, and colleges to fulfill requests and deliveries.

```sql
-- Wardens, Admins, Cleaners, Canteen, and Maintenance can view profiles
CREATE POLICY "Staff, Wardens, and Admins view all profiles" ON public.profiles 
  FOR SELECT USING (public.get_user_role(auth.uid()) IN ('warden', 'admin', 'cleaner', 'canteen', 'maintenance'));
```

- **SQL Migration Script** (To be run by the user or applied directly in Supabase):
  ```sql
  DROP POLICY IF EXISTS "Wardens and Admins view all profiles" ON public.profiles;
  
  CREATE POLICY "Staff, Wardens, and Admins view all profiles" ON public.profiles 
    FOR SELECT USING (public.get_user_role(auth.uid()) IN ('warden', 'admin', 'cleaner', 'canteen', 'maintenance'));
  ```

---

### 2. Flutter State Management

#### [MODIFY] [app_provider.dart](file:///C:/Users/APOORV/OneDrive/Desktop/HostelHub/hostel_hub_updated/lib/providers/app_provider.dart)
- Set up Supabase Realtime subscriptions using `_supabase.channel().onPostgresChanges()` for changes on tables:
  - `orders`
  - `service_requests`
  - `maintenance_requests`
- Automatically call `_fetchOrders()` or `_fetchRequests()` and trigger `notifyListeners()` when database updates occur.
- Add `_setupRealtimeSubscriptions()` helper method and trigger it upon successful login/auth state initialization.
- Add `_cancelRealtimeSubscriptions()` helper method and invoke it inside the `logout()` method to clean up channels and avoid memory leaks.
- Implement the manual trigger methods `refreshOrders()` and `refreshRequests()`.

---

### 3. Student UI Enhancements

#### [MODIFY] [my_orders_screen.dart](file:///C:/Users/APOORV/OneDrive/Desktop/HostelHub/hostel_hub_updated/lib/screens/orders/my_orders_screen.dart)
- Wrap both the **Active Orders** and **Past Orders** list views in a `RefreshIndicator` widget.
- Configure the `onRefresh` callback to invoke `AppProvider.refreshOrders()`, letting students manually pull to refresh their orders list in case of network fluctuations.

---

## Verification Plan

### Automated & Compilation Verification
- Run `flutter analyze` or ensure zero compiler errors in the updated files.

### Manual Verification
1. **Apply the SQL Fix**:
   Execute the migration snippet in your Supabase SQL Editor.
2. **Verify Cleaner Dashboard Requests**:
   - Log in as a student, submit a new room cleaning request.
   - Log in as a cleaner from the same college campus.
   - Verify that the cleaning request appears instantly with student details (name, room, hostel).
3. **Verify Student Dashboard Refresh**:
   - Log in as a student on one device and place an order.
   - Log in as canteen staff on another.
   - Mark the order as delivered.
   - Verify that the student's order status updates instantly without restarting the app or manual reload.
