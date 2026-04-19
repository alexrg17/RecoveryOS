import SwiftUI

struct ChangeEmailView: View {
    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let labelGray  = Color.white.opacity(0.38)
    private let valueGray  = Color.white.opacity(0.45)

    @State private var currentEmail: String = "m.holloway@pro.com"
    @State private var newEmail: String = ""
    @State private var confirmEmail: String = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header("Change Email")

                cardSection {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CURRENT EMAIL")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(1.2)
                            .foregroundColor(labelGray)
                        Text(currentEmail)
                            .font(.system(size: 15))
                            .foregroundColor(valueGray)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NEW EMAIL")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(1.2)
                            .foregroundColor(labelGray)
                        TextField("Enter new email", text: $newEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text("CONFIRM EMAIL")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(1.2)
                            .foregroundColor(labelGray)
                        TextField("Re-enter new email", text: $confirmEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                Button(action: { saveAndClose() }) {
                    Text("Save Email")
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
        // Validate and save new email, then dismiss
        dismiss()
    }
}

#Preview {
    NavigationStack { ChangeEmailView() }
}
