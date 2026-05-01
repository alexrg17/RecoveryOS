//
//  CheckInView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 16/03/2026.
//

import SwiftUI
import SwiftData
import UIKit

// Presents the morning check-in form and forwards all actions to CheckInController.
// This view intentionally contains no business logic so it stays easy to read
// and any changes to scoring or persistence only need to happen in one place.
struct CheckInView: View {

    // If HealthKit data is available the controller will pre-fill the biometric
    // fields on appear. Passing nil means the user fills everything in manually.
    var prefill: HealthKitSnapshot? = nil

    // @StateObject keeps the controller alive for the lifetime of this view.
    // Using @StateObject rather than @ObservedObject prevents the controller
    // from being recreated if a parent view re-renders.
    @StateObject private var controller = CheckInController()

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    // Colours are defined as private constants so they can be changed in one place
    // if the design is updated, rather than hunting through every modifier.
    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let labelGray  = Color.white.opacity(0.45)

    var body: some View {
        NavigationStack {
            ZStack {
                bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Header
                        VStack(spacing: 6) {
                            Text("Morning Check-In")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("How is your body feeling today?")
                                .font(.system(size: 14))
                                .foregroundStyle(labelGray)
                        }
                        .padding(.top, 8)

                        // Wellbeing sliders — bound to controller state
                        VStack(spacing: 0) {
                            sectionHeader("WELLBEING")
                            VStack(spacing: 12) {
                                sliderRow(label: "Soreness",    value: $controller.soreness,           invert: true)
                                sliderRow(label: "Energy",      value: $controller.energy,             invert: false)
                                sliderRow(label: "Stress",      value: $controller.stress,             invert: true)
                                sliderRow(label: "Hydration",   value: $controller.hydration,          invert: false)
                                sliderRow(label: "Mood",        value: $controller.mood,               invert: false)
                                sliderRow(label: "Nutrition",   value: $controller.nutritionAdherence, invert: false)
                            }
                            .padding(16)
                            .background(bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Biometrics — pre-filled from HealthKit by the controller
                        VStack(spacing: 0) {
                            sectionHeader(prefill != nil ? "BIOMETRICS  •  FROM APPLE HEALTH" : "BIOMETRICS  •  OPTIONAL")
                            VStack(spacing: 12) {
                                biometricField(label: "Sleep Hours",      placeholder: "e.g. 7.5", text: $controller.sleepHoursText)
                                biometricField(label: "HRV (ms)",         placeholder: "e.g. 65",  text: $controller.hrvText)
                                biometricField(label: "Resting HR (bpm)", placeholder: "e.g. 54",  text: $controller.restingHRText)
                                sliderRow(label: "Workout Load", value: $controller.workoutLoad, invert: false)
                            }
                            .padding(16)
                            .background(bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Submit — View delegates action to Controller
                        Button(action: submit) {
                            Text("Submit Check-In")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    LinearGradient(
                                        colors: [accentBlue, accentTeal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: accentBlue.opacity(0.4), radius: 14, y: 4)
                        }
                        .padding(.bottom, 16)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(labelGray)
                }
            }
            .toolbarBackground(bgPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            // Controller pre-fills biometrics from HealthKit on appear
            .onAppear { controller.prefill(from: prefill) }
        }
    }

    // MARK: - Submit

    // Tells the controller to build and save the check-in, then dismisses the sheet.
    // The dismiss happens after submit so SwiftData has already inserted the record
    // before the dashboard re-queries and tries to display it.
    private func submit() {
        controller.submit(into: modelContext)
        dismiss()
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .kerning(1.5)
            .foregroundStyle(labelGray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
    }

    // MARK: - Slider row

    private func sliderRow(label: String, value: Binding<Double>, invert: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(sliderColor(value: value.wrappedValue, invert: invert))
                    .monospacedDigit()
            }
            Slider(value: value, in: 1...10, step: 1)
                .tint(sliderColor(value: value.wrappedValue, invert: invert))
                // A downward swipe on any slider resets it to the neutral value of 5.
                // This gesture is intentionally different from moving the slider thumb
                // so it acts as a quick undo without needing a separate button.
                // The direction check (height > width) prevents horizontal drags from
                // accidentally triggering the reset while the user adjusts the value.
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { v in
                            if v.translation.height > 30, abs(v.translation.height) > abs(v.translation.width) {
                                value.wrappedValue = 5
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                )
        }
    }

    // Produces a colour that reflects how good or bad the slider value is.
    // The invert flag handles metrics where a low score is actually positive
    // (such as soreness and stress) so the same colour logic works for all sliders.
    private func sliderColor(value: Double, invert: Bool) -> Color {
        let normalized = invert ? (11 - value) / 10.0 : value / 10.0
        switch normalized {
        case 0.8...: return accentTeal
        case 0.6...: return Color(red: 0.4, green: 0.85, blue: 0.55)
        case 0.4...: return Color(red: 1.0, green: 0.75, blue: 0.2)
        default:     return Color(red: 1.0, green: 0.38, blue: 0.38)
        }
    }

    // MARK: - Biometric field

    private func biometricField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }
    }
}

#Preview {
    CheckInView()
        .modelContainer(for: DailyCheckIn.self, inMemory: true)
}
