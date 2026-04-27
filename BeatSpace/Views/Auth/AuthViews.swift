import SwiftUI

// MARK: - Welcome

struct WelcomeView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.colorScheme) var scheme

    @State private var showLogin = false
    @State private var showRegister = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            VStack(spacing: 24) {
                Spacer()

                // Hero
                ZStack {
                    Circle()
                        .fill(settingsVM.theme.primary.opacity(0.25))
                        .frame(width: 220, height: 220)
                        .blur(radius: 30)
                        .scaleEffect(pulse ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulse)

                    Circle()
                        .fill(settingsVM.theme.gradient)
                        .frame(width: 140, height: 140)
                        .shadow(color: settingsVM.theme.primary.opacity(0.7), radius: 30)

                    Image(systemName: "waveform")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 10) {
                    Text("Beat Space")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundStyle(settingsVM.theme.gradient)

                    Text("Music that matches your mood")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(spacing: 12) {
                    NeonButton(title: "Log In", symbol: "arrow.right.circle.fill", theme: settingsVM.theme) {
                        Haptics.tap(settingsVM.hapticsOn)
                        showLogin = true
                    }
                    NeonButton(title: "Sign Up", theme: settingsVM.theme, filled: false) {
                        Haptics.tap(settingsVM.hapticsOn)
                        showRegister = true
                    }

                    HStack(spacing: 12) {
                        Button {
                            Haptics.tap(settingsVM.hapticsOn)
                            authVM.continueAsGuest()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.circle")
                                Text("Guest")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)

                        Text("•").foregroundColor(.secondary)

                        Button {
                            Haptics.tap(settingsVM.hapticsOn)
                            authVM.loginDemo()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "play.rectangle.fill")
                                Text("Try Demo Account")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(settingsVM.theme.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 36)
            }
        }
        .onAppear { pulse = true }
        .sheet(isPresented: $showLogin) { LoginView() }
        .sheet(isPresented: $showRegister) { RegisterView() }
    }
}

// MARK: - Login

struct LoginView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(spacing: 22) {
                    // Top bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.secondary)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.card(scheme)))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                    VStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(settingsVM.theme.gradient)
                        Text("Welcome back")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                        Text("Sign in to continue your vibe")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 12) {
                        NeonTextField(placeholder: "Email", text: $email, symbol: "envelope.fill", keyboard: .emailAddress, theme: settingsVM.theme)
                        NeonTextField(placeholder: "Password", text: $password, symbol: "lock.fill", secure: true, theme: settingsVM.theme)
                    }
                    .padding(.horizontal, 18)

                    if let err = authVM.errorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 18)
                    }

                    NeonButton(title: "Log In", symbol: "arrow.right", theme: settingsVM.theme) {
                        Haptics.tap(settingsVM.hapticsOn)
                        if authVM.login(email: email, password: password) {
                            Haptics.notify(settingsVM.hapticsOn)
                            dismiss()
                        }
                    }
                    .padding(.horizontal, 18)

                    // Divider
                    HStack {
                        Rectangle().fill(Color.stroke(scheme)).frame(height: 1)
                        Text("or continue with").font(.system(size: 12)).foregroundColor(.secondary)
                        Rectangle().fill(Color.stroke(scheme)).frame(height: 1)
                    }
                    .padding(.horizontal, 18)

                    // Social
                    HStack(spacing: 12) {
                        SocialButton(title: "Apple", symbol: "apple.logo") {
                            Haptics.tap(settingsVM.hapticsOn)
                            authVM.loginSocial(provider: "Apple")
                            dismiss()
                        }
                        SocialButton(title: "Google", symbol: "globe") {
                            Haptics.tap(settingsVM.hapticsOn)
                            authVM.loginSocial(provider: "Google")
                            dismiss()
                        }
                    }
                    .padding(.horizontal, 18)

                    // Demo
                    Button {
                        Haptics.tap(settingsVM.hapticsOn)
                        authVM.loginDemo()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.rectangle.fill")
                            Text("Try with Demo Account").fontWeight(.bold)
                        }
                        .font(.system(size: 15))
                        .foregroundColor(settingsVM.theme.primary)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 14).fill(settingsVM.theme.primary.opacity(0.12)))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(settingsVM.theme.primary.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}

struct SocialButton: View {
    let title: String
    let symbol: String
    let action: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                Text(title).fontWeight(.semibold)
            }
            .font(.system(size: 15))
            .foregroundColor(scheme == .dark ? .white : .black)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.card(scheme)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stroke(scheme), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Register

struct RegisterView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var acceptTerms = false

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.secondary)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.card(scheme)))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundStyle(settingsVM.theme.gradient)
                        Text("Create Account")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                        Text("Join the Beat Space universe")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 10)

                    VStack(spacing: 12) {
                        NeonTextField(placeholder: "Full name", text: $name, symbol: "person.fill", theme: settingsVM.theme)
                        NeonTextField(placeholder: "Email", text: $email, symbol: "envelope.fill", keyboard: .emailAddress, theme: settingsVM.theme)
                        NeonTextField(placeholder: "Password (min 6 chars)", text: $password, symbol: "lock.fill", secure: true, theme: settingsVM.theme)
                    }
                    .padding(.horizontal, 18)

                    // Terms
                    Button { acceptTerms.toggle() } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: acceptTerms ? "checkmark.square.fill" : "square")
                                .foregroundColor(acceptTerms ? settingsVM.theme.primary : .secondary)
                                .font(.system(size: 18))
                            Text("I agree to Terms of Service and Privacy Policy")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)

                    if let err = authVM.errorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 18)
                    }

                    NeonButton(title: "Sign Up", symbol: "person.crop.circle.badge.plus", theme: settingsVM.theme) {
                        guard acceptTerms else {
                            authVM.errorMessage = "Please accept the Terms to continue"
                            return
                        }
                        Haptics.tap(settingsVM.hapticsOn)
                        if authVM.signUp(name: name, email: email, password: password) {
                            Haptics.notify(settingsVM.hapticsOn)
                            dismiss()
                        }
                    }
                    .padding(.horizontal, 18)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}
