//
//  LoginView.swift
//  RecoveryOS
//
//  Created by Richy James on 28/03/2026.
//

import SwiftUI
import SwiftData
import Supabase

struct LoginView: View {

    var onSignedIn: () -> Void
    var onCreateAccount: () -> Void

    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    // Fields
    @State private var email           = ""
    @State private var password        = ""
    @State private var showPassword    = false

    // UI state
    @State private var emailFocused    = false
    @State private var passwordFocused = false
    @State private var isLoading       = false
    @State private var shakeOffset: CGFloat = 0
    @State private var showError       = false
    @State private var errorMessage    = ""

    // Entrance animations
    @State private var logoOpacity: Double   = 0
    @State private var logoSlide: CGFloat    = -20
    @State private var cardOpacity: Double   = 0
    @State private var cardSlide: CGFloat    = 40
    @State private var buttonOpacity: Double = 0

    // Glow pulse on card border
    @State private var borderGlow: Double    = 0.4

    // Spinner rotation
    @State private var spinnerAngle: Double  = 0

    // Controls the forgot-password sheet. Presented as a sheet rather than a
    // navigation push so the user can dismiss it without losing what they typed
    // in the email field below.
    @State private var showForgotPassword = false

    var body: some View {
        ZStack {

            // ── Background ────────────────────────────────────────────────
            Color(red: 0.04, green: 0.04, blue: 0.07)
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.18, green: 0.35, blue: 0.9).opacity(0.12),
                    Color.clear
                ],
                center: .top,
                startRadius: 10,
                endRadius: 420
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Logo ─────────────────────────────────────────────
                    VStack(spacing: 10) {
                        AnimatedLogoOrb()

                        Text("RecoveryOS")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .opacity(logoOpacity)
                    .offset(y: logoSlide)
                    .padding(.top, 60)
                    .padding(.bottom, 36)

                    // ── Card ─────────────────────────────────────────────
                    VStack(spacing: 0) {

                        // Header
                        VStack(spacing: 6) {
                            Text("Welcome back")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Sign in to continue your recovery journey")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.45))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 28)
                        .padding(.bottom, 28)

                        // ── Email field ───────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            Label("EMAIL", systemImage: "envelope")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .labelStyle(FieldLabelStyle())

                            ZStack(alignment: .leading) {
                                if email.isEmpty {
                                    Text("your@email.com")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.25))
                                        .padding(.leading, 16)
                                }
                                TextField("", text: $email)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { emailFocused = true; passwordFocused = false } }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        emailFocused
                                            ? Color(red: 0.28, green: 0.55, blue: 1.0).opacity(0.9)
                                            : Color.white.opacity(0.08),
                                        lineWidth: emailFocused ? 1.5 : 1
                                    )
                            )
                            .shadow(
                                color: emailFocused ? Color(red: 0.28, green: 0.55, blue: 1.0).opacity(0.35) : .clear,
                                radius: 8
                            )
                            .animation(.easeInOut(duration: 0.2), value: emailFocused)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 14)

                        // ── Password field ────────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            Label("PASSWORD", systemImage: "lock")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .labelStyle(FieldLabelStyle())

                            ZStack(alignment: .leading) {
                                if password.isEmpty {
                                    Text("••••••••")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.25))
                                        .padding(.leading, 16)
                                }
                                HStack {
                                    Group {
                                        if showPassword {
                                            TextField("", text: $password)
                                        } else {
                                            SecureField("", text: $password)
                                        }
                                    }
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { passwordFocused = true; emailFocused = false } }

                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.35))
                                    }
                                    .padding(.trailing, 14)
                                }
                                .padding(.leading, 16)
                                .padding(.vertical, 14)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        passwordFocused
                                            ? Color(red: 0.28, green: 0.55, blue: 1.0).opacity(0.9)
                                            : Color.white.opacity(0.08),
                                        lineWidth: passwordFocused ? 1.5 : 1
                                    )
                            )
                            .shadow(
                                color: passwordFocused ? Color(red: 0.28, green: 0.55, blue: 1.0).opacity(0.35) : .clear,
                                radius: 8
                            )
                            .animation(.easeInOut(duration: 0.2), value: passwordFocused)
                        }
                        .padding(.horizontal, 24)
                        .offset(x: shakeOffset)

                        // Forgot password — passes whatever is already in the email
                        // field so the user does not have to type it again in the sheet.
                        HStack {
                            Spacer()
                            Button("Forgot password?") { showForgotPassword = true }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.65, blue: 1.0))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)

                        // Error message
                        if showError {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 12))
                                Text(errorMessage)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(Color(red: 1.0, green: 0.38, blue: 0.38))
                            .padding(.top, 10)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        // ── Sign in button ────────────────────────────────
                        Button(action: handleSignIn) {
                            ZStack {
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.28, green: 0.48, blue: 0.98),
                                        Color(red: 0.22, green: 0.75, blue: 0.65)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )

                                if isLoading {
                                    Circle()
                                        .trim(from: 0.1, to: 0.9)
                                        .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                        .frame(width: 22, height: 22)
                                        .rotationEffect(.degrees(spinnerAngle))
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color(red: 0.28, green: 0.48, blue: 0.98).opacity(0.45), radius: 14, y: 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 22)
                        .disabled(isLoading)

                        // Divider
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                            Text("or")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.25))
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)

                        // Create account
                        Button(action: onCreateAccount) {
                            Text("Create an account")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(red: 0.09, green: 0.09, blue: 0.13))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.28, green: 0.55, blue: 1.0).opacity(borderGlow),
                                        Color(red: 0.22, green: 0.75, blue: 0.65).opacity(borderGlow * 0.6),
                                        Color(red: 0.28, green: 0.55, blue: 1.0).opacity(borderGlow * 0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: borderGlow)
                    )
                    .shadow(color: Color(red: 0.2, green: 0.4, blue: 0.9).opacity(0.15), radius: 30, y: 10)
                    .padding(.horizontal, 20)
                    .opacity(cardOpacity)
                    .offset(y: cardSlide)

                    Spacer(minLength: 40)
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                emailFocused    = false
                passwordFocused = false
            }
        }
        .onAppear { beginAnimations() }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(prefillEmail: email)
        }
    }

    // MARK: - Actions
    private func handleSignIn() {
        withAnimation(.easeInOut(duration: 0.2)) {
            emailFocused    = false
            passwordFocused = false
        }

        guard !email.isEmpty, !password.isEmpty else {
            triggerError("Please fill in all fields.")
            return
        }
        guard email.contains("@") else {
            triggerError("Please enter a valid email address.")
            return
        }

        isLoading = true
        withAnimation(.linear(duration: 0.6).repeatForever(autoreverses: false)) {
            spinnerAngle = 360
        }

        Task {
            do {
                let session = try await supabase.auth.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading    = false
                    spinnerAngle = 0
                    // Create a local profile if none exists (e.g. signed out and back in)
                    if profiles.isEmpty {
                        let meta     = session.user.userMetadata
                        let name: String
                        if case .string(let n) = meta["full_name"] { name = n } else { name = "" }
                        let profile  = UserProfile(name: name, email: session.user.email ?? email)
                        modelContext.insert(profile)
                    }
                    isLoggedIn   = true
                    onSignedIn()
                }
            } catch {
                await MainActor.run {
                    isLoading    = false
                    spinnerAngle = 0
                    triggerError(friendlyAuthError(error))
                }
            }
        }
    }

    private func friendlyAuthError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("email not confirmed") || msg.contains("not confirmed") {
            return "Please confirm your email before signing in. Check your inbox."
        } else if msg.contains("invalid login") || msg.contains("invalid credentials") || msg.contains("wrong password") {
            return "Incorrect email or password."
        } else if msg.contains("user not found") || msg.contains("no user") {
            return "No account found with that email."
        } else if msg.contains("network") || msg.contains("connection") || msg.contains("offline") {
            return "Connection error. Please check your internet."
        } else if msg.contains("rate limit") || msg.contains("too many") {
            return "Too many attempts. Please wait a moment and try again."
        }
        return "Sign in failed. Please try again."
    }

    private func triggerError(_ message: String) {
        errorMessage = message
        withAnimation(.spring()) { showError = true }
        // Shake
        let shakes: [(CGFloat, Double)] = [(10, 0.0), (-10, 0.08), (8, 0.16), (-8, 0.24), (4, 0.32), (0, 0.40)]
        for (offset, delay) in shakes {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.07)) { shakeOffset = offset }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation { showError = false }
        }
    }

    // MARK: - Entrance animations
    private func beginAnimations() {
        withAnimation(.easeOut(duration: 0.7)) {
            logoOpacity = 1
            logoSlide   = 0
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.25)) {
            cardOpacity = 1
            cardSlide   = 0
        }
        borderGlow = 0.85
    }
}

// MARK: - Field label style (icon hidden, just text)
struct FieldLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.title
    }
}

// MARK: - Forgot password sheet

// Shown when the user taps "Forgot password?" on the login screen.
// Calls Supabase's password reset API which emails a magic link — the user
// does not need to be signed in for this to work, which is why it lives here
// rather than in the Settings screen alongside ResetPasswordView.
private struct ForgotPasswordView: View {

    var prefillEmail: String

    // Email is copied from the login field via prefillEmail so the user does
    // not have to type it a second time.
    @State private var email:         String
    @State private var isLoading      = false
    @State private var emailSent      = false
    @State private var errorMessage   = ""
    @State private var showError      = false

    @Environment(\.dismiss) private var dismiss

    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let labelGray  = Color.white.opacity(0.45)

    init(prefillEmail: String) {
        self.prefillEmail = prefillEmail
        _email = State(initialValue: prefillEmail)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                bgPrimary.ignoresSafeArea()

                VStack(spacing: 28) {

                    // Icon
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(accentBlue)
                        .padding(.top, 24)

                    // Heading
                    VStack(spacing: 8) {
                        Text("Reset Password")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Enter your email and we'll send you a reset link.")
                            .font(.system(size: 14))
                            .foregroundStyle(labelGray)
                            .multilineTextAlignment(.center)
                    }

                    if emailSent {
                        // Success state — replace the form so the user cannot
                        // accidentally tap "Send" a second time.
                        VStack(spacing: 14) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(accentTeal)
                            Text("Check your inbox")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("A reset link has been sent to\n\(email)")
                                .font(.system(size: 14))
                                .foregroundStyle(labelGray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )

                    } else {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL")
                                .font(.system(size: 10, weight: .semibold))
                                .kerning(1.5)
                                .foregroundStyle(labelGray)
                            TextField("your@email.com", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 15))
                                .foregroundStyle(.white)
                                .padding(14)
                                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }

                        if showError {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 12))
                                Text(errorMessage)
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(Color(red: 1.0, green: 0.38, blue: 0.38))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        // Send button
                        Button(action: sendResetEmail) {
                            ZStack {
                                LinearGradient(
                                    colors: [accentBlue, accentTeal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Send Reset Link")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: accentBlue.opacity(0.4), radius: 14, y: 4)
                        }
                        .disabled(isLoading)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
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

    // Calls the Supabase password reset API. On success, Supabase sends an email
    // containing a magic link that lets the user set a new password from a browser.
    // No auth session is required for this call — it only needs the email address.
    private func sendResetEmail() {
        guard !email.isEmpty, email.contains("@") else {
            errorMessage = "Please enter a valid email address."
            withAnimation { showError = true }
            return
        }

        isLoading  = true
        showError  = false

        Task {
            do {
                try await supabase.auth.resetPasswordForEmail(email)
                await MainActor.run {
                    isLoading = false
                    withAnimation { emailSent = true }
                }
            } catch {
                await MainActor.run {
                    isLoading     = false
                    errorMessage  = "Could not send reset email. Please try again."
                    withAnimation { showError = true }
                }
            }
        }
    }
}

#Preview {
    LoginView(onSignedIn: {}, onCreateAccount: {})
}
