import SwiftUI

struct LegalNoticeView: View {
    private let supportEmail = "support@company.test"

    var body: some View {
        ZStack {
            AppColor.pageGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    topSummaryCard

                    legalSection(title: "Editeur", icon: "building.2.fill", tint: AppColor.brand) {
                        legalLine("Application", value: "IT Inventory")
                        legalLine("Responsable", value: "Equipe IT Inventory")
                        legalLine("Contact", value: supportEmail)
                    }

                    legalSection(title: "Objet du service", icon: "doc.text.fill", tint: AppColor.accent) {
                        legalParagraph(
                            "IT Inventory permet la gestion d'inventaire interne: consultation des articles, "
                            + "mouvements de stock, scan de codes-barres et suivi des operations."
                        )
                    }

                    legalSection(title: "Donnees personnelles", icon: "lock.shield.fill", tint: AppColor.success) {
                        legalParagraph(
                            "Les donnees traitees sont limitees a l'exploitation du service: identifiants "
                            + "techniques, historiques de mouvements et donnees de session securisees."
                        )
                        legalParagraph(
                            "Les traitements sont realises pour assurer l'authentification, la securite, "
                            + "la tracabilite et le bon fonctionnement de l'application."
                        )
                    }

                    legalSection(title: "Hebergement et sous-traitants", icon: "server.rack", tint: AppColor.warning) {
                        legalParagraph(
                            "Les services backend sont fournis via Supabase. Les donnees peuvent etre "
                            + "hebergees sur une infrastructure tierce conformement aux parametrages "
                            + "d'environnement de l'application."
                        )
                    }

                    legalSection(title: "Propriete intellectuelle", icon: "c.circle.fill", tint: AppColor.brand) {
                        legalParagraph(
                            "L'application, ses interfaces, ses contenus et ses composants sont proteges "
                            + "par les droits de propriete intellectuelle. Toute reproduction non "
                            + "autorisee est interdite."
                        )
                    }

                    legalSection(
                        title: "Responsabilite",
                        icon: "exclamationmark.triangle.fill",
                        tint: AppColor.danger
                    ) {
                        legalParagraph(
                            "Le service est fourni avec une obligation de moyens. L'editeur ne peut etre "
                            + "tenu responsable des interruptions, indisponibilites temporaires, ou pertes "
                            + "indirectes liees a l'usage de l'application."
                        )
                    }

                    legalSection(title: "Mise a jour", icon: "clock.fill", tint: AppColor.textSecondary) {
                        legalLine("Version", value: appVersionLabel)
                        legalLine("Derniere revision", value: formattedRevisionDate)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Mentions legales")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var topSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.brand)
                Text("Informations legales")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
            }

            Text(
                "Cette page presente les informations juridiques et les conditions "
                + "d'utilisation de l'application IT Inventory."
            )
                .font(.footnote)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(16)
        .background(AppColor.card.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColor.separator, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func legalSection<Content: View>(
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

            VStack(alignment: .leading, spacing: 10) {
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

    private func legalLine(_ label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
        }
    }

    private func legalParagraph(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(AppColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var appVersionLabel: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        return "\(short) (build \(build))"
    }

    private var formattedRevisionDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
}
