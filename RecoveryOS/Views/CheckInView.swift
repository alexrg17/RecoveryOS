//
//  CheckInView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 16/03/2026.
//

import SwiftUI
import SwiftData
import UIKit

struct CheckInView: View {
    var prefill: HealthKitSnapshot? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Sliders (1-10)
    @State private var soreness:           Double = 5
    @State private var energy:             Double = 5
    @State private var stress:             Double = 5
    @State private var hydration:          Double = 5
    @State private var mood:               Double = 5
    @State private var nutritionAdherence: Double = 5

    // Biometric fields - pre-filled from HealthKit if available
    @State private var sleepHoursText: String
    @State private var hrvText:        String
    @State private var restingHRText:  String
    @State private var workoutLoad:    Double

    init(prefill: HealthKitSnapshot? = nil) {
        self.prefill    = prefill
        _sleepHoursText = State(initialValue: prefill?.sleepHours.map { String(format: "%.1f", $0) } ?? "")
        _hrvText        = State(initialValue: prefill?.hrvMs.map      { String(format: "%.0f", $0) } ?? "")
        _restingHRText  = State(initialValue: prefill?.restingHR.map  { String(format: "%.0f", $0) } ?? "")
        _workoutLoad    = State(initialValue: prefill.flatMap(\.workoutLoad) ?? 5)
    }

    // Design tokens
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

                        // Core sliders
                        VStack(spacing: 0) {
                            sectionHeader("WELLBEING")
                            VStack(spacing: 12) {
                                sliderRow(label: "Soreness",    value: $soreness,           invert: true)
                                sliderRow(label: "Energy",      value: $energy,             invert: false)
                                sliderRow(label: "Stress",      value: $stress,             invert: true)
                                sliderRow(label: "Hydration",   value: $hydration,          invert: false)
                                sliderRow(label: "Mood",        value: $mood,               invert: false)
                                sliderRow(label: "Nutrition",   value: $nutritionAdherence, invert: false)
                            }
                            .padding(16)
                            .background(bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Biometrics
                        VStack(spacing: 0) {
                            sectionHeader(prefill != nil ? "BIOMETRICS  •  FROM APPLE HEALTH" : "BIOMETRICS  •  OPTIONAL")
                            VStack(spacing: 12) {
                                biometricField(label: "Sleep Hours", placeholder: "e.g. 7.5", text: $sleepHoursText)
                                biometricField(label: "HRV (ms)",    placeholder: "e.g. 65",  text: $hrvText)
                                biometricField(label: "Resting HR (bpm)", placeholder: "e.g. 54", text: $restingHRText)
                                sliderRow(label: "Workout Load", value: $workoutLoad, invert: false)
                            }
                            .padding(16)
                            .background(bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Submit
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
        }
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
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { v in
                            // Swipe down on a slider resets it to 5
                            if v.translation.height > 30, abs(v.translation.height) > abs(v.translation.width) {
                                value.wrappedValue = 5
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                )
        }
    }

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

    // MARK: - Submit
    private func submit() {
        let score = DailyCheckIn.calculateScore(
            soreness:   Int(soreness),
            energy:     Int(energy),
            stress:     Int(stress),
            hydration:  Int(hydration),
            mood:       Int(mood),
            sleepHours: Double(sleepHoursText)
        )

        let checkIn = DailyCheckIn(
            soreness:           Int(soreness),
            energy:             Int(energy),
            stress:             Int(stress),
            hydration:          Int(hydration),
            mood:               Int(mood),
            nutritionAdherence: Int(nutritionAdherence),
            sleepHours:         Double(sleepHoursText),
            hrvMs:              Double(hrvText),
            restingHR:          Double(restingHRText),
            workoutLoad:        workoutLoad,
            readinessScore:     score
        )
        modelContext.insert(checkIn)
        NotificationManager.shared.scheduleRecoveryAlertIfNeeded(score: score)
        Task { try? await SupabaseService.shared.upsertCheckIn(checkIn) }
        dismiss()
    }
}

#Preview {
    CheckInView()
        .modelContainer(for: DailyCheckIn.self, inMemory: true)
}
