# TODO Sprint Plan - IOS Scale App

**Creation Date:** December 14, 2025  
**Priorities:** FaceID → Reset Behavior → Layout → iCloud

---

## 🔴 Sprint 15: FaceID Lock - Complete Removal

**Branch:** `fix/sprint-15-remove-faceid`

### Steps
1. Remove FaceID Lock option from `SettingsView.swift`
2. Remove `BiometricAuthService` if it exists
3. Remove LocalAuthentication dependencies if not used elsewhere
4. Clean up references in models/services
5. Test that the app no longer crashes

### Deliverables
- [ ] Code with no references to FaceID/TouchID
- [ ] Settings functional without biometric lock option
- [ ] Stable app on iPhone and iPad

### Success Criteria
- ✅ No crash on launch
- ✅ Settings display correctly without FaceID option
- ✅ No compilation errors related to LocalAuthentication
- ✅ Manual tests on iPhone Air and iPad Pro 13" successful

---

## 🟡 Sprint 16: Reset Behavior - Fix Implementation

**Branch:** `fix/sprint-16-reset-behavior`

### Root Cause (Critical Bug Found!)
**Two conflicting storage systems are used:**
1. `SettingsView.swift` uses `@AppStorage("reset_behavior")` → writes to `UserDefaults["reset_behavior"]`
2. `BasicIOSViewModel` calls `AppSettings.load()` → reads from `UserDefaults["app_settings"]` (JSON encoded struct)

**These two systems NEVER communicate!** When user changes Reset Behavior in Settings, it writes to one key, but ViewModels read from a completely different key with default values.

### Additional Issues
1. **`keepPosition` is broken**: The case just does `break` without any mechanism to save/restore the previous position
2. **No persistence**: There's no code to save the last position to UserDefaults or SwiftData
3. **Implementation exists but doesn't work** in ANY of the 9 metrics (not just 5 as previously thought)

### Affected Files
- ❌ ALL 9 ViewModels read from wrong storage key
- ❌ `SettingsView.swift` writes to `@AppStorage("reset_behavior")`
- ❌ `AppSettings.swift` reads from `"app_settings"` JSON blob

### Solution Options
**Option A: Unify on @AppStorage** (Recommended)
1. Remove `AppSettings.load()` pattern from ViewModels
2. Use `@AppStorage("reset_behavior")` directly in ViewModels
3. Add `@AppStorage("last_position_metric01")` etc. for keepPosition

**Option B: Unify on AppSettings struct**
1. Modify SettingsView to use `AppSettings.load()`/`save()` instead of @AppStorage
2. Add lastPosition fields to AppSettings struct

### Steps
1. Choose storage approach (Option A recommended)
2. Fix BasicIOSViewModel to read from correct storage
3. Implement `keepPosition` properly with position persistence
4. Apply fix to all 9 ViewModels
5. Test all 3 behavior options on all metrics

### Deliverables
- [ ] Unified storage system (no more conflicts)
- [ ] `keepPosition` properly saves and restores last position
- [ ] `resetToDefault` works on all 9 metrics
- [ ] `randomPosition` works on all 9 metrics
- [ ] All ViewModels use consistent approach

### Success Criteria
- ✅ Change setting in Settings → immediately reflected in metric behavior
- ✅ Keep Position: Position persists after saving measurement
- ✅ Reset to Default: Circles reset to 0.5 after saving
- ✅ Random Position: Random value generated after saving
- ✅ Setting persists after app restart
- ✅ Consistent behavior on ALL 9 metrics
- ✅ Tests on iPhone and iPad successful

---

## 🟢 Sprint 17: iPad Menu - Card Toggle & Buttons

**Branch:** `fix/sprint-17-ipad-menu-card`

### Current Issue
On iPad, the card has no chevron (unlike iPhone's "Read More" chevron). When tapping the card, it switches to "compact" mode and buttons become inaccessible. Tapping again does not restore the full mode.

### Required Changes
1. **Toggle functionality**: Allow smooth toggle between compact and full mode on iPad
2. **Always show buttons**: Buttons must remain accessible even in compact mode (only animation and description should disappear)

### Steps
1. Analyze `HomeView.swift` and modality card component
2. **Change 1:** Make toggle between compact/full mode work properly on iPad
3. **Change 2:** Keep buttons visible/accessible in compact mode (only animation and description disappear)
4. Test tap behavior on iPad vs iPhone
5. Harmonize UX between both platforms

### Deliverables
- [ ] Card toggleable between compact/full mode on iPad
- [ ] Buttons always visible/accessible in both modes
- [ ] Animation and description disappear in compact mode
- [ ] Intuitive tap behavior

### Success Criteria
- ✅ Tap on iPad card: smooth toggle between modes
- ✅ "Start Measurement" and "View History" buttons always accessible
- ✅ Circle animation disappears in compact mode
- ✅ Description disappears in compact mode
- ✅ No regression on iPhone
- ✅ Tests on iPad Pro 13" in portrait and landscape

---

## 🟠 Sprint 18: Layout - iPhone Landscape (Part 1)

**Branch:** `fix/sprint-18-iphone-landscape-layout-1`

### Affected Metrics
- Metric 02 (Advanced IOS)
- Metric 03 (Overlap)
- Metric 04 (Set Membership)
- Metric 05 (Proximity)

### Issues to Fix
- "Cramped" interface without scroll
- Invisible/inaccessible buttons
- Element overlaps
- Need ScrollView with landscape adaptation

### Steps
1. Add `GeometryReader` to detect orientation
2. Wrap content in `ScrollView` for landscape mode
3. Reduce vertical spacing in landscape
4. Test each metric individually
5. Ensure all buttons are visible

### Deliverables (per metric)
- [ ] **Metric 02:** Functional ScrollView, visible buttons, accessible sliders
- [ ] **Metric 03:** Functional ScrollView, non-cramped interface
- [ ] **Metric 04:** Functional ScrollView, no overlap
- [ ] **Metric 05:** Functional ScrollView, visible buttons

### Success Criteria
- ✅ All metrics scrollable in iPhone landscape
- ✅ All buttons (Done, Reset, etc.) visible and accessible
- ✅ No interface overlap
- ✅ Adapted but consistent spacing
- ✅ No regression in portrait
- ✅ Tests on iPhone Air in landscape

---

## 🟠 Sprint 19: Layout - iPhone Landscape (Part 2)

**Branch:** `fix/sprint-19-iphone-landscape-layout-2`

### Affected Metrics
- Metric 06 (Identification)
- Metric 07 (Projection)
- Metric 08 (Attribution)
- Metric 09 (Observation)

### Issues to Fix
- "Cramped" interface without scroll
- Invisible buttons
- Strange arrow behavior (Metrics 06, 07)
- Uncontrollable drag (Metrics 08, 09)

### Steps
1. Same approach as Sprint 18: `GeometryReader` + `ScrollView`
2. Fix arrow behavior (Metrics 06, 07)
3. Improve drag control (Metrics 08, 09)
4. Test each metric

### Deliverables (per metric)
- [ ] **Metric 06:** ScrollView, fixed arrow, controllable drag
- [ ] **Metric 07:** ScrollView, fixed arrow, controllable drag
- [ ] **Metric 08:** ScrollView, controllable drag
- [ ] **Metric 09:** ScrollView, controllable drag

### Success Criteria
- ✅ All metrics scrollable in iPhone landscape
- ✅ Arrow in the middle has consistent behavior (06, 07)
- ✅ Drag offers better control
- ✅ All buttons accessible
- ✅ Non-cluttered interface
- ✅ Tests on iPhone Air in landscape

---

## 🟣 Sprint 20: Layout - iPad Vertical Centering

**Branch:** `fix/sprint-20-ipad-vertical-centering`

### Affected Metrics
All metrics with "better use of space" and "circles too close to top" comments

### Issue
On iPad (portrait and landscape), circles are too close to the top of the screen, space is poorly used.

### Steps
1. Use same approach as onboarding (GeometryReader + minHeight)
2. Center main content vertically (circles + slider)
3. Keep buttons at the bottom
4. Test on iPad Pro 13" in portrait and landscape
5. Ensure it doesn't affect iPhone

### Deliverables
- [ ] All metrics with vertically centered circles on iPad
- [ ] Well-used space in portrait and landscape
- [ ] No iPhone regression

### Success Criteria
- ✅ Circles centered vertically on iPad portrait
- ✅ Circles centered vertically on iPad landscape
- ✅ Balanced and harmonious interface
- ✅ No regression on iPhone (portrait and landscape)
- ✅ Tests on iPad Pro 13" successful

---

## 🔵 Sprint 21: UX - Pinch Gesture Replacement (Metric 02)

**Branch:** `feature/sprint-21-replace-pinch-advanced-ios`

### Issue
Pinch on Metric 02 (Advanced IOS) is uncontrollable, radical, doesn't work on iPhone portrait.

### Steps
1. Analyze `AdvancedIOSView.swift` and the pinch gesture
2. Replace pinch with two vertical or horizontal sliders:
   - Option A: Vertical sliders on each side of circles
   - Option B: Horizontal sliders side by side under circles
3. Harmonize with existing proximity slider
4. Test on iPhone and iPad

### Deliverables
- [ ] Pinch gesture removed
- [ ] Two sliders for Self and Other scale
- [ ] Clear and intuitive interface
- [ ] Consistent behavior between iPhone and iPad

### Success Criteria
- ✅ No more uncontrollable pinch
- ✅ Precise control of each circle size
- ✅ Sliders accessible on iPhone portrait and landscape
- ✅ Interface consistent with rest of app
- ✅ Tests on iPhone Air and iPad Pro 13" successful

---

## 🔵 Sprint 22: UX - Metric 03 Horizontal Drag

**Branch:** `fix/sprint-22-overlap-horizontal-drag`

### Issue
Metric 03 (Overlap) has vertical drag while all other proximity metrics use horizontal drag. Incomprehensible for users.

### Steps
1. Analyze `OverlapView.swift` and `OverlapCirclesView.swift`
2. Change drag from vertical to horizontal
3. Harmonize with Metric 01 (Basic IOS)
4. Test consistency

### Deliverables
- [ ] Horizontal drag instead of vertical
- [ ] Consistent behavior with Basic IOS
- [ ] No regression

### Success Criteria
- ✅ Horizontal drag like other proximity metrics
- ✅ Intuitive and consistent behavior
- ✅ Tests on iPhone and iPad successful
- ✅ Documentation updated

---

## 🔵 Sprint 23: UX - Titles & Instructions Harmonization

**Branch:** `fix/sprint-23-harmonize-ui-consistency`

### Issue
Inconsistency in titles, instructions, and drag directions between metrics. Some have titles/subtitles, others don't.

### Steps
1. Audit all 9 metrics:
   - Title presence
   - Instructions presence
   - Instructions format
2. Define a single standard:
   - Option A: All with title + brief instructions
   - Option B: None with title/instructions (minimalist)
   - Option C: Title only, no instructions
3. Apply standard to all metrics
4. Remove inconsistent elements (e.g., scale under circles Metric 08 if not everywhere)

### Deliverables
- [ ] UI standardization document
- [ ] All metrics harmonized
- [ ] Consistent and predictable interface

### Success Criteria
- ✅ Same title/instructions format on all 9 metrics
- ✅ No sudden appearance of elements
- ✅ Consistent and professional UX
- ✅ Tests on iPhone and iPad
- ✅ Positive user feedback

---

## 🔵 Sprint 24: UX - Arrow Behavior Fix (Metrics 06, 07)

**Branch:** `fix/sprint-24-fix-arrow-behavior`

### Issue
On Metrics 06 (Identification) and 07 (Projection), the arrow in the middle has "weird behavior" and drag offers too little control. Circles may already be too close at start.

### Steps
1. Analyze `IdentificationCirclesView.swift` and `ProjectionCirclesView.swift`
2. Fix arrow behavior (size, position, animation)
3. Increase initial distance between circles for more range
4. Improve drag sensitivity
5. Test fine control

### Deliverables
- [ ] Arrow with consistent behavior
- [ ] Optimized initial distance
- [ ] More precise and controllable drag
- [ ] Usable value range

### Success Criteria
- ✅ Arrow no longer behaves weirdly
- ✅ Drag offers satisfactory control
- ✅ Initial distance allows usable range
- ✅ Slider works well as complement
- ✅ Tests on iPhone and iPad successful

---

## 🔵 Sprint 25: UX - Drag Control Improvement (Metrics 08, 09)

**Branch:** `fix/sprint-25-improve-drag-control`

### Issue
Metrics 08 (Attribution) and 09 (Observation) have "almost uncontrollable" or "difficult to control" drag.

### Steps
1. Analyze `AttributionCirclesView.swift` and `ObservationCirclesView.swift`
2. Improve drag sensitivity (adjust multiplication factors)
3. Increase drag zone if necessary
4. Test different values to find the sweet spot
5. Ensure slider offers a precise alternative

### Deliverables
- [ ] Drag with improved control
- [ ] Adjusted sensitivity
- [ ] Slider as precise alternative

### Success Criteria
- ✅ Controllable and predictable drag
- ✅ User can precisely position circles
- ✅ No sudden jumps
- ✅ Slider offers fine control as complement
- ✅ Tests on iPhone and iPad successful

---

## 🔵 Sprint 26: UX - Proximity Asymmetric Drag (Metric 05)

**Branch:** `fix/sprint-26-proximity-drag-clarification`

### Issue
On Metric 05 (Proximity), you can bring one circle from the left, the other from the right, but only from center with slider. Confusing behavior.

### Steps
1. Analyze `ProximityCirclesView.swift`
2. Clarify behavior:
   - Option A: Allow dragging each circle independently (left/right)
   - Option B: Drag only from center (like slider) for consistency
   - Option C: Documentation/tooltip to explain
3. Implement chosen solution
4. Test user understanding

### Deliverables
- [ ] Clarified drag behavior
- [ ] Consistency between drag and slider
- [ ] Documentation if needed

### Success Criteria
- ✅ Predictable and consistent behavior
- ✅ No user confusion
- ✅ Drag and slider are complementary
- ✅ Tests on iPhone and iPad successful

---

## 🟣 Sprint 27: iCloud Sync - Debug & Fix

**Branch:** `fix/sprint-27-icloud-sync`

### Root Cause (Critical Bug Found!)
**The iCloud sync was NEVER implemented - only skeleton code exists:**

1. **SwiftData not configured for CloudKit:**
   ```swift
   // In IOSScaleApp.swift
   cloudKitDatabase: .none  // ❌ CloudKit is DISABLED!
   ```

2. **Empty implementation methods:**
   ```swift
   private func uploadChanges() async throws {
       // This would query SwiftData for sessions modified since last sync
       // and upload them to CloudKit
       // Implementation depends on SwiftData integration
   }
   
   private func processSessionRecord(_ record: CKRecord) async {
       // Convert CKRecord to SessionModel and save locally
       // Implementation depends on SwiftData integration
   }
   ```

3. **What DOES work:**
   - ✅ Entitlements are correct (`iCloud.com.remyramadour.iosscale`)
   - ✅ Container ID is correct
   - ✅ Settings toggle works (uses `@AppStorage` correctly)
   - ✅ `uploadSession()` method exists and can save individual records
   - ✅ iCloud status check works

### The Real Problem
The sync toggle in Settings gives the **illusion** of working, but:
- `downloadChanges()` queries CloudKit but never saves to SwiftData
- `uploadChanges()` is completely empty
- SwiftData uses `cloudKitDatabase: .none` so no automatic sync

### Solution Options

**Option A: SwiftData Automatic Sync** (Recommended - Simplest)
1. Change `cloudKitDatabase: .none` to `cloudKitDatabase: .automatic`
2. Remove manual CloudSyncService (or simplify to status display only)
3. SwiftData handles all sync automatically

**Option B: Manual CloudKit Sync** (Current approach - needs completion)
1. Keep `cloudKitDatabase: .none`
2. Implement `uploadChanges()` to query SwiftData and upload
3. Implement `processSessionRecord()` to save to SwiftData
4. Add change tracking (lastModified timestamps)
5. Handle conflicts

### Steps
1. **Decision:** Choose Option A (automatic) or B (manual)
2. If Option A:
   - Change `cloudKitDatabase: .automatic` in `IOSScaleApp.swift`
   - Simplify `CloudSyncService` to status display only
   - Test automatic sync
3. If Option B:
   - Implement `uploadChanges()` with SwiftData query
   - Implement `processSessionRecord()` with SwiftData save
   - Add conflict resolution
4. Verify app appears in iCloud Storage settings
5. Test sync between two devices

### Deliverables
- [ ] SwiftData configured for CloudKit (if Option A)
- [ ] OR CloudSyncService fully implemented (if Option B)
- [ ] App visible in iCloud "Manage Storage"
- [ ] Bidirectional sync working
- [ ] Error handling and user feedback

### Success Criteria
- ✅ App appears in iCloud "Manage Storage"
- ✅ Data syncs between iPhone and iPad
- ✅ Sync works after delete/reinstall
- ✅ Sync conflicts handled correctly
- ✅ User feedback on errors
- ✅ Tests on real devices with same Apple ID

---

## 📋 Summary

| Sprint | Title | Priority | Estimate |
|--------|-------|----------|----------|
| 15 | FaceID Removal | 🔴 Critical | 2h |
| 16 | Reset Behavior | 🟡 High | 4h |
| 17 | iPad Menu Card | 🟢 High | 3h |
| 18 | iPhone Landscape 1 | 🟠 Medium | 6h |
| 19 | iPhone Landscape 2 | 🟠 Medium | 6h |
| 20 | iPad Centering | 🟣 Medium | 4h |
| 21 | Replace Pinch | 🔵 Low | 4h |
| 22 | Overlap Horizontal | 🔵 Low | 2h |
| 23 | UI Consistency | 🔵 Low | 6h |
| 24 | Arrow Behavior | 🔵 Low | 4h |
| 25 | Drag Control | 🔵 Low | 4h |
| 26 | Proximity Drag | 🔵 Low | 3h |
| 27 | iCloud Sync | 🟣 Critical | 4h (Option A) / 12h (Option B) |

**Total estimated:** ~52-60 hours of development

---

## 🔄 Workflow

For each sprint:

1. **Create branch** from `main`
2. **Implement** modifications
3. **Test** according to success criteria
4. **Commit** with descriptive message
5. **Push** and create PR
6. **Review & Test** by user
7. **Merge** into `main` after validation
8. **Tag** the version (optional)

---

**Notes:**
- Each sprint must be validated before moving to the next
- Possibility to adjust priorities based on feedback
- User testing required for UX sprints (21-26)
