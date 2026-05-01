import SwiftUI

struct HydrationTargetView: View {
    @AppStorage("hydrationTargetLiters") private var targetLiters: Double = 2.5
    @AppStorage("hydrationUnit")         private var unit: String = "L"
    @AppStorage("hydrationReminder")     private var hydrationReminder: Bool = false

    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let labelGray  = Color.white.opacity(0.45)

    private let ozPerLiter = 33.814

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header("Hydration Target", subtitle: "Set your daily fluid goal")

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("UNIT")
                        Picker("Unit", selection: $unit) {
                            Text("Liters (L)").tag("L")
                            Text("Fluid Ounces (fl oz)").tag("fl oz")
                        }
                        .pickerStyle(.segmented)
                        .tint(accentBlue)
                    }
                }

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("DAILY TARGET")
                        HStack {
                            Text("Target")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Text(formattedTarget)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(accentTeal)
                                .monospacedDigit()
                        }
                        Slider(value: Binding(
                            get: { targetLiters },
                            set: { targetLiters = round($0 * 4) / 4 }
                        ), in: 1.0...5.0)
                        .tint(accentTeal)
                    }
                }

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("REMINDERS")
                        toggleRow(title: "Hydration Reminder", subtitle: "Send periodic prompts to drink water") {
                            Toggle("", isOn: $hydrationReminder).labelsHidden()
                        }
                    }
                }

            }
            .padding(16)
        }
        .background(bgPrimary.ignoresSafeArea())
        .navigationTitle("Hydration Target")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { Task { try? await SupabaseService.shared.syncAllPreferences() } }
    }

    private var formattedTarget: String {
        if unit == "L" {
            return String(format: "%.2f L", targetLiters)
        }
        let ounces = targetLiters * ozPerLiter
        return String(format: "%.0f fl oz", ounces)
    }

    // MARK: - Helpers
    @ViewBuilder private func header(_ title: String, subtitle: String? = nil) -> some View {
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

    @ViewBuilder private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .kerning(1.2)
            .foregroundColor(labelGray)
    }

    @ViewBuilder private func cardSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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

    @ViewBuilder private func toggleRow<Control: View>(title: String, subtitle: String, @ViewBuilder control: () -> Control) -> some View {
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
    NavigationStack { HydrationTargetView() }
}
