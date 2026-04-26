//
//  RecoveryOSApp.swift
//  RecoveryOS
//
//  Created by Alex Radu on 16/03/2026.
//

import SwiftUI
import SwiftData

@main
struct RecoveryOSApp: App {
    @Environment(\.scenePhase) private var scenePhase

    // DashboardController is created here at the app level so there is only ever
    // one instance shared across all views. If we created it inside DashboardView
    // it would be destroyed and recreated every time the view appeared, which
    // would reset the AI advice cache and trigger unnecessary regeneration.
    @StateObject private var dashboardController = DashboardController()

    // SwiftData requires a ModelContainer to be set up once and shared with
    // the whole view hierarchy via .modelContainer(). Building it as a stored
    // property rather than inside body means it is only created once per launch.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyCheckIn.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // SwiftData throws here when a new field has been added to a model and the
            // existing on-disk store cannot be migrated automatically. The safest
            // option during development is to delete the old store files and start
            // fresh rather than crashing, since test data can be re-entered easily.
            let storeURL = modelConfiguration.url
            let shmURL   = storeURL.deletingPathExtension().appendingPathExtension("store-shm")
            let walURL   = storeURL.deletingPathExtension().appendingPathExtension("store-wal")
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: shmURL)
            try? FileManager.default.removeItem(at: walURL)
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    init() {
        // Permission must be requested as early as possible so the OS dialog
        // appears at a natural point rather than interrupting the user later.
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Both shared objects are injected here so every view in the hierarchy
                // can access them via @EnvironmentObject without needing to pass them
                // explicitly through every intermediate view.
                .environmentObject(HealthKitManager.shared)
                .environmentObject(dashboardController)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, phase in
            // HealthKit data is refreshed every time the app comes back to the
            // foreground so that the dashboard always shows today's latest readings
            // even if the app has been in the background for several hours.
            if phase == .active,
               UserDefaults.standard.bool(forKey: "healthKitEnabled") {
                HealthKitManager.shared.requestAuthorization()
            }
        }
    }
}
