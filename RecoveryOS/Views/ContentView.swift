//
//  ContentView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 16/03/2026.
//

import SwiftUI
import SwiftData

enum AppScreen {
    case welcome, dashboard
}

struct ContentView: View {
    @State private var screen: AppScreen = .welcome

    var body: some View {
        ZStack {
            switch screen {
            case .welcome:
                WelcomeView(
                    onGetStarted: {
                        withAnimation(.easeInOut(duration: 0.5)) { screen = .dashboard }
                    },
                    onSignIn: {
                        withAnimation(.easeInOut(duration: 0.5)) { screen = .dashboard }
                    }
                )
                .transition(.opacity)

            case .dashboard:
                DashboardView()
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DailyCheckIn.self, inMemory: true)
}
