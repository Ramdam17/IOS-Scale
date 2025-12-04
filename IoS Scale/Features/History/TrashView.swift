//
//  TrashView.swift
//  IoS Scale
//
//  View for managing deleted sessions (soft delete).
//

import SwiftUI
import SwiftData

/// Displays deleted sessions with restore and permanent delete options
struct TrashView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        filter: #Predicate<SessionModel> { $0.deletedAt != nil },
        sort: \SessionModel.deletedAt,
        order: .reverse
    ) private var deletedSessions: [SessionModel]
    
    @State private var showEmptyTrashConfirmation = false
    
    var body: some View {
        NavigationStack {
            Group {
                if deletedSessions.isEmpty {
                    emptyTrashView
                } else {
                    trashListView
                }
            }
            .gradientBackground()
            .navigationTitle("Trash")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !deletedSessions.isEmpty {
                        Button("Empty Trash") {
                            showEmptyTrashConfirmation = true
                        }
                        .foregroundStyle(.red)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Empty Trash?", isPresented: $showEmptyTrashConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Empty Trash", role: .destructive) {
                    emptyTrash()
                }
            } message: {
                Text("This will permanently delete \(deletedSessions.count) session(s). This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyTrashView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            Image(systemName: "trash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Trash is Empty")
                .font(Typography.title2)
            
            Text("Deleted sessions will appear here.\nYou can restore them or delete them permanently.")
                .font(Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            
            Spacer()
        }
    }
    
    // MARK: - Trash List
    
    private var trashListView: some View {
        List {
            Section {
                Text("\(deletedSessions.count) deleted session(s)")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }
            
            Section {
                ForEach(deletedSessions) { session in
                    TrashRowView(session: session)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                restoreSession(session)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                permanentlyDeleteSession(session)
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Actions
    
    private func restoreSession(_ session: SessionModel) {
        withAnimation {
            session.restore()
            HapticManager.shared.success()
        }
    }
    
    private func permanentlyDeleteSession(_ session: SessionModel) {
        withAnimation {
            modelContext.delete(session)
            HapticManager.shared.success()
        }
    }
    
    private func emptyTrash() {
        withAnimation {
            for session in deletedSessions {
                modelContext.delete(session)
            }
            HapticManager.shared.success()
        }
    }
}

// MARK: - Trash Row View

private struct TrashRowView: View {
    let session: SessionModel
    
    private var deletedAgo: String {
        guard let deletedAt = session.deletedAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: deletedAt, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Modality icon
            ZStack {
                Circle()
                    .fill(session.modality.tintColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: session.modality.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(session.modality.tintColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(session.modality.displayName)
                    .font(Typography.headline)
                    .foregroundStyle(.primary)
                
                HStack {
                    Label("\(session.measurements.count)", systemImage: "number")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.quaternary)
                    
                    Text("Deleted \(deletedAgo)")
                        .font(Typography.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Restore hint
            Image(systemName: "arrow.uturn.backward.circle")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .glassBackground()
    }
}

#Preview {
    TrashView()
        .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
