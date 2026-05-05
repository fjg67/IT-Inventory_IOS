import SwiftUI
import UIKit

struct SupportContactView: View {
    @Environment(\.openURL) private var openURL

    private let supportEmail = "support@company.test"

    var body: some View {
        ZStack {
            AppColor.pageGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    contactHero
                    actionButtons
                    requiredInfos
                    diagnosticsCard
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Contacter le support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var contactHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColor.brand.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: "headphones")
                        .foregroundStyle(AppColor.brand)
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Support IT Inventory")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Reponse habituelle sous 24h ouvrees")
                        .font(.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer()
            }

            Text(
                "Pour un traitement rapide, decrivez le contexte, les etapes pour "
                + "reproduire et joignez une capture d'ecran si possible."
            )
                .font(.footnote)
                .foregroundStyle(AppColor.textSecondary)

            HStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColor.brand)
                Text(supportEmail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .background(AppColor.card.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColor.separator, lineWidth: 1)
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                sendSupportEmail()
            } label: {
                primaryActionRow(
                    title: "Envoyer un email",
                    subtitle: "Ouvre votre app Mail avec les informations pre-remplies",
                    icon: "paperplane.fill",
                    tint: AppColor.brand
                )
            }
            .buttonStyle(.plain)

            Button {
                UIPasteboard.general.string = supportEmail
            } label: {
                secondaryActionRow(
                    title: "Copier l'adresse support",
                    subtitle: supportEmail,
                    icon: "doc.on.doc.fill"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var requiredInfos: some View {
        supportSection(title: "Informations a fournir", icon: "checklist", tint: AppColor.success) {
            infoLine("- Module concerne (Accueil, Articles, Scan, PC, Mouvements, Reglages)")
            infoLine("- Action realisee juste avant le probleme")
            infoLine("- Message d'erreur affiche (si present)")
            infoLine("- Resultat attendu vs resultat obtenu")
            infoLine("- Capture(s) d'ecran et heure approximative")
        }
    }

    private var diagnosticsCard: some View {
        supportSection(title: "Diagnostic utile", icon: "wrench.and.screwdriver.fill", tint: AppColor.warning) {
            diagnosticRow(label: "Version app", value: appVersionLabel)
            diagnosticRow(label: "iOS", value: UIDevice.current.systemVersion)
            diagnosticRow(label: "Appareil", value: UIDevice.current.model)
            diagnosticRow(label: "Environnement", value: environmentLabel)

            Button {
                UIPasteboard.general.string = diagnosticPayload
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.on.square")
                    Text("Copier le bloc diagnostic")
                    Spacer()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.brand)
                .padding(.top, 6)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func supportSection<Content: View>(
        title: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.caption.weight(.semibold))
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .tracking(0.7)
            }
            .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(14)
            .background(AppColor.card.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColor.separator, lineWidth: 1)
            )
        }
    }

    private func primaryActionRow(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.textTertiary)
        }
        .padding(12)
        .background(AppColor.card.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separator, lineWidth: 1)
        )
    }

    private func secondaryActionRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppColor.surface)
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background(AppColor.card.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separator, lineWidth: 1)
        )
    }

    private func infoLine(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(AppColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func diagnosticRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
        }
    }

    private var appVersionLabel: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        return "\(short) (build \(build))"
    }

    private var environmentLabel: String {
        Bundle.main.object(forInfoDictionaryKey: "APP_ENV") as? String ?? "-"
    }

    private var diagnosticPayload: String {
        """
        IT Inventory diagnostic
        - Version: \(appVersionLabel)
        - iOS: \(UIDevice.current.systemVersion)
        - Appareil: \(UIDevice.current.model)
        - Environnement: \(environmentLabel)
        """
    }
}

private extension SupportContactView {
    func sendSupportEmail() {
        let subject = "Support IT Inventory"
        let body =
            "Bonjour,%0D%0A%0D%0AModule concerne:%0D%0AEtapes de reproduction:%0D%0A" +
            "Resultat attendu:%0D%0AResultat obtenu:%0D%0A%0D%0AMerci."

        guard let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "mailto:\(supportEmail)?subject=\(encodedSubject)&body=\(body)") else {
            return
        }

        openURL(url)
    }
}
