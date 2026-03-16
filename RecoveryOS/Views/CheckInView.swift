//
//  CheckInView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 16/03/2026.
//

import SwiftUI
import SwiftData

struct CheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Core sliders (1–10)
    @State private var soreness: Double = 5
    @State private var energy: Double = 5
    @State private var stress: Double = 5
    @State private var hydration: Double = 5
    @State private var mood: Double = 5

    // Biometric text fields
    @State private var sleepHoursText = ""
    @State private var hrvText = ""
    @State private var restingHRText = ""
    @State private var workoutLoad: Double = 5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    coreSection
                    biometricsSection
                    submitButton
                }
                .padding()
            }
            .navigationTitle("Morning Check-In")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .tint(.teal)
    }

    // MARK: - Core Sliders

    private var coreSection: some View {
        VStack(spacing: 16) {
            sliderRow(label: "Soreness", value: $soreness)
            sliderRow(label: "Energy", value: $energy)
            sliderRow(label: "Stress", value: $stress)
            sliderRow(label: "Hydration", value: $hydration)
            sliderRow(label: "Mood", value: $mood)
        }
    }

    private func sliderRow(label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.headline)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.teal)
                    .monospacedDigit()
            }
            Slider(value: value, in: 1...10, step: 1)
        }
    }

    // MARK: - Biometrics

    private var biometricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Biometrics (Optional)")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 8)

            numericField(label: "Sleep Hours", placeholder: "e.g. 7.5", text: $sleepHoursText)
            numericField(label: "HRV (ms)", placeholder: "e.g. 45", text: $hrvText)
            numericField(label: "Resting HR (bpm)", placeholder: "e.g. 58", text: $restingHRText)
            sliderRow(label: "Workout Load", value: $workoutLoad)
        }
    }

    private func numericField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.headline)
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button(action: submit) {
            Text("Submit Check-In")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.teal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 8)
    }

    private func submit() {
        let checkIn = DailyCheckIn(
            soreness: Int(soreness),
            energy: Int(energy),
            stress: Int(stress),
            hydration: Int(hydration),
            mood: Int(mood),
            sleepHours: Double(sleepHoursText),
            hrvMs: Double(hrvText),
            restingHR: Double(restingHRText),
            workoutLoad: workoutLoad
        )
        modelContext.insert(checkIn)
        dismiss()
    }
}

#Preview {
    CheckInView()
        .modelContainer(for: DailyCheckIn.self, inMemory: true)
}
