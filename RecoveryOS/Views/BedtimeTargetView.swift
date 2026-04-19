import SwiftUI

struct BedtimeTargetView: View {
    @AppStorage("bedtimeHour")      private var bedtimeHour: Int = 22
    @AppStorage("bedtimeMinute")    private var bedtimeMinute: Int = 30
    @AppStorage("bedtimeReminder")  private var bedtimeReminder: Bool = true
    @AppStorage("windDownMinutes")  private var windDownMinutes: Double = 30

    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let labelGray  = Color.white.opacity(0.45)

    @State private var tempDate = Date()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header("Bedtime Target", subtitle: "Set your ideal bedtime and wind-down")

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("TARGET BEDTIME")
                        DatePicker("", selection: $tempDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.wheel)
                            .environment(\.locale, Locale.current)
                            .tint(accentBlue)
                    }
                }

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("REMINDER")
                        toggleRow(title: "Bedtime Reminder", subtitle: "Notify me at my target bedtime") {
                            Toggle("", isOn: $bedtimeReminder).labelsHidden()
                        }
                    }
                }

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("WIND-DOWN")
                        HStack {
                            Text("Duration")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(windDownMinutes)) min")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(accentTeal)
                                .monospacedDigit()
                        }
                        Slider(value: $windDownMinutes, in: 0...90, step: 1)
                            .tint(accentTeal)
                    }
                }
            }
            .padding(16)
        }
        .background(bgPrimary.ignoresSafeArea())
        .navigationTitle("Bedtime Target")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { tempDate = makeDate(hour: bedtimeHour, minute: bedtimeMinute) }
        .onChange(of: tempDate) { newValue in
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            bedtimeHour   = comps.hour ?? 22
            bedtimeMinute = comps.minute ?? 0
        }
    }

    private func makeDate(hour: Int, minute: Int) -> Date {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
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
    NavigationStack { BedtimeTargetView() }
}
