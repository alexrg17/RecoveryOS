//
//  ContentView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 16/03/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showWelcome   = true
    @State private var showCheckIn   = false

    var body: some View {
        ZStack {
            if showWelcome {
                WelcomeView(
                    onGetStarted: {
                        withAnimation(.easeInOut(duration: 0.5)) { showWelcome = false }
                    },
                    onSignIn: {
                        withAnimation(.easeInOut(duration: 0.5)) { showWelcome = false }
                    }
                )
                .transition(.opacity)
            } else {
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DailyCheckIn.self, inMemory: true)
}
