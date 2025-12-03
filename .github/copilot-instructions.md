# Copilot Instructions — IOS Scale App

> **Version:** 1.0  
> **Last Updated:** December 2025  
> **Project:** IOS Scale — Intersubjective Measurement Platform

---

## ⚠️ CRITICAL RULES

### File Operations — ALWAYS ASK FIRST
**NEVER create, edit, rename, move, or delete any file or folder without explicit user approval.**

Before ANY file operation, you MUST:
1. Describe what you intend to do
2. List the exact files/folders affected
3. Wait for explicit "yes" or approval

```
❌ WRONG: Just creating/editing files
✅ RIGHT: "I'd like to create `Models/Session.swift`. Proceed?"
```

### Code Quality Standards
- **Language:** Swift 6, SwiftUI, iOS/iPadOS/macOS 26+
- **Documentation:** All comments in English
- **Architecture:** MVVM with clear separation
- **Naming:** Clear, descriptive, no abbreviations

---

## 📱 Project Overview

**IOS Scale** measures intersubjective experiences using visual circle-based scales, inspired by Aron's IOS Scale (1992) and research by Ollagnier-Beldame & Coupé (2019).

### Platforms
- iOS 26+ (iPhone)
- iPadOS 26+ (iPad)
- macOS 26+ (Mac Catalyst)

### Core Features
- 9 measurement modalities (2 classic + 7 research)
- Dark/Light/System themes with pastel "rainbow unicorn" aesthetic
- Apple Liquid Glass design language
- Export to CSV/TSV/JSON
- iCloud sync
- FaceID/TouchID authentication

---

## 🏗️ Architecture

### Folder Structure
```
IOSScale/
├── App/
│   ├── IOSScaleApp.swift
│   └── AppDelegate.swift
├── Core/
│   ├── Models/
│   ├── Services/
│   ├── Extensions/
│   └── Utilities/
├── Features/
│   ├── Home/
│   ├── Measurement/
│   │   ├── Basic/
│   │   ├── Advanced/
│   │   └── Research/
│   ├── History/
│   ├── Export/
│   └── Settings/
├── UI/
│   ├── Components/
│   ├── Themes/
│   └── Modifiers/
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

### Key Models
```swift
// Session contains multiple measurements
struct Session: Identifiable, Codable {
    let id: UUID
    let modality: ModalityType
    var measurements: [Measurement]
}

// Each measurement has a primary value (0-1)
struct Measurement: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let primaryValue: Double  // Always 0.0 to 1.0
    let secondaryValues: [String: Double]?
}

// 9 modalities total
enum ModalityType: String, Codable, CaseIterable {
    case basicIOS, advancedIOS  // Classic
    case overlap, setMembership, proximity  // Research
    case identification, projection, attribution, observation
}
```

---

## 🎨 Design System

### Theme
- **Style:** Rainbow unicorn, pastel energy, light and beautiful
- **Design Language:** Apple Liquid Glass (iOS 26)
- **Colors:** Soft pastels with gradient backgrounds
- **Circles:** Self = Blue gradient, Other = Magenta/Violet gradient

### Color Palette
```swift
// Primary circle colors
static let selfCircle = Color.blue.gradient
static let otherCircle = Color.purple.gradient

// Pastel backgrounds
static let lightBackground = LinearGradient(/* pastel rainbow */)
static let darkBackground = LinearGradient(/* deep purples/blues */)
```

### Interactions
- **Drag:** Horizontal on circles to adjust overlap (0→1)
- **Slider:** Always present at bottom, synced with circles
- **Pinch:** On Advanced IOS for circle size (0.2→2.0)
- **Haptic:** Light feedback on value changes

---

## 📊 Data Management

### Value Ranges
| Property | Range | Description |
|----------|-------|-------------|
| `primaryValue` | 0.0 → 1.0 | Main measurement (overlap/proximity) |
| `selfScale` | 0.2 → 2.0 | Self circle size (Advanced only) |
| `otherScale` | 0.2 → 2.0 | Other circle size (Advanced only) |

### Export Formats
- **CSV/TSV:** Flat table with all measurements
- **JSON:** Hierarchical with sessions and metadata

### Storage
- **Local:** SwiftData
- **Cloud:** CloudKit (optional)

---

## 🔀 Git Workflow

### Branch Naming
```
feature/[sprint]-[feature-name]
fix/[issue-number]-[description]
refactor/[area]
docs/[document-name]
```

### Examples
```
feature/sprint-1-basic-ios-circles
feature/sprint-4-export-csv
fix/42-slider-sync-issue
refactor/measurement-models
docs/readme-update
```

### Commit Messages
```
feat(basic-ios): add circle drag gesture
fix(export): correct CSV decimal separator
refactor(models): unify measurement structure
docs: update README with setup instructions
```

---

## 🧪 Code Patterns

### SwiftUI View Template
```swift
struct MeasurementView: View {
    @StateObject private var viewModel: MeasurementViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        // Implementation
    }
}
```

### ViewModel Template
```swift
@MainActor
final class MeasurementViewModel: ObservableObject {
    @Published private(set) var currentValue: Double = 0.0
    
    private let sessionService: SessionService
    
    init(sessionService: SessionService = .shared) {
        self.sessionService = sessionService
    }
}
```

### Circle Component Pattern
```swift
struct InteractiveCircle: View {
    let type: CircleType  // .self or .other
    @Binding var position: CGPoint
    @Binding var scale: Double
    
    var body: some View {
        Circle()
            .fill(type.gradient)
            .frame(width: 100 * scale, height: 100 * scale)
            .position(position)
            .gesture(dragGesture)
    }
}
```

---

## ✅ PR Checklist

Before submitting any PR, verify:

- [ ] Code compiles without warnings
- [ ] All comments are in English
- [ ] MVVM architecture respected
- [ ] No hardcoded strings (use Localizable)
- [ ] Supports Dark and Light modes
- [ ] Responsive on iPhone and iPad
- [ ] Accessibility labels added
- [ ] No force unwraps (`!`) without justification

---

## 📚 References

### Scientific Basis
- Aron, A., Aron, E. N., & Smollan, D. (1992). *Inclusion of Other in the Self Scale*
- Ollagnier-Beldame, M., & Coupé, C. (2019). *Meeting You for the First Time*

### Apple Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [SwiftData](https://developer.apple.com/documentation/swiftdata)

---

## 🚫 Don't

- Don't create files without asking
- Don't use UIKit when SwiftUI works
- Don't hardcode colors (use theme system)
- Don't skip accessibility
- Don't use `Any` or force casts
- Don't commit to `main` directly

## ✅ Do

- Ask before any file operation
- Use Swift 6 concurrency (`async/await`)
- Follow Apple HIG
- Write self-documenting code
- Use `@Observable` macro (iOS 17+)
- Test on multiple device sizes
