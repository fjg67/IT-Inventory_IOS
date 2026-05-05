import SwiftUI

struct ArticlesView: View {
    private enum AddSheet: String, Identifiable {
        case actions
        case articleForm

        var id: String { rawValue }
    }

    @Bindable private var viewModel: ArticlesViewModel
    private let makeAddArticleViewModel: () -> AddArticleViewModel
    private let makeDetailViewModel: (Article) -> ArticleStockViewModel
    private let selectedSiteId: String?
    private let onOpenCreatePC: () -> Void
    private let onOpenScan: () -> Void
    @State private var animateIn = false
    @State private var activeAddSheet: AddSheet?

    init(
        viewModel: ArticlesViewModel,
        selectedSiteId: String?,
        makeAddArticleViewModel: @escaping () -> AddArticleViewModel,
        onOpenCreatePC: @escaping () -> Void,
        onOpenScan: @escaping () -> Void,
        makeDetailViewModel: @escaping (Article) -> ArticleStockViewModel
    ) {
        self.viewModel = viewModel
        self.selectedSiteId = selectedSiteId
        self.makeAddArticleViewModel = makeAddArticleViewModel
        self.onOpenCreatePC = onOpenCreatePC
        self.onOpenScan = onOpenScan
        self.makeDetailViewModel = makeDetailViewModel
    }

    var body: some View {
        ZStack {
            AppColor.pageGradient.ignoresSafeArea()
            ambientBackdrop

            VStack(spacing: 0) {
                topHeader
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)

                searchPanel
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)

                if let errorMessage = viewModel.errorMessage {
                    errorBanner(text: errorMessage)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xs)
                }

                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.isLoading {
                            ForEach(0..<7, id: \.self) { _ in shimmerRow }
                        } else if viewModel.visibleArticles.isEmpty {
                            emptyState
                        } else {
                            articlesList
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl + 12)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                EmptyView()
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.loadOnAppear(siteId: selectedSiteId)
            withAnimation(.easeOut(duration: 0.35).delay(0.05)) {
                animateIn = true
            }
        }
        .onChange(of: selectedSiteId) {
            Task { await viewModel.reload(siteId: selectedSiteId) }
        }
        .onChange(of: viewModel.query) { viewModel.queryDidChange() }
        .onChange(of: viewModel.sortMode) { viewModel.sortModeDidChange() }
        .overlay(alignment: .bottomTrailing) {
            fabButton
        }
        .sheet(item: $activeAddSheet) { addSheet in
            switch addSheet {
            case .actions:
                AddArticleActionSheet(
                    onCreateArticle: {
                        activeAddSheet = .articleForm
                    },
                    onCreatePC: {
                        activeAddSheet = nil
                        onOpenCreatePC()
                    },
                    onScanBarcode: {
                        activeAddSheet = nil
                        onOpenScan()
                    }
                )
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground(.clear)
                .presentationBackgroundInteraction(.enabled)

            case .articleForm:
                AddArticleView(
                    viewModel: makeAddArticleViewModel(),
                    onCreated: {
                        Task {
                            await viewModel.reload(siteId: selectedSiteId)
                        }
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var ambientBackdrop: some View {
        ZStack {
            Circle()
                .fill(AppColor.brand.opacity(0.22))
                .frame(width: 260)
                .blur(radius: 90)
                .offset(x: -120, y: -260)

            Ellipse()
                .fill(AppColor.accent.opacity(0.12))
                .frame(width: 320, height: 220)
                .blur(radius: 100)
                .offset(x: 120, y: -110)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var topHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Catalogue")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColor.textSecondary)
                Text("Articles")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(AppColor.textPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Total")
                    .font(.caption2)
                    .foregroundStyle(AppColor.textTertiary)
                Text("\(viewModel.visibleArticles.count)")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColor.accent)
                    .monospacedDigit()
            }
        }
    }

    private var searchPanel: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColor.textSecondary)
                    .font(.system(size: 16, weight: .medium))
                TextField("Recherche intelligente (nom, ref, categorie)", text: $viewModel.query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(AppColor.textPrimary)

                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(AppColor.surface.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )

            HStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryFilterButton(label: "Toutes", isSelected: viewModel.selectedCategory == nil) {
                            viewModel.selectedCategory = nil
                        }
                        ForEach(viewModel.uniqueCategories, id: \.self) { category in
                            categoryFilterButton(label: category, isSelected: viewModel.selectedCategory == category) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                }

                HStack(spacing: 5) {
                    Circle()
                        .fill(AppColor.accent)
                        .frame(width: 6, height: 6)
                    Text("\(viewModel.visibleArticles.count)")
                        .font(.caption)
                        .foregroundStyle(AppColor.textTertiary)
                        .monospacedDigit()
                }
                .padding(.leading, 8)
            }

            HStack(spacing: 8) {
                ForEach(ArticlesSortMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            viewModel.sortMode = mode
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: icon(for: mode))
                                .font(.system(size: 10, weight: .bold))
                            Text(mode.rawValue)
                                .font(.caption2.weight(.bold))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .foregroundStyle(viewModel.sortMode == mode ? Color.white : AppColor.textSecondary)
                        .background(
                            Group {
                                if viewModel.sortMode == mode {
                                    AppColor.accentGradient
                                } else {
                                    LinearGradient(colors: [AppColor.surface, AppColor.surface], startPoint: .leading, endPoint: .trailing)
                                }
                            }
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(viewModel.sortMode == mode ? 0.18 : 0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(AppColor.card.opacity(0.55))
                .overlay(.ultraThinMaterial.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.05), AppColor.accent.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: AppColor.brand.opacity(0.14), radius: 26, x: 0, y: 8)
    }

    private func errorBanner(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColor.warning)
            Text(text)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(AppColor.warning.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .stroke(AppColor.warning.opacity(0.35), lineWidth: 1)
        )
    }

    private func categoryFilterButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                action()
            }
        }) {
            Text(label)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(
                    isSelected ? 
                    AnyView(AppColor.brandGradient) :
                    AnyView(LinearGradient(colors: [AppColor.surface, AppColor.surface], startPoint: .leading, endPoint: .trailing))
                )
                .foregroundStyle(isSelected ? Color.white : AppColor.textSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(isSelected ? 0.18 : 0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func icon(for mode: ArticlesSortMode) -> String {
        switch mode {
        case .newest:
            return "clock.arrow.circlepath"
        case .alphabetical:
            return "textformat"
        case .reference:
            return "number"
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(AppColor.brand.opacity(0.2))
                    .frame(width: 78, height: 78)
                Image(systemName: "shippingbox")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
            }
            Text("Aucun article trouve")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppColor.textPrimary)
            Text("Essaie un autre filtre ou un mot-cle")
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 84)
    }

    @ViewBuilder
    private var articlesList: some View {
        ForEach(Array(viewModel.visibleArticles.enumerated()), id: \.element.id) { index, article in
            articleRow(for: article, atIndex: index)
        }
    }

    private func articleRow(for article: Article, atIndex index: Int) -> some View {
        NavigationLink {
            ArticleDetailView(
                article: article,
                viewModel: makeDetailViewModel(article)
            )
        } label: {
            ArticleCardRow(
                article: article,
                imageURL: viewModel.displayImageURL(for: article),
                stockQuantity: viewModel.stockQuantity(for: article),
                stockLevel: viewModel.stockLevel(for: article)
            )
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 14)
            .animation(
                .spring(response: 0.45, dampingFraction: 0.82)
                    .delay(Double(index) * 0.015),
                value: animateIn
            )
        }
        .buttonStyle(.plain)
    }

    private var shimmerRow: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColor.surface)
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(AppColor.surface)
                    .frame(height: 15)
                RoundedRectangle(cornerRadius: 5)
                    .fill(AppColor.surface)
                    .frame(width: 136, height: 11)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(AppColor.card.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var fabButton: some View {
        Button {
            activeAddSheet = .actions
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: 58, height: 58)
                .background(
                    Circle()
                        .fill(AppColor.brandGradient)
                        .overlay(.ultraThinMaterial.opacity(0.15))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        )
                )
                .shadow(color: AppColor.brand.opacity(0.45), radius: 16, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.trailing, AppSpacing.lg)
        .padding(.bottom, 88)
    }
}


private struct AddArticleActionSheet: View {
    let onCreateArticle: () -> Void
    let onCreatePC: () -> Void
    let onScanBarcode: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.white.opacity(0.22))
                .frame(width: 42, height: 5)
                .padding(.top, 8)

            Text("Ajouter un article")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)

            actionButton(title: "Ajouter un article (catalogue)", icon: "shippingbox.fill", tint: AppColor.success, action: onCreateArticle)
            actionButton(title: "Ajouter un article (PC)", icon: "plus.app.fill", tint: AppColor.brand, action: onCreatePC)
            actionButton(title: "Scanner code-barres", icon: "barcode.viewfinder", tint: AppColor.accent, action: onScanBarcode)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColor.card.opacity(0.94))
                .overlay(.ultraThinMaterial.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
        .padding(.horizontal, AppSpacing.sm)
        .padding(.bottom, AppSpacing.sm)
    }

    private func actionButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                Text(title)
                    .font(.headline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(AppColor.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(0.22))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tint.opacity(0.55), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ArticleCardRow: View {
    let article: Article
    let imageURL: URL?
    let stockQuantity: Int
    let stockLevel: ArticleStockLevel

    var body: some View {
        HStack(spacing: 13) {
            ArticleThumbnailView(url: imageURL, size: 60)

            VStack(alignment: .leading, spacing: 5) {
                Text(article.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)

                // Marque + Modèle
                if let brand = article.brand {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(AppColor.brand.opacity(0.7))
                        Text(([brand, article.model].compactMap { $0 }).joined(separator: " · "))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppColor.textSecondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 6) {
                    // Code d'identification (référence)
                    HStack(spacing: 4) {
                        Image(systemName: "barcode")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(AppColor.accent.opacity(0.8))
                        Text(article.reference)
                            .font(.caption2.monospaced().weight(.semibold))
                            .foregroundStyle(AppColor.accent)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(AppColor.accent.opacity(0.10))
                    .clipShape(Capsule())
                    // Catégorie
                    if let cat = article.category {
                        tag(text: cat, tint: AppColor.textSecondary)
                    }
                }

                if article.isArchived {
                    tag(text: "Archive", tint: AppColor.warning)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                stockPill

                ZStack {
                    Circle()
                        .fill(AppColor.surface.opacity(0.85))
                        .frame(width: 28, height: 28)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.card.opacity(0.95), AppColor.surface.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.16), AppColor.brand.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: AppColor.brand.opacity(0.10), radius: 16, x: 0, y: 8)
        .shadow(color: .black.opacity(0.22), radius: 10, x: 0, y: 4)
    }

    private func tag(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(tint.opacity(0.14))
            .foregroundStyle(tint)
            .clipShape(Capsule())
    }

    private var stockPill: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(stockTint)
                .frame(width: 7, height: 7)

            Text("Stock")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)

            Text("\(stockQuantity)")
                .font(.subheadline.monospacedDigit().weight(.bold))
                .foregroundStyle(stockTint)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(AppColor.surface.opacity(0.82))
                .overlay(.ultraThinMaterial.opacity(0.25))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(stockTint.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: stockTint.opacity(0.18), radius: 10, x: 0, y: 5)
    }

    private var stockTint: Color {
        switch stockLevel {
        case .good:
            return AppColor.success
        case .warning:
            return AppColor.warning
        case .critical:
            return AppColor.danger
        }
    }
}

private struct ArticleThumbnailView: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppColor.brand.opacity(0.25), AppColor.surface.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "cube.box.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppColor.brand.opacity(0.6))
                }
                .frame(width: size, height: size)

            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )

            case .failure:
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppColor.brand.opacity(0.25), AppColor.surface.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "cube.box.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppColor.brand.opacity(0.6))
                }
                .frame(width: size, height: size)

            @unknown default:
                EmptyView()
            }
        }
    }
}

