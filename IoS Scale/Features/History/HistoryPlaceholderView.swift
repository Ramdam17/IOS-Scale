//
//  HistoryPlaceholderView.swift
//  IoS Scale
//
//  Placeholder view for session history (Sprint 4).
//

import SwiftUI

/// Placeholder view for session history - will be fully implemented in Sprint 4
struct HistoryPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Icon
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 60))
                    .foregroundStyle(ColorPalette.selfCircleCore.gradient)
                
                // Title
                Text("Session History")
                    .font(Typography.title2)
                
                // Description
                Text("Your measurement history will appear here.\nThis feature is coming in a future update.")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gradientBackground()
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HistoryPlaceholderView()
}
