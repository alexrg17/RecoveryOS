import SwiftUI
import Supabase

struct ResetPasswordView: View {
    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let labelGray  = Color.white.opacity(0.38)

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

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

                if showError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(errorMessage)
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 1.0, green: 0.38, blue: 0.38))
                    .padding(.top, 4)
                    .transition(.opacity)
                }

                if showSuccess {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Password updated successfully")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.25, green: 0.90, blue: 0.69))
                    .padding(.top, 4)
                    .transition(.opacity)
                }

                Button(action: saveAndClose) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(accentBlue)
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Password")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .disabled(isLoading)
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
        guard !newPassword.isEmpty else {
            showError(message: "Please enter a new password.")
            return
        }
        guard newPassword.count >= 8 else {
            showError(message: "Password must be at least 8 characters.")
            return
        }
        guard newPassword == confirmPassword else {
            showError(message: "Passwords do not match.")
            return
        }

        isLoading = true
        showError = false
        showSuccess = false

        Task {
            do {
                try await supabase.auth.update(user: UserAttributes(password: newPassword))
                await MainActor.run {
                    isLoading = false
                    withAnimation { showSuccess = true }
                    // Clear fields and dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError(message: error.localizedDescription)
                }
            }
        }
    }

    private func showError(message: String) {
        errorMessage = message
        withAnimation { showError = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation { showError = false }
        }
    }
}

#Preview {
    NavigationStack { ResetPasswordView() }
}
