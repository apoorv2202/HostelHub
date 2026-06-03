# Checklist - Real-time Status Sync & Squidex Food Photos

- [x] Update `FoodItem` model to support `imageUrl`
- [x] Implement image field parsing in `SquidexService`
- [x] Add `imageUrl: null` or propagate `imageUrl` to mock data and provider helpers
- [x] Fix mapping of `lost_requests` status in `AppProvider`
- [x] Implement real-time postgres subscriptions for student requests in `AppProvider`
- [x] Update requests screen UI status chip and progress bar rendering for Lost Cards
- [x] Update student Night Canteen screen to render Network Image if available
- [x] Update Canteen Dashboard menu tab to render Network Image if available
- [x] Exclude approved (in-progress) Lost Card requests from the Home Screen active requests counter
- [x] Verify the build and execution of the application
