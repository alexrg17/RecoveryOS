import SwiftUI
import SwiftData
import Supabase

struct ChangeEmailView: View {
    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let labelGray  = Color.white.opacity(0.38)
    private let valueGray  = Color.white.opacity(0.45)

    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var newEmail:     String = ""
    @State private var confirmEmail: String = ""
    @State private var isLoading    = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    private var currentEmail: String {
        profiles.first?.email ?? (supabase.auth.currentUser?.email ?? "")
    }

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
                            .foregroundColor(.white)
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
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                if let err = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(err)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 1.0, green: 0.38, blue: 0.38))
                }

                if let ok = successMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text(ok)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.25, green: 0.90, blue: 0.69))
                }

                Button(action: saveEmail) {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Save Email")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(isLoading)
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(bgPrimary.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveEmail() {
        errorMessage   = nil
        successMessage = nil
        guard !newEmail.isEmpty, !confirmEmail.isEmpty else { errorMessage = "Please fill in both fields."; return }
        guard newEmail.contains("@") else { errorMessage = "Please enter a valid email address."; return }
        guard newEmail == confirmEmail else { errorMessage = "Emails do not match."; return }
        guard newEmail != currentEmail else { errorMessage = "That is already your current email."; return }

        isLoading = true
        Task {
            do {
                try await supabase.auth.update(user: UserAttributes(email: newEmail))
                await MainActor.run {
                    profiles.first?.email = newEmail
                    try? modelContext.save()
                    isLoading      = false
                    successMessage = "Email updated. Check your inbox to confirm the change."
                    newEmail       = ""
                    confirmEmail   = ""
                }
            } catch {
                await MainActor.run {
                    isLoading     = false
                    errorMessage  = "Failed to update email. Please try again."
                }
            }
        }
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

#Preview {
    NavigationStack { ChangeEmailView() }
}
