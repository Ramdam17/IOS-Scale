//
//  HistoryView.swift
//  IoS Scale
//
//  Main view for browsing session history with filtering and sorting.
//

import SwiftUI
import SwiftData

/// Sorting options for session list
enum SessionSortOption: String, CaseIterable {
    case dateNewest = "Newest First"
    case dateOldest = "Oldest First"
    case mostMeasurements = "Most Measurements"
    case modalityName = "By Modality"
}

/// Main view displaying session history with search and filtering
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    @Query(
        filter: #Predicate<SessionModel> { $0.deletedAt == nil },
        sort: \SessionModel.createdAt,
        order: .reverse
    ) private var sessions: [SessionModel]
    
    @Query(
        filter: #Predicate<SessionModel> { $0.deletedAt != nil }
    ) private var trashedSessions: [SessionModel]
    
    @State private var searchText = ""
    @State private var sortOption: SessionSortOption = .dateNewest
    @State private var selectedModality: ModalityType?
    @State private var showExportSheet = false
    @State private var showTrashView = false
    
    private var filteredSessions: [SessionModel] {
        var result = sessions
        
        // Filter by modality
        if let modality = selectedModality {
            result = result.filter { $0.modality == modality }
        }
        
        // Filter by search text (matches notes or modality name)
        if !searchText.isEmpty {
            result = result.filter { session in
                session.modality.displayName.localizedCaseInsensitiveContains(searchText) ||
                (session.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Sort
        switch sortOption {
        case .dateNewest:
            result.sort { $0.createdAt > $1.createdAt }
        case .dateOldest:
            result.sort { $0.createdAt < $1.createdAt }
        case .mostMeasurements:
            result.sort { ($0.measurements ?? []).count > ($1.measurements ?? []).count }
        case .modalityName:
            result.sort { $0.modality.displayName < $1.modality.displayName }
        }
        
        return result
    }
    
    private var totalMeasurements: Int {
        sessions.reduce(0) { $0 + ($1.measurements ?? []).count }
    }
    
    private var usedModalities: [ModalityType] {
        Array(Set(sessions.map(\.modality))).sorted { $0.displayName < $1.displayName }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionListView
                }
            }
            .gradientBackground()
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search sessions...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !sessions.isEmpty {
                        Menu {
                            // Sort options
                            Section("Sort By") {
                                ForEach(SessionSortOption.allCases, id: \.self) { option in
                                    Button {
                                        sortOption = option
                                    } label: {
                                        HStack {
                                            Text(option.rawValue)
                                            if sortOption == option {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Modality filter
                            Section("Filter by Modality") {
                                Button {
                                    selectedModality = nil
                                } label: {
                                    HStack {
                                        Text("All Modalities")
                                        if selectedModality == nil {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                
                                ForEach(usedModalities) { modality in
                                    Button {
                                        selectedModality = modality
                                    } label: {
                                        HStack {
                                            Image(systemName: modality.iconName)
                                            Text(modality.displayName)
                                            if selectedModality == modality {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.sm) {
                        // Trash button with badge
                        Button {
                            showTrashView = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "trash")
                                
                                if !trashedSessions.isEmpty {
                                    Text("\(trashedSessions.count)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .padding(3)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                        
                        if !sessions.isEmpty {
                            Button {
                                showExportSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ExportSheet(sessions: nil)
            }
            .sheet(isPresented: $showTrashView) {
                TrashView()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundStyle(ColorPalette.selfCircleCore.gradient)
            
            Text("No Sessions Yet")
                .font(Typography.title2)
            
            Text("Start a measurement to see your history here.")
                .font(Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            
            Spacer()
        }
    }
    
    // MARK: - Session List
    
    private var sessionListView: some View {
        List {
            // Stats header section
            Section {
                statsHeader
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: Spacing.sm, leading: 0, bottom: Spacing.sm, trailing: 0))
            }
            
            // Filter indicator
            if selectedModality != nil || !searchText.isEmpty {
                Section {
                    filterIndicator
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
            }
            
            // Session list
            Section {
                ForEach(filteredSessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        SessionRowView(session: session)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteSession(session)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        HStack(spacing: Spacing.lg) {
            StatBox(
                value: "\(sessions.count)",
                label: "Sessions",
                color: ColorPalette.selfCircleCore
            )
            
            StatBox(
                value: "\(totalMeasurements)",
                label: "Measurements",
                color: ColorPalette.otherCircleCore
            )
            
            StatBox(
                value: "\(usedModalities.count)",
                label: "Modalities",
                color: Color(hex: "A29BFE")
            )
        }
        .padding(.vertical, Spacing.md)
    }
    
    // MARK: - Filter Indicator
    
    private var filterIndicator: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease")
                .foregroundStyle(.secondary)
            
            if let modality = selectedModality {
                Text("Filtered: \(modality.displayName)")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !searchText.isEmpty {
                Text("Search: \"\(searchText)\"")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(filteredSessions.count) results")
                .font(Typography.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, Spacing.sm)
    }
    
    // MARK: - Actions
    
    private func deleteSession(_ session: SessionModel) {
        withAnimation {
            session.moveToTrash()
            HapticManager.shared.success()
        }
    }
}

// MARK: - Stat Box Component

private struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(Typography.title)
                .foregroundStyle(color)
            
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .glassBackground()
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
