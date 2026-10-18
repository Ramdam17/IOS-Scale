# Roadmap — IOS Scale

> **Version:** 1.0  
> **Last Updated:** December 2025  
> **Total Estimated Duration:** ~15-17 weeks

---

## 📊 Overview

| Phase | Sprints | Duration | Outcome |
|-------|---------|----------|---------|
| **Phase 1: Core App** | 0-7 | ~8 weeks | v1.0 with Basic + Advanced IOS |
| **Phase 2: Research Modalities** | 8-14 | ~7 weeks | v1.x with all 9 modalities |

### Release Strategy

| Version | Content | Target |
|---------|---------|--------|
| v1.0 | Basic IOS + Advanced IOS + Full app features | App Store |
| v1.1 | + Overlap | Update |
| v1.2 | + Set Membership | Update |
| v1.3 | + Proximity | Update |
| v1.4 | + Identification | Update |
| v1.5 | + Projection | Update |
| v1.6 | + Attribution | Update |
| v1.7 | + Observation | Update |

---

# Phase 1: Core Application

---

## Sprint 0 — Foundations

**Duration:** 1 week  
**Branch:** `feature/sprint-0-foundations`

### Objectives
Set up the project infrastructure, architecture, and design system.

### Tasks

#### Project Setup
- [ ] Create Xcode project (iOS 26, SwiftUI, Swift 6)
- [ ] Configure targets (iOS, iPadOS, macOS Catalyst)
- [ ] Set up folder structure per architecture
- [ ] Configure SwiftData schema
- [ ] Set up SwiftLint configuration

#### GitHub Setup
- [ ] Initialize repository
- [ ] Create `.gitignore` for Xcode/Swift
- [ ] Set up branch protection rules for `main`
- [ ] Create PR template
- [ ] Create issue templates

#### Design System Foundation
- [ ] Implement `ThemeManager` (Dark/Light/System)
- [ ] Create color palette extensions
- [ ] Create typography scale
- [ ] Create spacing constants
- [ ] Build `LiquidGlassCard` component

#### Core Models
- [ ] `ModalityType` enum
- [ ] `Measurement` struct
- [ ] `Session` struct
- [ ] `AppSettings` struct
- [ ] SwiftData `@Model` wrappers

### Deliverables
- [ ] Project compiles without errors
- [ ] Theme switching works
- [ ] Empty navigation shell
- [ ] Git repo with initial commit

### Acceptance Criteria
- [ ] App launches on iPhone, iPad, and Mac
- [ ] Theme toggle changes colors correctly
- [ ] Folder structure matches architecture spec
- [ ] All models are Codable and Identifiable

---

## Sprint 1 — Basic IOS & Advanced IOS

**Duration:** 2 weeks  
**Branch:** `feature/sprint-1-basic-advanced-ios`

### Objectives
Implement both classic IOS scale modalities with full interaction.

### Week 1: Basic IOS

#### Tasks
- [ ] Create `CircleView` component with gradient
- [ ] Implement horizontal drag gesture on circles
- [ ] Create `IOSSlider` component (0→1 range)
- [ ] Sync slider ↔ circle positions bidirectionally
- [ ] Implement overlap calculation
- [ ] Add visual overlap blending (color merge)
- [ ] Add haptic feedback on value changes
- [ ] Display value labels (Distant/Close/Connected/Merged)
- [ ] Create `BasicIOSView` screen (NO numeric value displayed)
- [ ] Create `BasicIOSViewModel`
- [ ] Implement `ExitSessionSheet` modal with options:
  - [ ] "Save & Exit" — saves current state and exits
  - [ ] "Exit without saving" — discards and exits
  - [ ] "Cancel" — returns to measurement
- [ ] Remove/disable back navigation gesture and button

#### Deliverables
- [ ] Basic IOS fully functional
- [ ] Circles draggable horizontally
- [ ] Slider synced with circles
- [ ] Overlap visually rendered
- [ ] Exit modal with save options
- [ ] No back button, no displayed value

#### UX Rules
- **No back navigation** — User cannot swipe back or tap a back button
- **No numeric value displayed** — The measurement value is internal only
- **Exit is the only way out** — "Exit session" button triggers save options modal

### Week 2: Advanced IOS

#### Tasks
- [ ] Extend `CircleView` with scale property
- [ ] Implement vertical drag for size adjustment
- [ ] Implement pinch gesture for size adjustment
- [ ] Add second axis slider (or vertical slider) for scale ratio
- [ ] Constrain scale to 0.2 → 2.0 range
- [ ] Store `selfScale` and `otherScale` in measurement
- [ ] Create `AdvancedIOSView` screen (NO numeric value displayed)
- [ ] Create `AdvancedIOSViewModel`
- [ ] Reuse `ExitSessionSheet` modal from Basic IOS

#### Deliverables
- [ ] Advanced IOS fully functional
- [ ] Circle sizes adjustable (drag + pinch)
- [ ] Both overlap and scale captured
- [ ] `secondaryValues` populated correctly
- [ ] Same exit flow as Basic IOS (no back, exit modal)

### Acceptance Criteria (Sprint 1)
- [ ] Both modalities produce valid `Measurement` objects
- [ ] Values always within 0-1 (primary) and 0.2-2.0 (scales)
- [ ] Interactions feel smooth (60fps)
- [ ] Works on iPhone and iPad
- [ ] **No numeric value visible** on measurement screen
- [ ] **No back navigation** — only Exit button
- [ ] **Exit modal** presents save options before leaving

---

## Sprint 2 — Menu & Navigation

**Duration:** 1 week  
**Branch:** `feature/sprint-2-menu-navigation`

### Objectives
Build the home screen with modality selection, animated previews, and app navigation.

### Tasks

#### Home Screen
- [ ] Create `HomeView` with app title
- [ ] Build modality card list (9 cards)
- [ ] Implement expandable card with description
- [ ] Show modality availability (active vs coming soon)
- [ ] Implement card tap → navigation to measurement

#### Animated Card Previews
- [ ] Create `ModalityPreviewView` component for each modality type
- [ ] **Basic IOS preview**: Two circles gently moving closer/apart in a loop
- [ ] **Advanced IOS preview**: Circles moving + subtle size pulsing
- [ ] **Overlap preview**: Circles with animated intersection zone
- [ ] **Set Membership preview**: Circles moving in/out of a rectangle
- [ ] **Proximity preview**: Circles with animated connecting line
- [ ] **Identification preview**: Arrow/flow animation Self → Other
- [ ] **Projection preview**: Arrow/flow animation Other → Self  
- [ ] **Attribution preview**: Circles moving on an axis
- [ ] **Observation preview**: Eye icon transitioning to circle
- [ ] Use subtle, looping animations (2-4 second cycles)
- [ ] Animations should be lightweight (no heavy GPU usage)
- [ ] Respect "Reduce Motion" accessibility setting

#### Navigation
- [ ] Set up `NavigationStack`
- [ ] Create `AppRouter` or coordinator
- [ ] Add floating stats button (bottom right)
- [ ] Implement tab bar or sidebar for iPad
- [ ] **Disable** back gesture when in measurement screen

#### Responsive Layout
- [ ] iPhone: single column card list
- [ ] iPad Portrait: 2 column grid
- [ ] iPad Landscape: sidebar + detail

#### Polish
- [ ] Add card entry animations
- [ ] Implement pull-to-refresh (future: sync status)
- [ ] Add empty state for no sessions

### Deliverables
- [ ] Home screen with all 9 modality cards
- [ ] **Animated previews** showing each modality's behavior
- [ ] Navigation to Basic and Advanced IOS
- [ ] Placeholder navigation for other modalities
- [ ] Responsive layout working

### Acceptance Criteria
- [ ] All modalities visible on home screen
- [ ] Cards expand to show description with **animated preview**
- [ ] Animations loop smoothly and respect Reduce Motion
- [ ] Tapping active modality opens measurement view
- [ ] Layout adapts to device size
- [ ] Back gesture disabled when in measurement

---

## Sprint 3 — Export & Sharing

**Duration:** 1 week  
**Branch:** `feature/sprint-3-export-sharing`

### Objectives
Implement data export in multiple formats and iOS sharing.

### Tasks

#### Export Logic
- [ ] Create `ExportService`
- [ ] Implement CSV generation
- [ ] Implement TSV generation
- [ ] Implement JSON generation
- [ ] Add metadata to exports (optional via settings)
- [ ] Handle decimal separator setting

#### Export UI
- [ ] Create `ExportSheet` view
- [ ] Add format picker (CSV/TSV/JSON segmented)
- [ ] Add export button with icon
- [ ] Show loading state during generation
- [ ] Preview file name before export

#### Sharing
- [ ] Integrate `ShareLink` (iOS 16+)
- [ ] Support AirDrop
- [ ] Support Messages, Mail, Notes
- [ ] Support Save to Files
- [ ] Support Copy to clipboard (JSON)

#### Integration
- [ ] Add "Save current state" button to measurement views
- [ ] Add "Export" option to session detail
- [ ] Hook export into measurement flow

### Deliverables
- [ ] Export sheet with format selection
- [ ] CSV, TSV, JSON all generate correctly
- [ ] iOS share sheet appears with file
- [ ] File can be saved locally

### Acceptance Criteria
- [ ] Exported CSV opens correctly in Numbers/Excel
- [ ] JSON is valid and parseable
- [ ] Share sheet shows appropriate apps
- [ ] Export completes in < 2 seconds for typical session

---

## Sprint 4 — History & Review

**Duration:** 1 week  
**Branch:** `feature/sprint-4-history-review`

### Objectives
Allow users to view, review, and manage past sessions.

### Tasks

#### Session List
- [ ] Create `HistoryView` screen
- [ ] List sessions grouped by date
- [ ] Show session summary (modality, count, date)
- [ ] Add search/filter by modality
- [ ] Add sort options (date, modality)

#### Session Detail
- [ ] Create `SessionDetailView`
- [ ] Show all measurements in session
- [ ] Display timeline visualization
- [ ] Show statistics (min, max, average, trend)
- [ ] Option to export single session

#### Data Management
- [ ] Implement session deletion (swipe to delete)
- [ ] Add confirmation dialog for delete
- [ ] Implement bulk delete option
- [ ] Add "Delete All Data" in settings

#### Visualization
- [ ] Simple line chart for session over time
- [ ] Show circle positions at each measurement
- [ ] Playback option (animate through measurements)

### Deliverables
- [ ] History screen with all sessions
- [ ] Session detail with measurements
- [ ] Delete functionality working
- [ ] Basic chart visualization

### Acceptance Criteria
- [ ] All saved sessions appear in history
- [ ] Tapping session shows details
- [ ] Delete removes from local storage
- [ ] Chart renders without lag

---

## Sprint 5 — Authentication & Settings

**Duration:** 1 week  
**Branch:** `feature/sprint-5-auth-settings`

### Objectives
Add security options and complete settings implementation.

### Tasks

#### Authentication
- [ ] Create `AuthenticationService`
- [ ] Implement Sign in with Apple
- [ ] Implement FaceID/TouchID unlock
- [ ] Add passcode fallback
- [ ] Lock app on background (optional)
- [ ] Show auth on launch if enabled

#### Settings Screen
- [ ] Create `SettingsView`
- [ ] Appearance section (Theme picker)
- [ ] Measurement section (Reset behaviour picker)
- [ ] Data section (iCloud toggle, export format)
- [ ] Security section (Auth toggle, biometric toggle)
- [ ] About section (version, acknowledgements)

#### Settings Bundle
- [ ] Create `Settings.bundle`
- [ ] Expose key settings to iOS Settings app
- [ ] Sync with in-app settings

#### Reset Behaviour
- [ ] Implement "Keep position" mode
- [ ] Implement "Reset to default" mode
- [ ] Implement "Random positioning" mode
- [ ] Apply between measurements in session

### Deliverables
- [ ] Settings screen complete
- [ ] Sign in with Apple working
- [ ] FaceID/TouchID working (if available)
- [ ] Settings accessible from iOS Settings

### Acceptance Criteria
- [ ] Theme change persists across launches
- [ ] Auth blocks access when enabled
- [ ] Reset behaviour affects measurement flow
- [ ] Settings bundle appears in iOS Settings

---

## Sprint 6 — iCloud Sync

**Duration:** 1 week  
**Branch:** `feature/sprint-6-icloud-sync`

### Objectives
Enable cross-device synchronization via iCloud.

### Tasks

#### CloudKit Setup
- [ ] Enable CloudKit capability
- [ ] Create CloudKit container
- [ ] Define record types for Session, Measurement
- [ ] Set up development and production environments

#### Sync Service
- [ ] Create `CloudSyncService`
- [ ] Implement upload on save
- [ ] Implement download on launch
- [ ] Handle conflict resolution (last-write-wins or merge)
- [ ] Implement incremental sync

#### UI Integration
- [ ] Add sync status indicator
- [ ] Show last sync time
- [ ] Manual sync button (pull to refresh)
- [ ] Handle offline mode gracefully

#### Error Handling
- [ ] Handle iCloud not available
- [ ] Handle quota exceeded
- [ ] Handle network errors
- [ ] Show user-friendly error messages

### Deliverables
- [ ] Sessions sync to iCloud
- [ ] Data appears on other devices
- [ ] Sync status visible to user
- [ ] Errors handled gracefully

### Acceptance Criteria
- [ ] Create session on iPhone → appears on iPad
- [ ] Edit on iPad → updates on iPhone
- [ ] Delete syncs across devices
- [ ] Works offline, syncs when online

---

## Sprint 7 — Polish & Release v1.0

**Duration:** 1 week  
**Branch:** `feature/sprint-7-polish-release`

### Objectives
Final polish, testing, documentation, and App Store preparation.

### Tasks

#### Accessibility
- [ ] Audit all screens with VoiceOver
- [ ] Add missing accessibility labels
- [ ] Test with Dynamic Type
- [ ] Test with Reduce Motion
- [ ] Test with color blindness simulation

#### Polish
- [ ] Review all animations (smooth, consistent)
- [ ] Review haptic feedback points
- [ ] Fix any UI glitches
- [ ] Ensure consistent spacing
- [ ] Review Dark mode thoroughly

#### Testing
- [ ] Test on iPhone SE (smallest)
- [ ] Test on iPhone 15 Pro Max
- [ ] Test on iPad mini
- [ ] Test on iPad Pro 12.9"
- [ ] Test on Mac (Catalyst)

#### Documentation
- [ ] Complete README.md
- [ ] Write CONTRIBUTING.md
- [ ] Add LICENSE (choose license)
- [ ] Write ACKNOWLEDGEMENTS.md
- [ ] Add code documentation (DocC)

#### App Store
- [ ] Create app screenshots (all device sizes)
- [ ] Write app description
- [ ] Prepare keywords
- [ ] Create app preview video (optional)
- [ ] Set up App Store Connect
- [ ] Submit for review

### Deliverables
- [ ] All polish items complete
- [ ] Documentation complete
- [ ] App submitted to App Store
- [ ] v1.0 tag created

### Acceptance Criteria
- [ ] No crashes in testing
- [ ] All accessibility audits pass
- [ ] App Store assets ready
- [ ] App approved by Apple

---

# Phase 2: Research Modalities

Each sprint follows the same structure. Modalities build on the shared circle components from Sprint 1.

---

## Sprint 8 — Overlap Modality

**Duration:** 1 week  
**Branch:** `feature/sprint-8-modality-overlap`

### Description
Measures specifically the degree of overlap/intersection between Self and Other. Unlike Basic IOS which measures distance, this focuses on "how much do we share?"

### Interaction Design
- **Visual:** Two circles with highlighted intersection zone
- **Primary gesture:** Vertical drag to adjust overlap amount
- **Slider:** Controls overlap percentage
- **Output:** `primaryValue` = overlap (0-1)

### Tasks
- [ ] Create `OverlapView` and `OverlapViewModel`
- [ ] Implement vertical drag gesture
- [ ] Highlight intersection zone with distinct color
- [ ] Show percentage of overlap visually
- [ ] Add to navigation (enable card on home)
- [ ] Write unit tests

### Acceptance Criteria
- [ ] Overlap adjustable via drag and slider
- [ ] Intersection zone visually distinct
- [ ] Measurement saves correctly
- [ ] Card active on home screen

---

## Sprint 9 — Set Membership Modality

**Duration:** 1 week  
**Branch:** `feature/sprint-9-modality-set-membership`

### Description
Based on "to (not) feel a part of the same set" — measures whether Self and Other belong to a shared group/category.

### Interaction Design
- **Visual:** Rectangle (the "set") containing potential space for circles
- **Primary gesture:** Drag circles into/out of the set
- **Slider:** Degree of shared membership
- **Output:** `primaryValue` = inclusion degree, `secondaryValues` = `selfInSet`, `otherInSet`

### Tasks
- [ ] Create `SetMembershipView` and `SetMembershipViewModel`
- [ ] Implement draggable set boundary
- [ ] Detect when circles are inside/outside set
- [ ] Visual feedback for membership state
- [ ] Add to navigation

### Acceptance Criteria
- [ ] Set visually contains or excludes circles
- [ ] Both circles can be positioned independently
- [ ] Membership state captured in output

---

## Sprint 10 — Proximity Modality

**Duration:** 1 week  
**Branch:** `feature/sprint-10-modality-proximity`

### Description
Pure distance measurement without overlap — "how close do I feel to the other?"

### Interaction Design
- **Visual:** Two circles with connecting line showing distance
- **Primary gesture:** Horizontal drag, pinch to zoom (bring together)
- **Slider:** Controls distance
- **Output:** `primaryValue` = inverse distance (0=far, 1=touching)

### Tasks
- [ ] Create `ProximityView` and `ProximityViewModel`
- [ ] Implement connecting line between circles
- [ ] Line thickness varies with proximity
- [ ] Circles cannot overlap (stop at touching)
- [ ] Pinch gesture brings both closer/farther

### Acceptance Criteria
- [ ] Distance clearly visualized
- [ ] Circles stop at edge (no overlap)
- [ ] Pinch works intuitively

---

## Sprint 11 — Identification Modality

**Duration:** 1 week  
**Branch:** `feature/sprint-11-modality-identification`

### Description
"To (not) identify oneself with the other" — Self absorbs qualities of Other.

### Interaction Design
- **Visual:** Other circle moves toward and "into" Self
- **Primary gesture:** Drag Other toward Self
- **Effect:** Other becomes transparent, Self takes on Other's color
- **Output:** `primaryValue` = identification degree

### Tasks
- [ ] Create `IdentificationView` and `IdentificationViewModel`
- [ ] Implement Other → Self absorption animation
- [ ] Color blending as identification increases
- [ ] Opacity change on Other circle
- [ ] Directional arrow indicator

### Acceptance Criteria
- [ ] Clear visual of Self absorbing Other
- [ ] Direction is explicitly Other → Self
- [ ] Animation is smooth and reversible

---

## Sprint 12 — Projection Modality

**Duration:** 1 week  
**Branch:** `feature/sprint-12-modality-projection`

### Description
"To (not) identify the other with oneself" — Self projects onto Other (opposite of Identification).

### Interaction Design
- **Visual:** Self circle moves toward and "into" Other
- **Primary gesture:** Drag Self toward Other
- **Effect:** Self becomes transparent, Other takes on Self's color
- **Output:** `primaryValue` = projection degree

### Tasks
- [ ] Create `ProjectionView` and `ProjectionViewModel`
- [ ] Implement Self → Other projection animation
- [ ] Animated arrows from Self to Other
- [ ] Mirror logic of Identification but reversed

### Acceptance Criteria
- [ ] Clear visual of Self projecting onto Other
- [ ] Direction is explicitly Self → Other
- [ ] Visually distinct from Identification

---

## Sprint 13 — Attribution Modality

**Duration:** 1 week  
**Branch:** `feature/sprint-13-modality-attribution`

### Description
"To (not) assign to the other" — measuring perceived similarity across dimensions.

### Interaction Design
- **Visual:** One or more axes with Self and Other positioned
- **Primary gesture:** Drag circles on axis/axes
- **Simplified mode:** Single "Similar ↔ Different" axis
- **Advanced mode:** Multiple trait axes (optional)
- **Output:** `primaryValue` = overall similarity, `secondaryValues` = per-axis if multiple

### Tasks
- [ ] Create `AttributionView` and `AttributionViewModel`
- [ ] Implement single axis mode (default)
- [ ] Calculate similarity from positions
- [ ] Optional: multiple axes UI
- [ ] Aggregate to single score

### Acceptance Criteria
- [ ] Circles positionable on similarity axis
- [ ] Clear visual of same vs different
- [ ] Single output value computed

---

## Sprint 14 — Observation Modality

**Duration:** 1 week  
**Branch:** `feature/sprint-14-modality-observation`

### Description
"To oversee the interaction" — measuring the sense of being an observer vs participant.

### Interaction Design
- **Visual:** Eye/viewpoint icon above the Self-Other pair
- **Primary gesture:** Vertical drag (up = observer, down = immersed)
- **Effect:** Scene becomes "distant" (blur, smaller) when observing
- **Output:** `primaryValue` = immersion (0=observer, 1=fully immersed)

### Tasks
- [ ] Create `ObservationView` and `ObservationViewModel`
- [ ] Implement viewpoint indicator
- [ ] Add blur/scale effect based on position
- [ ] Eye icon transforms to Self circle when immersed
- [ ] Smooth transition animation

### Acceptance Criteria
- [ ] Clear observer vs participant states
- [ ] Visual effect reinforces the feeling
- [ ] Value correctly captures position

---

## 🏁 Post-Release

### Maintenance
- Monitor crash reports
- Address user feedback
- Fix bugs as needed

### Future Considerations
- Longitudinal tracking features
- Data visualization improvements
- Research collaboration features
- Watch app (simplified)
- Widget support

---

## 📋 Sprint Template

For reference, each sprint should include:

```markdown
## Sprint N — [Name]

**Duration:** X week(s)
**Branch:** `feature/sprint-n-name`

### Objectives
[What this sprint accomplishes]

### Tasks
- [ ] Task 1
- [ ] Task 2
- [ ] ...

### Deliverables
- [ ] Deliverable 1
- [ ] Deliverable 2

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

---

## 📅 Timeline Summary

| Sprint | Name | Duration | Cumulative |
|--------|------|----------|------------|
| 0 | Foundations | 1 week | Week 1 |
| 1 | Basic + Advanced IOS | 2 weeks | Week 3 |
| 2 | Menu & Navigation | 1 week | Week 4 |
| 3 | Export & Sharing | 1 week | Week 5 |
| 4 | History & Review | 1 week | Week 6 |
| 5 | Auth & Settings | 1 week | Week 7 |
| 6 | iCloud Sync | 1 week | Week 8 |
| 7 | Polish & Release | 1 week | Week 9 |
| **v1.0 Release** | | | **Week 9** |
| 8 | Overlap | 1 week | Week 10 |
| 9 | Set Membership | 1 week | Week 11 |
| 10 | Proximity | 1 week | Week 12 |
| 11 | Identification | 1 week | Week 13 |
| 12 | Projection | 1 week | Week 14 |
| 13 | Attribution | 1 week | Week 15 |
| 14 | Observation | 1 week | Week 16 |
| **v1.7 Complete** | | | **Week 16** |