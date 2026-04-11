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
    case welcome, login, signUp, onboarding, healthSync, dashboard
}

struct ContentView: View {
    @State private var screen: AppScreen

    init() {
        let loggedIn  = UserDefaults.standard.bool(forKey: "isLoggedIn")
        let onboarded = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if loggedIn && onboarded {
            _screen = State(initialValue: .dashboard)
        } else if loggedIn {
            _screen = State(initialValue: .onboarding)
        } else {
            _screen = State(initialValue: .welcome)
        }
    }

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
                DashboardView(onSignedOut: { transition(to: .welcome) })
                    .transition(.opacity)
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
