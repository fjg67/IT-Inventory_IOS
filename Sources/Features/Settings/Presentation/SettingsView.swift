import SwiftUI

struct SettingsView: View {
    @Environment(AppContainer.self) private var container
    @State private var notificationsEnabled = false

    var body: some View {
        ZStack {
            AppColor.pageGradient.ignoresSafeArea()
            ambientGlow

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerCard

                    settingsSection(title: "Apparence", icon: "paintpalette.fill", iconColor: AppColor.accent) {
                        themePicker
                    }

                    settingsSection(title: "Sécurité", icon: "lock.shield.fill", iconColor: AppColor.brand) {
                        settingsToggle(
                            "Face ID / Touch ID",
                            icon: "faceid",
                            subtitle: "Verrouiller l'app au retour en premier plan",
                            value: Binding(
                                get: { container.authViewModel.isBiometricEnabled },
                                set: { container.authViewModel.setBiometricEnabled($0) }
                            )
                        )
                    }

                    settingsSection(title: "Notifications", icon: "bell.badge.fill", iconColor: AppColor.warning) {
                        settingsToggle(
                            "Alertes push",
                            icon: "bell.fill",
                            subtitle: "Recevoir les alertes stock et mouvements",
                            value: $notificationsEnabled
                        )
                    }

                    settingsSection(title: "Support", icon: "questionmark.circle.fill", iconColor: AppColor.success) {
                        NavigationLink {
                            LegalNoticeView()
                        } label: {
                            settingsLinkRow(label: "Mentions légales", icon: "doc.text.fill")
                        }

                        Divider().background(AppColor.separator).padding(.leading, 54)

                        NavigationLink {
                            SupportContactView()
                        } label: {
                            settingsLinkRow(label: "Contacter le support", icon: "envelope.fill")
                        }
                    }

                    signOutButton
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 140)
            }
        }
        .navigationTitle("Réglages")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Decor

    private var ambientGlow: some View {
        ZStack {
            Circle()
                .fill(AppColor.brand.opacity(0.20))
                .frame(width: 240, height: 240)
                .blur(radius: 90)
                .offset(x: 140, y: -260)

            Circle()
                .fill(AppColor.accent.opacity(0.14))
                .frame(width: 170, height: 170)
                .blur(radius: 70)
                .offset(x: -160, y: 20)
        }
        .allowsHitTesting(false)
    }

    private var headerCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColor.brandGradient)
                    .frame(width: 76, height: 76)
                    .shadow(color: AppColor.brand.opacity(0.45), radius: 16, x: 0, y: 8)
                Image(systemName: "cube.box.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
            }

            Text("IT Inventory")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)

            Text("Préférences de l'application")
                .font(.footnote)
                .foregroundStyle(AppColor.textSecondary)

            HStack(spacing: 8) {
                statusPill(icon: "building.2.fill", text: container.selectedSite?.name ?? "Tous les sites")
                statusPill(icon: "person.crop.circle.fill", text: container.selectedTechnician?.name ?? "Technicien")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppColor.card.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppColor.separator, lineWidth: 1)
        )
    }

    private func statusPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(AppColor.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppColor.surface)
        .clipShape(Capsule())
    }

    // MARK: - Theme picker

    private var themePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColor.brand)
                Text("Style de thème")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, 12)

            HStack(spacing: 8) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button {
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                            container.appTheme = theme
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: theme.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(theme.label)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(container.appTheme == theme ? AppColor.textPrimary : AppColor.textSecondary)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(container.appTheme == theme ? AppColor.brand.opacity(0.24) : AppColor.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    container.appTheme == theme ? AppColor.brand.opacity(0.5) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 12, weight: .semibold))
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .tracking(0.8)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                content()
            }
            .background(AppColor.card.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColor.separator, lineWidth: 1)
            )
        }
    }

    private func settingsToggle(_ label: String, icon: String, subtitle: String, value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: 3) {
                settingsRow(label: label, icon: icon)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColor.textTertiary)
                    .padding(.leading, 44)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: AppColor.brand))
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 12)
    }

    private func settingsLinkRow(label: String, icon: String) -> some View {
        HStack(spacing: 12) {
            settingsRow(label: label, icon: icon)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.textTertiary)
                .padding(.trailing, AppSpacing.md)
        }
        .padding(.vertical, 12)
    }

    private func settingsRow(label: String, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColor.surface)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColor.textSecondary)
            }
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
        }
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            container.authViewModel.signOutButtonTapped()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppColor.danger.opacity(0.16))
                        .frame(width: 34, height: 34)
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColor.danger)
                }

                Text("Se déconnecter")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.danger)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColor.danger.opacity(0.7))
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 14)
            .background(AppColor.card.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColor.danger.opacity(0.25), lineWidth: 1)
            )
            }
        .buttonStyle(.plain)
            }
}
