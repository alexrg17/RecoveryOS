import SwiftUI

struct ResetPasswordView: View {
    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let labelGray  = Color.white.opacity(0.38)

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header("Reset Password")

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CURRENT PASSWORD")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(1.2)
                            .foregroundColor(labelGray)
                        SecureField("Enter current password", text: $currentPassword)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text("NEW PASSWORD")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(1.2)
                            .foregroundColor(labelGray)
                        SecureField("Enter new password", text: $newPassword)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text("CONFIRM PASSWORD")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(1.2)
                            .foregroundColor(labelGray)
                        SecureField("Re-enter new password", text: $confirmPassword)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                Button(action: { saveAndClose() }) {
                    Text("Save Password")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(bgPrimary.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func header(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private func cardSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .background(bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private func saveAndClose() {
        // Validate and save password, then dismiss
        dismiss()
    }
}

#Preview {
    NavigationStack { ResetPasswordView() }
}
