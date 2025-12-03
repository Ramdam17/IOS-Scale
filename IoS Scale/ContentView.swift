//
//  ContentView.swift
//  IoS Scale
//
//  Created by Remy Ramadour on 2025-11-23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
