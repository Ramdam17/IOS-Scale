# Design Guide — IOS Scale

> **Version:** 1.0  
> **Last Updated:** December 2025  
> **Design Language:** Apple Liquid Glass + Rainbow Unicorn Pastel

---

## 🎨 Design Philosophy

### Core Principles

1. **Light & Beautiful** — The app should feel airy, not heavy. Minimal visual clutter.
2. **Pastel Energy** — Soft, warm colors that feel inviting and non-clinical.
3. **Rainbow Unicorn** — Playful gradients that shift subtly between pastels.
4. **Intuitive First** — Users should understand interactions without instructions.
5. **Liquid Glass** — Leverage iOS 26's new translucent, depth-aware materials.

### Emotional Goals

| Feeling | How We Achieve It |
|---------|-------------------|
| Calm | Soft gradients, slow animations |
| Trust | Consistent patterns, no surprises |
| Delight | Micro-interactions, haptic feedback |
| Clarity | High contrast text, clear hierarchy |

---

## 🌈 Color System

### Primary Circle Colors

```swift
// Self Circle — Cool Blue
static let selfCircleCore = Color(hex: "#4A90D9")
static let selfCircleGlow = Color(hex: "#7BB3FF")
static let selfCircleGradient = RadialGradient(
    colors: [selfCircleCore, selfCircleGlow.opacity(0.6)],
    center: .center,
    startRadius: 0,
    endRadius: 60
)

// Other Circle — Warm Magenta
static let otherCircleCore = Color(hex: "#9B59B6")
static let otherCircleGlow = Color(hex: "#D98EDB")
static let otherCircleGradient = RadialGradient(
    colors: [otherCircleCore, otherCircleGlow.opacity(0.6)],
    center: .center,
    startRadius: 0,
    endRadius: 60
)

// Overlap Zone — Blended
static let overlapGradient = LinearGradient(
    colors: [selfCircleCore.opacity(0.7), otherCircleCore.opacity(0.7)],
    startPoint: .leading,
    endPoint: .trailing
)
```

### Background Gradients

#### Light Mode
```swift
static let lightBackground = LinearGradient(
    colors: [
        Color(hex: "#F8F9FF"),  // Soft lavender white
        Color(hex: "#E8F4F8"),  // Pale cyan
        Color(hex: "#FFF8F0"),  // Warm cream
        Color(hex: "#F0FFF4")   // Mint whisper
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

#### Dark Mode
```swift
static let darkBackground = LinearGradient(
    colors: [
        Color(hex: "#1A1A2E"),  // Deep navy
        Color(hex: "#16213E"),  // Midnight blue
        Color(hex: "#1F1135"),  // Dark purple
        Color(hex: "#0F0F23")   // Near black
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### Accent Colors (Cards & Buttons)

| Element | Light Mode | Dark Mode |
|---------|-----------|-----------|
| Card Background | `#FFFFFF` @ 80% | `#2A2A3E` @ 60% |
| Card Border | `#E0E0E0` @ 50% | `#4A4A6A` @ 30% |
| Primary Button | Blue→Purple gradient | Same with glow |
| Destructive Button | `#E74C3C` pastel | `#FF6B6B` |
| Success | `#27AE60` pastel | `#6BCB77` |

### Modality Card Colors

Each modality has a signature tint visible in its card:

| Modality | Tint Color | Hex |
|----------|-----------|-----|
| Basic IOS | Sky Blue | `#74B9FF` |
| Advanced IOS | Rose | `#FD79A8` |
| Overlap | Lavender | `#A29BFE` |
| Set Membership | Slate | `#636E72` |
| Proximity | Mint | `#00CEC9` |
| Identification | Peach | `#FDCB6E` |
| Projection | Coral | `#E17055` |
| Attribution | Blush | `#FAB1A0` |
| Observation | Sky | `#81ECEC` |

---

## 📐 Typography

### Font Stack

```swift
// Primary: San Francisco (System)
static let title = Font.system(.largeTitle, design: .rounded, weight: .bold)
static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
static let body = Font.system(.body, design: .default, weight: .regular)
static let caption = Font.system(.caption, design: .rounded, weight: .medium)
static let numeric = Font.system(.title2, design: .monospaced, weight: .medium)
```

### Text Hierarchy

| Level | Usage | Size | Weight |
|-------|-------|------|--------|
| Large Title | Screen titles | 34pt | Bold |
| Title | Section headers | 28pt | Bold |
| Headline | Card titles | 17pt | Semibold |
| Body | Descriptions | 17pt | Regular |
| Caption | Labels, hints | 12pt | Medium |
| Numeric | Values (0.65) | 24pt | Medium Mono |

### Text Colors

```swift
static let textPrimary = Color.primary        // Adapts to theme
static let textSecondary = Color.secondary    // 60% opacity
static let textTertiary = Color.tertiary      // 40% opacity
static let textOnGradient = Color.white       // For buttons
```

---

## 🔘 Components

### Interactive Circles

```
┌─────────────────────────────────────────────────┐
│                                                 │
│     ┌───────┐              ┌───────┐           │
│     │       │              │       │           │
│     │ Self  │              │ Other │           │
│     │       │              │       │           │
│     └───────┘              └───────┘           │
│         ●────────────────────●                 │
│              (connection line)                  │
└─────────────────────────────────────────────────┘
```

#### Circle States

| State | Visual |
|-------|--------|
| Default | Soft gradient, subtle shadow |
| Dragging | Scale 1.05, stronger shadow |
| Overlapping | Colors blend in intersection |
| Merged | Single blended circle |

#### Circle Sizing

```swift
// Base sizes (before scale multiplier)
static let circleBaseDiameter: CGFloat = 120  // iPhone
static let circleBaseDiameterPad: CGFloat = 180  // iPad

// Scale range for Advanced IOS
static let minScale: Double = 0.2
static let maxScale: Double = 2.0
static let defaultScale: Double = 1.0
```

### Cards (Modality Selection)

```
┌────────────────────────────────────────────────┐
│  ┌────┐                                        │
│  │ 🔵 │  Basic IOS                        ∨   │
│  └────┘  Classic scale                         │
│                                                │
│  ┌─────────────────────────────────────────┐  │
│  │         ○         ○                     │  │
│  │       Self      Other                   │  │
│  └─────────────────────────────────────────┘  │
│                                                │
│  Classic distance-based measurement using      │
│  two circles that can be moved closer or       │
│  farther apart.                                │
└────────────────────────────────────────────────┘
```

#### Card Properties

```swift
struct ModalityCard: View {
    // Visual properties
    let cornerRadius: CGFloat = 20
    let padding: CGFloat = 16
    let iconSize: CGFloat = 44
    
    // Liquid Glass effect
    var material: Material = .ultraThinMaterial
    var shadowRadius: CGFloat = 10
    var shadowOpacity: Double = 0.1
}
```

### Slider

```
Distant          Close         Connected         Merged
  │               │               │                │
  ├───────────────┼───────────────┼────────────────┤
  ○━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●
  │                               │
  │←──────────── Thumb ──────────→│
```

#### Slider Properties

```swift
// Track
static let trackHeight: CGFloat = 8
static let trackCornerRadius: CGFloat = 4
static let trackColorFilled = selfCircleGradient
static let trackColorEmpty = Color.gray.opacity(0.3)

// Thumb
static let thumbDiameter: CGFloat = 28
static let thumbShadowRadius: CGFloat = 4
```

### Buttons

#### Primary Action
```swift
Button("Save current state") { }
    .buttonStyle(.borderedProminent)
    .tint(LinearGradient(colors: [.blue, .purple], ...))
    .cornerRadius(16)
    .shadow(radius: 8)
```

#### Destructive Action
```swift
Button("Exit session") { }
    .buttonStyle(.bordered)
    .tint(.red.opacity(0.8))
    .cornerRadius(16)
```

### Export Sheet

```
┌────────────────────────────────────────────────┐
│  ─────                                         │
│  Back          Export Data            Cancel   │
│                                                │
│  Export Format                                 │
│  ┌──────────┬──────────┬──────────┐           │
│  │   CSV    │   TSV    │   JSON   │           │
│  └──────────┴──────────┴──────────┘           │
│                                                │
│  ┌────────────────────────────────────────┐   │
│  │           📤 Export                    │   │
│  └────────────────────────────────────────┘   │
└────────────────────────────────────────────────┘
```

---

## 📱 Layout & Spacing

### Spacing Scale

```swift
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

### Safe Areas

```swift
// Always respect safe areas
.safeAreaInset(edge: .bottom) {
    // Slider and buttons here
}
```

### Responsive Breakpoints

| Device | Width | Adjustments |
|--------|-------|-------------|
| iPhone SE | < 375pt | Smaller circles, compact spacing |
| iPhone Standard | 375-428pt | Default sizing |
| iPad Portrait | 768pt | 1.5x circles, more padding |
| iPad Landscape | 1024pt+ | Side panel layout option |

### Grid System

```swift
// Home screen cards
LazyVGrid(columns: [
    GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
], spacing: 16) {
    // Modality cards
}
.padding(.horizontal, 16)
```

---

## 🎬 Animation & Motion

### Timing Functions

```swift
// Standard interactions
static let defaultAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)

// Subtle feedback
static let quickAnimation = Animation.easeOut(duration: 0.2)

// Screen transitions
static let transitionAnimation = Animation.spring(response: 0.5, dampingFraction: 0.85)
```

### Circle Animations

```swift
// Drag gesture
.animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: position)

// Scale change (Advanced IOS)
.animation(.spring(response: 0.4), value: scale)

// Overlap blend
.animation(.easeInOut(duration: 0.3), value: overlapAmount)
```

### Micro-interactions

| Action | Animation |
|--------|-----------|
| Circle drag start | Scale to 1.05, shadow increase |
| Circle drag end | Scale to 1.0, spring back |
| Slider change | Haptic light |
| Save success | Checkmark scale in, haptic success |
| Card expand | Spring, rotate chevron |

---

## ♿ Accessibility

### VoiceOver Labels

```swift
Circle()
    .accessibilityLabel("Self circle")
    .accessibilityValue("Position: \(Int(overlap * 100))% overlap")
    .accessibilityHint("Drag horizontally to adjust closeness")
    .accessibilityAddTraits(.allowsDirectInteraction)
```

### Dynamic Type

```swift
// Support all text sizes
@ScaledMetric(relativeTo: .body) var circleSize: CGFloat = 120

Text("Value")
    .font(.body)
    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
```

### Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

.animation(reduceMotion ? nil : .spring(), value: position)
```

### Color Contrast

All text must meet WCAG AA standards:
- Normal text: 4.5:1 minimum
- Large text: 3:1 minimum

---

## 🌙 Dark Mode Specifics

### Material Adjustments

```swift
// Light mode
.background(.ultraThinMaterial)

// Dark mode — slightly more opaque
.background(.regularMaterial)
```

### Shadow Adjustments

```swift
// Light mode
.shadow(color: .black.opacity(0.1), radius: 10, y: 4)

// Dark mode — glow effect instead
.shadow(color: selfCircleGlow.opacity(0.3), radius: 15, y: 0)
```

### Circle Adjustments

```swift
// Dark mode circles get a subtle outer glow
Circle()
    .fill(gradient)
    .overlay(
        Circle()
            .stroke(glowColor.opacity(colorScheme == .dark ? 0.5 : 0), lineWidth: 2)
            .blur(radius: 4)
    )
```

---

## 📲 Platform Adaptations

### iPhone

- Single column layout
- Bottom sheet for export
- Circles centered vertically
- Slider at bottom with safe area padding

### iPad

- Two column option in landscape
- Larger circles (1.5x)
- Sidebar navigation option
- Popover for export instead of sheet

### Mac (Catalyst)

- Window min size: 800x600
- Menu bar integration
- Keyboard shortcuts (⌘S save, ⌘E export)
- Settings in app menu

---

## 📁 Asset Naming

### Icons

```
icon-modality-basic
icon-modality-advanced
icon-modality-overlap
icon-export-csv
icon-export-json
icon-settings-theme
icon-settings-sync
```

### Images

```
background-gradient-light
background-gradient-dark
onboarding-step-1
onboarding-step-2
```

### SF Symbols Used

| Purpose | Symbol |
|---------|--------|
| Basic IOS | `circle.circle` |
| Advanced IOS | `circle.lefthalf.filled` |
| Overlap | `circle.fill.badge.plus` |
| Set Membership | `rectangle.3.group` |
| Proximity | `arrow.left.and.right` |
| Identification | `person.fill.turn.right` |
| Projection | `person.fill.turn.left` |
| Attribution | `list.bullet.clipboard` |
| Observation | `eye` |
| Export | `square.and.arrow.up` |
| Settings | `gearshape` |
| Save | `square.and.arrow.down` |
| Exit | `rectangle.portrait.and.arrow.right` |
| Chart | `chart.line.uptrend.xyaxis` |

---

## 🔧 Implementation Checklist

For each screen/component:

- [ ] Works in Light mode
- [ ] Works in Dark mode
- [ ] Responsive on iPhone SE
- [ ] Responsive on iPad
- [ ] VoiceOver labels complete
- [ ] Dynamic Type supported
- [ ] Reduce Motion respected
- [ ] Haptic feedback implemented
- [ ] Animations smooth (60fps)
- [ ] Loading states defined
- [ ] Error states defined
- [ ] Empty states defined
