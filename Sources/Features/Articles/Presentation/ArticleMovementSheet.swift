import SwiftUI

// MARK: - ArticleMovementSheet

struct ArticleMovementSheet: View {
    let article: Article
    let type: MovementType
    let availableSites: [Site]
    let currentSiteId: String?
    let onConfirm: (Int, String?, String?) -> Void

    @State private var quantity = 1
    @State private var reason = ""
    @State private var targetSiteId: String?
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var btnScale: CGFloat = 1.0
    @FocusState private var reasonFocused: Bool
    @Environment(AppContainer.self) private var container

    // MARK: Computed helpers

    private var typeColor: Color {
        switch type {
        case .entry:      return AppColor.success
        case .exit:       return AppColor.danger
        case .adjustment: return AppColor.warning
        case .transfer:   return AppColor.accent
        case .unknown:    return AppColor.brand
        }
    }

    private var typeIcon: String {
        switch type {
        case .entry:      return "arrow.down.circle.fill"
        case .exit:       return "arrow.up.circle.fill"
        case .adjustment: return "slider.horizontal.3"
        case .transfer:   return "arrow.triangle.swap"
        case .unknown:    return "questionmark"
        }
    }

    private var currentSiteName: String? {
        container.availableSites.first(where: { $0.id == currentSiteId })?.name
    }

    private var transferSites: [Site] {
        container.availableSites.filter { $0.id != currentSiteId && $0.isActive }
    }

    private var canConfirm: Bool {
        type != .transfer || targetSiteId != nil
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.page.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        articleHeaderCard
                        if type == .transfer { transferCard }
                        quantityCard
                        reasonCard
                        confirmButton
                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(type.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") { reasonFocused = false }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Article header

    private var articleHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: typeIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(typeColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(article.name)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(article.reference)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            Text(type.label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(typeColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(typeColor.opacity(0.12)))
        }
        .padding(16)
        .amsCard()
    }

    // MARK: - Transfer destination

    private var transferCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Site de destination", systemImage: "location.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)

            if transferSites.isEmpty {
                Text("Aucun autre site disponible")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(transferSites) { site in
                            let selected = targetSiteId == site.id
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    targetSiteId = selected ? nil : site.id
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: selected ? "checkmark.circle.fill" : "building.2")
                                        .font(.caption.weight(.semibold))
                                    Text(site.name)
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(selected ? .white : AppColor.accent)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule().fill(selected ? AppColor.accent : AppColor.accent.opacity(0.12))
                                )
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 2)
                }
            }

            if let name = currentSiteName {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppColor.textTertiary)
                    Text("Depuis : \(name)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppColor.textTertiary)
                }
            }
        }
        .padding(16)
        .amsCard()
    }

    // MARK: - Quantity

    private var quantityCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    guard quantity > 1 else { return }
                    quantity -= 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "minus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(quantity > 1 ? AppColor.textPrimary : AppColor.textTertiary)
                        .frame(width: 64, height: 84)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                VStack(spacing: 2) {
                    Text("\(quantity)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(typeColor)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: quantity)
                    Text("unités")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppColor.textTertiary)
                }
                .frame(maxWidth: .infinity)

                Button {
                    quantity += 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(typeColor)
                        .frame(width: 64, height: 84)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Rectangle()
                .fill(AppColor.separator.opacity(0.5))
                .frame(height: 0.5)
                .padding(.horizontal, 16)

            HStack(spacing: 8) {
                ForEach([5, 10, 25, 50], id: \.self) { amt in
                    Button {
                        quantity += amt
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text("+\(amt)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(typeColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(typeColor.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .amsCard()
    }

    // MARK: - Reason

    private var reasonCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Motif (optionnel)", systemImage: "text.bubble")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)

            TextField("Ex : retour fournisseur, inventaire…", text: $reason, axis: .vertical)
                .lineLimit(2...5)
                .font(.body)
                .foregroundStyle(AppColor.textPrimary)
                .focused($reasonFocused)
                .submitLabel(.done)
                .onSubmit { reasonFocused = false }
        }
        .padding(16)
        .amsCard()
    }

    // MARK: - Confirm button

    private var confirmButton: some View {
        Button {
            guard canConfirm, !isSubmitting else { return }
            confirm()
        } label: {
            ZStack {
                HStack(spacing: 8) {
                    Image(systemName: typeIcon).font(.headline.weight(.semibold))
                    Text("Confirmer · \(quantity) unité\(quantity > 1 ? "s" : "")")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .opacity(showSuccess || isSubmitting ? 0 : 1)

                if isSubmitting && !showSuccess {
                    ProgressView().tint(.white)
                }

                if showSuccess {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3.weight(.semibold))
                        Text("Enregistré")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        !canConfirm
                            ? AppColor.textTertiary.opacity(0.3)
                            : (showSuccess ? AppColor.success : typeColor)
                    )
            )
            .scaleEffect(btnScale)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: showSuccess)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: canConfirm)
        }
        .buttonStyle(.plain)
        .disabled(!canConfirm || isSubmitting)
        .padding(.top, 4)
    }

    // MARK: - Logic

    private func confirm() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { btnScale = 0.95 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) { btnScale = 1.0 }
        }
        isSubmitting = true
        let note = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { showSuccess = true }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                onConfirm(quantity, note.isEmpty ? nil : note, targetSiteId)
            }
        }
    }
}

// MARK: - Card modifier helper

private extension View {
    func amsCard() -> some View {
        self
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
    }
}
