//
//  Typography.swift
//  IoS Scale
//
//  Defines the app's typography scale using San Francisco.
//

import SwiftUI

// MARK: - Typography

enum Typography {
    /// Large title - Screen titles (34pt Bold Rounded)
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    
    /// Title - Section headers (28pt Bold Rounded)
    static let title = Font.system(.title, design: .rounded, weight: .bold)
    
    /// Title 2 - Subsection headers (22pt Bold Rounded)
    static let title2 = Font.system(.title2, design: .rounded, weight: .bold)
    
    /// Title 3 - Minor headers (20pt Semibold Rounded)
    static let title3 = Font.system(.title3, design: .rounded, weight: .semibold)
    
    /// Headline - Card titles (17pt Semibold Rounded)
    static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
    
    /// Body - Descriptions (17pt Regular Default)
    static let body = Font.system(.body, design: .default, weight: .regular)
    
    /// Callout - Secondary text (16pt Regular Default)
    static let callout = Font.system(.callout, design: .default, weight: .regular)
    
    /// Subheadline - Tertiary text (15pt Regular Default)
    static let subheadline = Font.system(.subheadline, design: .default, weight: .regular)
    
    /// Footnote - Small text (13pt Regular Default)
    static let footnote = Font.system(.footnote, design: .default, weight: .regular)
    
    /// Caption - Labels, hints (12pt Medium Rounded)
    static let caption = Font.system(.caption, design: .rounded, weight: .medium)
    
    /// Caption 2 - Smallest text (11pt Regular Default)
    static let caption2 = Font.system(.caption2, design: .default, weight: .regular)
    
    /// Numeric - Values display (24pt Medium Monospaced)
    static let numeric = Font.system(.title2, design: .monospaced, weight: .medium)
    
    /// Numeric Large - Large values (34pt Medium Monospaced)
    static let numericLarge = Font.system(.largeTitle, design: .monospaced, weight: .medium)
}

// MARK: - View Extension

extension View {
    /// Apply large title typography
    func largeTitleStyle() -> some View {
        self.font(Typography.largeTitle)
    }
    
    /// Apply title typography
    func titleStyle() -> some View {
        self.font(Typography.title)
    }
    
    /// Apply headline typography
    func headlineStyle() -> some View {
        self.font(Typography.headline)
    }
    
    /// Apply body typography
    func bodyStyle() -> some View {
        self.font(Typography.body)
    }
    
    /// Apply caption typography
    func captionStyle() -> some View {
        self.font(Typography.caption)
    }
    
    /// Apply numeric typography
    func numericStyle() -> some View {
        self.font(Typography.numeric)
    }
}
