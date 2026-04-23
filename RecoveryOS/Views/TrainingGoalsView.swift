import SwiftUI
import SwiftData

struct TrainingGoalsView: View {
    // Persistence
    @AppStorage("trainingIntensityBias") private var intensityBias: String = "LIT"
    @AppStorage("dailyStrainTarget")    private var dailyStrain: Double = 6.0
    @AppStorage("autoRestDay")          private var autoRestDay: Bool = true

    // SwiftData — keep UserProfile.intensity in sync
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    // UI state for segmented
    @State private var selectedBiasIndex: Int = 0 // 0 = LIT, 1 = HIT

    // Design tokens
    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let labelGray  = Color.white.opacity(0.45)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header("Training Goals", subtitle: "Configure your preferred training targets")

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("INTENSITY BIAS")
                        Picker("Intensity Bias", selection: $selectedBiasIndex) {
                            Text("LIT").tag(0)
                            Text("HIT").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .tint(accentBlue)
                    }
                }

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("DAILY STRAIN TARGET")
                        HStack {
                            Text("Target: ")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Text(String(format: "%.1f", dailyStrain))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(accentTeal)
                                .monospacedDigit()
                        }
                        Slider(value: $dailyStrain, in: 0...10, step: 0.5)
                            .tint(accentTeal)
                    }
                }

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("REST DAYS")
                        toggleRow(title: "Auto Rest-Day Detection", subtitle: "Use low recovery scores to schedule rest") {
                            Toggle("", isOn: $autoRestDay).labelsHidden()
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(bgPrimary.ignoresSafeArea())
        .navigationTitle("Training Goals")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // If UserProfile has intensity data from onboarding, treat it as source of truth
            if let profile {
                let isHIT = profile.intensity >= 0.5
                intensityBias     = isHIT ? "HIT" : "LIT"
                selectedBiasIndex = isHIT ? 1 : 0
            } else {
                selectedBiasIndex = intensityBias == "HIT" ? 1 : 0
            }
        }
        .onChange(of: selectedBiasIndex) { _, newValue in
            intensityBias = newValue == 1 ? "HIT" : "LIT"
            if let profile {
                profile.intensity = newValue == 1 ? 1.0 : 0.0
                try? modelContext.save()
            }
        }
    }

    // MARK: - UI helpers
    @ViewBuilder
    private func header(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.5))
            }
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .kerning(1.2)
            .foregroundColor(labelGray)
    }

    @ViewBuilder
    private func cardSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) { content() }
                .padding(14)
                .background(bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private func toggleRow<Control: View>(title: String, subtitle: String, @ViewBuilder control: () -> Control) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(labelGray)
            }
            Spacer()
            control()
        }
    }
}

#Preview {
    NavigationStack { TrainingGoalsView() }
}
