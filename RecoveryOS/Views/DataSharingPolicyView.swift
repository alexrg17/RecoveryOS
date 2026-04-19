import SwiftUI

struct DataSharingPolicyView: View {
    @AppStorage("shareAnalytics") private var shareAnalytics: Bool = false
    @AppStorage("improveModels")  private var improveModels: Bool = true
    @AppStorage("crashReports")   private var crashReports: Bool = true

    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let labelGray  = Color.white.opacity(0.45)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header("Data Sharing Policy", subtitle: "Control how your data helps improve RecoveryOS")

                cardSection {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("ABOUT")
                        Text("We respect your privacy. You can choose what diagnostic and usage data you share to help us improve reliability and features. None of your health metrics are shared without your consent.")
                            .font(.system(size: 13))
                            .foregroundColor(labelGray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("SHARING OPTIONS")
                        toggleRow(title: "Share Anonymous Analytics", subtitle: "Help us understand general usage patterns") {
                            Toggle("", isOn: $shareAnalytics)
                                .toggleStyle(SwitchToggleStyle(tint: accentTeal))
                                .labelsHidden()
                        }
                        divider
                        toggleRow(title: "Improve Models with Usage Data", subtitle: "Improve recommendations and insights") {
                            Toggle("", isOn: $improveModels)
                                .toggleStyle(SwitchToggleStyle(tint: accentTeal))
                                .labelsHidden()
                        }
                        divider
                        toggleRow(title: "Crash Reports", subtitle: "Send crash logs to help us fix issues") {
                            Toggle("", isOn: $crashReports)
                                .toggleStyle(SwitchToggleStyle(tint: accentTeal))
                                .labelsHidden()
                        }
                    }
                }

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("POLICY")
                        HStack {
                            Text("View Full Policy")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(accentBlue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.35))
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                }
            }
            .padding(16)
        }
        .background(bgPrimary.ignoresSafeArea())
        .navigationTitle("Data Sharing")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Reusable UI
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

    private var divider: some View { Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1) }

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
    NavigationStack { DataSharingPolicyView() }
}
