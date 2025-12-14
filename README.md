# IOS Scale

IOS Scale is an iOS/iPadOS application for measuring intersubjective experiences using visual circle-based scales. The application implements and extends the Inclusion of Other in the Self (IOS) Scale, a validated psychological measure of interpersonal closeness.

## Overview

The application provides 9 measurement modalities:

- Basic IOS: Classic two-circle overlap measurement
- Advanced IOS: Two-circle overlap with adjustable circle sizes
- Overlap: Percentage-based overlap visualization
- Set Membership: Venn diagram style inclusion
- Proximity: Distance-based measurement
- Identification: Directional relationship from self to other
- Projection: Directional relationship from other to self
- Attribution: Attribute assignment between entities
- Observation: Observer perspective measurement

All measurements use a normalized 0.0 to 1.0 scale for consistency and export compatibility.

## Requirements

- iOS 26.0 or later
- iPadOS 26.0 or later
- Xcode 26.0 or later for building

## Building

1. Clone the repository
2. Open IoS Scale.xcodeproj in Xcode
3. Select your target device or simulator
4. Build and run (Cmd+R)

## Usage

1. Select a measurement modality from the home screen
2. Drag circles or use the slider to adjust the measurement value
3. Tap Done to save the measurement
4. View measurement history from the History tab
5. Export data to CSV, TSV, or JSON format

## Data Export

Measurements can be exported in three formats:

- CSV: Comma-separated values with headers
- TSV: Tab-separated values with headers
- JSON: Hierarchical structure with session metadata

## Scientific Background

This application is based on established research in intersubjective measurement:

Aron, A., Aron, E. N., and Smollan, D. (1992). Inclusion of Other in the Self Scale and the Structure of Interpersonal Closeness. Journal of Personality and Social Psychology, 63(4), 596-612.

Ollagnier-Beldame, M., and Coupe, C. (2019). Meeting You for the First Time: Descriptive Categories of an Intersubjective Experience. Constructivist Foundations, 14(2), 167-180.

Coupe, C., and Ollagnier-Beldame, M. (2022). Diversity in Intersubjective Representations. Frontiers in Psychology, 13, 810157.

## Architecture

The application follows MVVM architecture with SwiftUI and SwiftData:

- Models: Session, Measurement, ModalityType, AppSettings
- ViewModels: One per measurement modality
- Views: SwiftUI views with Liquid Glass design language
- Services: Export, CloudSync, Haptic feedback

## License

CC0 1.0 Universal

To the extent possible under law, the author has waived all copyright and related or neighboring rights to this work.

This work is published from France.

See https://creativecommons.org/publicdomain/zero/1.0/ for details.

