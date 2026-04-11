//
//  ContentView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 16/03/2026.
//

import SwiftUI
import SwiftData

// MARK: - App screens
enum AppScreen {
    case welcome, login, signUp, onboarding, healthSync, dashboard, settings
}

struct ContentView: View {
    @State private var screen: AppScreen = .welcome

    var body: some View {
        ZStack {
            switch screen {

            case .welcome:
                WelcomeView(
                    onGetStarted: { transition(to: .signUp)  },
                    onSignIn:     { transition(to: .login)   }
                )
                .transition(.opacity)

            case .login:
                LoginView(
                    onSignedIn:      { transition(to: .dashboard)  },
                    onCreateAccount: { transition(to: .signUp)     }
                )
                .transition(.asymmetric(
                    insertion:  .move(edge: .trailing).combined(with: .opacity),
                    removal:    .move(edge: .leading).combined(with: .opacity)
                ))

            case .signUp:
                SignUpView(
                    onAccountCreated: { transition(to: .onboarding) },
                    onSignIn:         { transition(to: .login)       }
                )
                .transition(.asymmetric(
                    insertion:  .move(edge: .trailing).combined(with: .opacity),
                    removal:    .move(edge: .leading).combined(with: .opacity)
                ))

            case .onboarding:
                OnboardingView(onFinished: { transition(to: .healthSync) })
                    .transition(.asymmetric(
                        insertion:  .move(edge: .trailing).combined(with: .opacity),
                        removal:    .move(edge: .leading).combined(with: .opacity)
                    ))

            case .healthSync:
                HealthSyncView(
                    onSynced:   { transition(to: .dashboard) },
                    onSkipped:  { transition(to: .dashboard) }
                )
                .transition(.asymmetric(
                    insertion:  .move(edge: .trailing).combined(with: .opacity),
                    removal:    .move(edge: .leading).combined(with: .opacity)
                ))

            case .dashboard:
                DashboardView(onProfileTapped: { transition(to: .settings) })
                    .transition(.opacity)

            case .settings:
                SettingsView(onBack: { transition(to: .dashboard) })
                    .transition(.asymmetric(
                        insertion:  .move(edge: .trailing).combined(with: .opacity),
                        removal:    .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: screen)
    }

    private func transition(to next: AppScreen) {
        withAnimation(.easeInOut(duration: 0.4)) { screen = next }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DailyCheckIn.self, inMemory: true)
}
