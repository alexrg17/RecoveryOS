//
//  SignUpView.swift
//  RecoveryOS
//
//  Created by Richy James on 28/03/2026.
//

import SwiftUI
import SwiftData
import Supabase

struct SignUpView: View {

    var onAccountCreated: () -> Void
    var onSignIn: () -> Void

    @Environment(\.modelContext) private var modelContext
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    // Fields
    @State private var fullName         = ""
    @State private var email            = ""
    @State private var password         = ""
    @State private var confirmPassword  = ""
    @State private var showPassword     = false
    @State private var showConfirm      = false

    // Focus
    @State private var focusedField: Field? = nil
    enum Field { case name, email, password, confirm }

    // UI state
    @State private var isLoading        = false
    @State private var shakeOffset: CGFloat = 0
    @State private var showError        = false
    @State private var errorMessage     = ""
    @State private var spinnerAngle: Double = 0

    // Entrance animations
    @State private var logoOpacity: Double  = 0
    @State private var logoSlide: CGFloat   = -20
    @State private var cardOpacity: Double  = 0
    @State private var cardSlide: CGFloat   = 50
    @State private var borderGlow: Double   = 0.4

    // Password strength
    private var passwordStrength: Int {
        var score = 0
        if password.count >= 8         { score += 1 }
        if password.count >= 12        { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil    { score += 1 }
        return score // 0-4
    }
    private var strengthLabel: String {
        ["", "Weak", "Fair", "Good", "Strong"][max(0, min(passwordStrength, 4))]
    }
    private var strengthColor: Color {
        switch passwordStrength {
        case 1:  return Color(red: 1.0, green: 0.4, blue: 0.4)
        case 2:  return Color(red: 1.0, green: 0.75, blue: 0.2)
        case 3:  return Color(red: 0.4, green: 0.85, blue: 0.55)
        case 4:  return Color(red: 0.25, green: 0.9, blue: 0.65)
        default: return Color.white.opacity(0.15)
        }
    }

    var body: some View {
        ZStack {

            // ── Background ────────────────────────────────────────────────
            Color(red: 0.04, green: 0.04, blue: 0.07)
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.35, green: 0.2, blue: 0.85).opacity(0.1),
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
                    .padding(.top, 50)
                    .padding(.bottom, 28)

                    // ── Card ─────────────────────────────────────────────
                    VStack(spacing: 0) {

                        // Header
                        VStack(spacing: 6) {
                            Text("Create your account")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Start your personalised recovery journey")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.45))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 26)
                        .padding(.bottom, 24)

                        // ── Full name ─────────────────────────────────────
                        inputField(
                            label: "FULL NAME",
                            placeholder: "Alex Johnson",
                            text: $fullName,
                            field: .name,
                            keyboard: .default,
                            isSecure: false,
                            showToggle: false
                        )
                        .padding(.bottom, 14)

                        // ── Email ─────────────────────────────────────────
                        inputField(
                            label: "EMAIL",
                            placeholder: "your@email.com",
                            text: $email,
                            field: .email,
                            keyboard: .emailAddress,
                            isSecure: false,
                            showToggle: false
                        )
                        .padding(.bottom, 14)

                        // ── Password ──────────────────────────────────────
                        inputField(
                            label: "PASSWORD",
                            placeholder: "Min. 8 characters",
                            text: $password,
                            field: .password,
                            keyboard: .default,
                            isSecure: !showPassword,
                            showToggle: true,
                            isVisible: $showPassword
                        )

                        // Password strength bar
                        VStack(alignment: .leading, spacing: 4) {
                            if !password.isEmpty {
                                HStack(spacing: 4) {
                                    ForEach(0..<4) { i in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(i < passwordStrength ? strengthColor : Color.white.opacity(0.1))
                                            .frame(height: 3)
                                            .animation(.easeInOut(duration: 0.3), value: passwordStrength)
                                    }
                                }
                                .transition(.opacity)

                                if !strengthLabel.isEmpty {
                                    Text(strengthLabel)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(strengthColor)
                                        .transition(.opacity)
                                        .animation(.easeInOut(duration: 0.2), value: strengthLabel)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, password.isEmpty ? 0 : 8)
                        .frame(height: password.isEmpty ? 0 : nil)
                        .clipped()

                        // ── Confirm password ──────────────────────────────
                        inputField(
                            label: "CONFIRM PASSWORD",
                            placeholder: "Repeat your password",
                            text: $confirmPassword,
                            field: .confirm,
                            keyboard: .default,
                            isSecure: !showConfirm,
                            showToggle: true,
                            isVisible: $showConfirm
                        )
                        .padding(.top, 14)
                        .offset(x: shakeOffset)

                        // Error
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

                        // ── Create account button ─────────────────────────
                        Button(action: handleSignUp) {
                            ZStack {
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.28, green: 0.48, blue: 0.98),
                                        Color(red: 0.22, green: 0.78, blue: 0.65)
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
                                    HStack(spacing: 8) {
                                        Text("Create Account")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color(red: 0.28, green: 0.48, blue: 0.98).opacity(0.4), radius: 14, y: 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 22)
                        .disabled(isLoading)

                        // Terms note
                        Text("By creating an account you agree to our Terms of Service and Privacy Policy.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.25))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .padding(.top, 12)

                        // Divider
                        HStack(spacing: 12) {
                            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                            Text("or").font(.system(size: 12)).foregroundColor(.white.opacity(0.25))
                            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)

                        // Sign in
                        Button(action: onSignIn) {
                            Text("Already have an account? Sign in")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 0.4, green: 0.65, blue: 1.0))
                        }
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
                                        Color(red: 0.45, green: 0.28, blue: 1.0).opacity(borderGlow),
                                        Color(red: 0.28, green: 0.55, blue: 1.0).opacity(borderGlow * 0.7),
                                        Color(red: 0.22, green: 0.75, blue: 0.65).opacity(borderGlow * 0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: borderGlow)
                    )
                    .shadow(color: Color(red: 0.35, green: 0.2, blue: 0.85).opacity(0.15), radius: 30, y: 10)
                    .padding(.horizontal, 20)
                    .opacity(cardOpacity)
                    .offset(y: cardSlide)

                    Spacer(minLength: 40)
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) { focusedField = nil }
        }
        .onAppear { beginAnimations() }
    }

    // MARK: - Reusable input field
    @ViewBuilder
    private func inputField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        keyboard: UIKeyboardType,
        isSecure: Bool,
        showToggle: Bool,
        isVisible: Binding<Bool> = .constant(false)
    ) -> some View {
        let isFocused = focusedField == field

        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .padding(.leading, 2)

            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.22))
                        .padding(.leading, 16)
                }
                HStack {
                    Group {
                        if isSecure {
                            SecureField("", text: text)
                        } else {
                            TextField("", text: text)
                                .keyboardType(keyboard)
                                .autocapitalization(keyboard == .emailAddress ? .none : .words)
                                .disableAutocorrection(keyboard == .emailAddress)
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) { focusedField = field }
                    }

                    if showToggle {
                        Button(action: { isVisible.wrappedValue.toggle() }) {
                            Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        .padding(.trailing, 14)
                    }
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
                        isFocused
                            ? Color(red: 0.45, green: 0.3, blue: 1.0).opacity(0.9)
                            : Color.white.opacity(0.08),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .shadow(
                color: isFocused ? Color(red: 0.45, green: 0.3, blue: 1.0).opacity(0.3) : .clear,
                radius: 8
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Actions
    private func handleSignUp() {
        withAnimation { focusedField = nil }

        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            triggerError("Please fill in all fields.")
            return
        }
        guard email.contains("@") else {
            triggerError("Please enter a valid email address.")
            return
        }
        guard password.count >= 8 else {
            triggerError("Password must be at least 8 characters.")
            return
        }
        guard password == confirmPassword else {
            triggerError("Passwords do not match.")
            return
        }

        isLoading = true
        withAnimation(.linear(duration: 0.6).repeatForever(autoreverses: false)) {
            spinnerAngle = 360
        }

        Task {
            do {
                try await supabase.auth.signUp(
                    email: email,
                    password: password,
                    data: ["full_name": AnyJSON(fullName)]
                )
                let newProfile = UserProfile(name: fullName, email: email)
                await MainActor.run {
                    isLoading    = false
                    spinnerAngle = 0
                    // Remove any stale profiles from previous accounts before inserting
                    let stale = (try? modelContext.fetch(FetchDescriptor<UserProfile>())) ?? []
                    stale.forEach { modelContext.delete($0) }
                    modelContext.insert(newProfile)
                    try? modelContext.save()
                    isLoggedIn   = true
                    onAccountCreated()
                }
                // Persist skeleton profile to Supabase immediately
                try? await SupabaseService.shared.upsertProfile(newProfile)
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
        if msg.contains("already registered") || msg.contains("already exists") || msg.contains("user already") {
            return "An account with this email already exists. Try signing in."
        } else if msg.contains("password") && (msg.contains("weak") || msg.contains("short")) {
            return "Password is too weak. Use at least 8 characters with numbers and uppercase."
        } else if msg.contains("network") || msg.contains("connection") || msg.contains("offline") {
            return "Connection error. Please check your internet."
        } else if msg.contains("rate limit") || msg.contains("too many") {
            return "Too many attempts. Please wait a moment and try again."
        }
        return "Sign up failed. Please try again."
    }

    private func triggerError(_ message: String) {
        errorMessage = message
        withAnimation(.spring()) { showError = true }
        let shakes: [(CGFloat, Double)] = [(10, 0.0), (-10, 0.08), (8, 0.16), (-8, 0.24), (4, 0.32), (0, 0.40)]
        for (offset, delay) in shakes {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.07)) { shakeOffset = offset }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation { showError = false }
        }
    }

    private func beginAnimations() {
        withAnimation(.easeOut(duration: 0.7)) {
            logoOpacity = 1
            logoSlide   = 0
        }
        withAnimation(.spring(response: 0.75, dampingFraction: 0.8).delay(0.25)) {
            cardOpacity = 1
            cardSlide   = 0
        }
        borderGlow = 0.9
    }
}

#Preview {
    SignUpView(onAccountCreated: {}, onSignIn: {})
}
