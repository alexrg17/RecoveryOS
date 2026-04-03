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
    case welcome, login, signUp, main
}

struct ContentView: View {
    @State private var screen: AppScreen = .welcome
    @State private var showCheckIn       = false

    var body: some View {
        ZStack {
            switch screen {

            case .welcome:
                WelcomeView(
                    onGetStarted: { transition(to: .signUp) },
                    onSignIn:     { transition(to: .login)  }
                )
                .transition(.opacity)

            case .login:
                LoginView(
                    onSignedIn:      { transition(to: .main)    },
                    onCreateAccount: { transition(to: .signUp)  }
                )
                .transition(.asymmetric(
                    insertion:  .move(edge: .trailing).combined(with: .opacity),
                    removal:    .move(edge: .leading).combined(with: .opacity)
                ))

            case .signUp:
                SignUpView(
                    onAccountCreated: { transition(to: .main)   },
                    onSignIn:         { transition(to: .login)  }
                )
                .transition(.asymmetric(
                    insertion:  .move(edge: .trailing).combined(with: .opacity),
                    removal:    .move(edge: .leading).combined(with: .opacity)
                ))

            case .main:
                NavigationStack {
                    VStack(spacing: 24) {
                        Text("RecoveryOS")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Button(action: { showCheckIn = true }) {
                            Label("Log Check-In", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.teal)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    .sheet(isPresented: $showCheckIn) {
                        CheckInView()
                    }
                }
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
