import SwiftUI

// MARK: - Shake geometry effect
private struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        let t = animatableData
        let translation = sin(t * .pi * 6) * 14 * max(0, 1 - t / 4)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

struct LoginView: View {
    @Environment(AppContainer.self) private var container
    @Bindable private var viewModel: AuthViewModel
    @State private var orbs = false
    @State private var shakeAttempts: CGFloat = 0
    @State private var errorGlow = false
    @State private var isPasswordVisible = false
    @State private var successScale: CGFloat = 1

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────
            AppColor.page.ignoresSafeArea()

            // Ambient orbs
            GeometryReader { geo in
                Circle()
                    .fill(AppColor.brand.opacity(0.28))
                    .blur(radius: 80)
                    .frame(width: 340, height: 340)
                    .offset(x: -60, y: orbs ? -20 : 20)
                    .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: orbs)

                Circle()
                    .fill(AppColor.accent.opacity(0.15))
                    .blur(radius: 70)
                    .frame(width: 280, height: 280)
                    .offset(x: geo.size.width - 180, y: geo.size.height * 0.3)
                    .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: orbs)

                Circle()
                    .fill(AppColor.brandDeep.opacity(0.20))
                    .blur(radius: 60)
                    .frame(width: 220, height: 220)
                    .offset(x: geo.size.width * 0.2, y: geo.size.height * 0.65 + (orbs ? 10 : -10))
                    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: orbs)
            }
            .ignoresSafeArea()

            // ── Content ─────────────────────────────────────────────
            VStack(spacing: 0) {
                Spacer()

                // Logo + Title
                VStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(viewModel.loginSucceeded
                                  ? LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                                  : AppColor.brandGradient)
                            .frame(width: 88, height: 88)
                            .shadow(
                                color: viewModel.loginSucceeded ? Color.green.opacity(0.7) : AppColor.brand.opacity(0.6),
                                radius: 24, x: 0, y: 8
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.loginSucceeded)
                            .scaleEffect(successScale)

                        if viewModel.loginSucceeded {
                            Image(systemName: "checkmark")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(AppColor.textPrimary)
                                .transition(.scale(scale: 0.3).combined(with: .opacity))
                        } else {
                            Image(systemName: "cube.box.fill")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundStyle(AppColor.textPrimary)
                                .transition(.scale(scale: 0.3).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: viewModel.loginSucceeded)

                    VStack(spacing: 6) {
                        Text("IT Inventory")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, AppColor.brand.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Accédez à votre espace stock sécurisé")
                            .font(.subheadline)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer().frame(height: 52)

                // Form card
                VStack(spacing: AppSpacing.md) {
                    // ── Password field ──────────────────────────────
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(errorGlow ? AppColor.danger : AppColor.brand)
                            .frame(width: 20)
                            .animation(.easeInOut(duration: 0.2), value: errorGlow)

                        Group {
                            if isPasswordVisible {
                                TextField("Mot de passe", text: $viewModel.password)
                            } else {
                                SecureField("Mot de passe", text: $viewModel.password)
                            }
                        }
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(AppColor.textPrimary)
                        .onChange(of: viewModel.password) { _, _ in
                            if errorGlow {
                                withAnimation(.easeOut(duration: 0.3)) { errorGlow = false }
                                viewModel.errorMessage = nil
                            }
                        }

                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                isPasswordVisible.toggle()
                            }
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(AppColor.textSecondary)
                                .frame(width: 20)
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, 18)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(
                                errorGlow ? AppColor.danger : Color.white.opacity(0.10),
                                lineWidth: errorGlow ? 2 : 1
                            )
                            .animation(.easeInOut(duration: 0.2), value: errorGlow)
                    )
                    .shadow(
                        color: errorGlow ? AppColor.danger.opacity(0.45) : .clear,
                        radius: 10, x: 0, y: 0
                    )
                    .modifier(ShakeEffect(animatableData: shakeAttempts))

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                            Text(errorMessage)
                                .font(.footnote)
                        }
                        .foregroundStyle(AppColor.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // ── Sign-in button ───────────────────────────────
                    Button {
                        viewModel.signInButtonTapped()
                    } label: {
                        ZStack {
                            if viewModel.loginSucceeded {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3.weight(.bold))
                                    Text("Connecté !")
                                        .font(.headline.weight(.bold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .transition(.scale(scale: 0.8).combined(with: .opacity))
                            } else if viewModel.isSubmitting {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                            } else {
                                HStack(spacing: 8) {
                                    Text("Se connecter")
                                        .font(.headline.weight(.bold))
                                    Image(systemName: "arrow.right")
                                        .font(.headline.weight(.bold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                            }
                        }
                        .foregroundStyle(AppColor.textPrimary)
                        .background(
                            Group {
                                if viewModel.loginSucceeded {
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else if viewModel.password.isEmpty || viewModel.isSubmitting {
                                    AppColor.surface.opacity(0.6)
                                } else {
                                    LinearGradient(
                                        colors: [AppColor.brand, AppColor.brandDeep],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(
                            color: viewModel.loginSucceeded
                                ? Color.green.opacity(0.55)
                                : (viewModel.password.isEmpty ? .clear : AppColor.brand.opacity(0.45)),
                            radius: 16, x: 0, y: 6
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.loginSucceeded)
                    }
                    .disabled(viewModel.password.isEmpty || viewModel.isSubmitting || viewModel.loginSucceeded)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.password.isEmpty)

                    // ── Face ID button ───────────────────────────────
                    if viewModel.isBiometricEnabled {
                        Button {
                            viewModel.signInWithBiometrics()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "faceid")
                                    .font(.title3.weight(.semibold))
                                Text("Se connecter avec Face ID")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(AppColor.brand)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppColor.brand.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .stroke(AppColor.brand.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(viewModel.isSubmitting || viewModel.loginSucceeded)
                    }
                }
                .padding(AppSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppColor.card.opacity(0.7))
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(.ultraThinMaterial.opacity(0.3))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.14), Color.white.opacity(0.03)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ), lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 12)
                .padding(.horizontal, AppSpacing.md)

                Spacer()

                Text(container.environment.appEnv == "DEBUG" ? "Mode debug" : "v1.0")
                    .font(.caption2)
                    .foregroundStyle(AppColor.textTertiary)
                    .padding(.bottom, AppSpacing.lg)
            }
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            if newValue != nil {
                withAnimation(.easeInOut(duration: 0.15)) { errorGlow = true }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.15)) {
                    shakeAttempts += 1
                }
            }
        }
        .onChange(of: viewModel.loginSucceeded) { _, succeeded in
            if succeeded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    successScale = 1.15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        successScale = 1.0
                    }
                }
            }
        }
        .onAppear {
            orbs = true
            if viewModel.isBiometricEnabled {
                // Petit délai pour laisser la vue s'afficher avant le popup Face ID
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.signInWithBiometrics()
                }
            }
        }
    }
}

