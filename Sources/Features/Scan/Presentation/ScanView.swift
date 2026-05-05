import AVFoundation
import SwiftUI

struct ScanView: View {
    @Bindable var viewModel: ScanViewModel
    @Environment(AppContainer.self) private var container
    let makeDetailViewModel: (Article) -> ArticleStockViewModel

    @State private var cameraPermission: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var navigateToArticle: Article?
    @State private var cornerPulse = false
    @State private var scannedArticle: Article?
    @State private var scannedCurrentStock: Int?
    @State private var scannedExistsOnSelectedSite = true

    private var isArticleNotFound: Bool {
        if case .articleNotFound = viewModel.state { return true }
        return false
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            cameraLayer
            overlayLayer
            if case .articleNotFound(let barcode) = viewModel.state {
                articleNotFoundOverlay(barcode: barcode)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: isArticleNotFound)
        .navigationTitle("Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            checkPermission()
            viewModel.loadSitesOnAppear()
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                cornerPulse = true
            }
        }
        .navigationDestination(item: $navigateToArticle) { article in
            ArticleDetailView(article: article, viewModel: makeDetailViewModel(article))
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .found(let article) = newState {
                scannedArticle = article
                Task {
                    let stockLookup = await viewModel.currentStock(
                        for: article.id,
                        siteId: container.selectedSite?.id
                    )
                    scannedCurrentStock = stockLookup.quantity
                    scannedExistsOnSelectedSite = stockLookup.existsOnSelectedSite
                }
            }
            if case .articleNotFound = newState {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
        .sheet(item: $scannedArticle) { article in
            ScanResultSheet(
                article: article,
                currentStock: scannedCurrentStock,
                existsOnSelectedSite: scannedExistsOnSelectedSite,
                selectedSiteName: container.selectedSite?.name,
                transferSites: viewModel.transferTargets(excluding: container.selectedSite?.id),
                isProcessing: viewModel.state == .searching,
                isReadOnly: container.isReadOnly,
                onConsult: {
                    scannedArticle = nil
                    scannedCurrentStock = nil
                    scannedExistsOnSelectedSite = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        navigateToArticle = article
                        viewModel.reset()
                    }
                },
                onConfirm: { type, quantity, reason, targetSite in
                    Task {
                        await viewModel.createMovement(
                            article: article,
                            type: type,
                            quantity: quantity,
                            reason: reason,
                            selectedSiteId: container.selectedSite?.id,
                            technicianId: container.selectedTechnician?.id,
                            technicianName: container.selectedTechnician?.name,
                            targetSiteId: targetSite?.id
                        )
                        scannedArticle = nil
                        scannedCurrentStock = nil
                        scannedExistsOnSelectedSite = true
                    }
                },
                onPCStatusChange: { status, completion in
                    Task {
                        let (success, errorMsg) = await viewModel.updatePCStatus(
                            article: article,
                            status: status,
                            technicianName: container.selectedTechnician?.name
                        )
                        completion(success, errorMsg)
                        // La fermeture est gérée par onNewScan après l'animation (1.6s)
                    }
                },
                onNewScan: {
                    scannedArticle = nil
                    scannedCurrentStock = nil
                    scannedExistsOnSelectedSite = true
                    viewModel.reset()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
    }

    // MARK: – Camera
    @ViewBuilder
    private var cameraLayer: some View {
        switch cameraPermission {
        case .authorized:
            BarcodeScannerView { code in viewModel.onBarcode(code) }
                .ignoresSafeArea()
        case .denied, .restricted:
            permissionDeniedView
        default:
            AppColor.page.ignoresSafeArea()
        }
    }

    // MARK: – Overlay
    private var overlayLayer: some View {
        VStack(spacing: 0) {
            // Top gradient scrim
            LinearGradient(
                colors: [AppColor.page.opacity(0.7), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 140)
            .ignoresSafeArea(edges: .top)

            Spacer()

            // Viewfinder
            ZStack {
                // Dim surround
                Color.black.opacity(0.45)
                    .reverseMask {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .frame(width: 280, height: 182)
                    }

                // iOS-like viewfinder shell
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.08))
                    .frame(width: 280, height: 182)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )

                ViewfinderCorners(size: CGSize(width: 280, height: 182), active: cornerPulse)

                // Scan line
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, AppColor.accent.opacity(0.95), .clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: 244, height: 3)
                    .shadow(color: AppColor.accent.opacity(0.75), radius: 10)
                    .offset(y: cornerPulse ? 64 : -64)
                    .animation(.easeInOut(duration: 1.75).repeatForever(autoreverses: true), value: cornerPulse)
                    .frame(width: 280, height: 182, alignment: .center)
                    .clipped()

                Text("Pointez vers un code-barres")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppColor.textSecondary)
                    .offset(y: 118)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            // Bottom panel
            VStack(spacing: AppSpacing.md) {
                // Status
                scanStatusBanner

                // Mode picker
                HStack(spacing: 0) {
                    ForEach(ScanMode.allCases, id: \.self) { mode in
                        Button {
                            viewModel.mode = mode
                        } label: {
                            Text(mode.title)
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    viewModel.mode == mode
                                        ? AppColor.brand
                                        : Color.clear
                                )
                                .foregroundStyle(
                                    viewModel.mode == mode ? .white : AppColor.textSecondary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.mode)
                    }
                }
                .padding(4)
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
            .padding(.top, AppSpacing.lg)
            .background(
                LinearGradient(
                    colors: [.clear, AppColor.page.opacity(0.95)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    // MARK: – Status banner
    @ViewBuilder
    private var scanStatusBanner: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .searching:
            HStack(spacing: 8) {
                ProgressView().tint(AppColor.accent)
                Text("Recherche…")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppColor.textPrimary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColor.card)
            .clipShape(Capsule())
        case .notFound(let msg):
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill").foregroundStyle(AppColor.danger)
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Spacer()
                Button("Réessayer") { viewModel.reset() }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColor.brand)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColor.danger.opacity(0.3), lineWidth: 1)
            )
        case .found:
            EmptyView()
        case .articleNotFound:
            EmptyView()
        case .permissionDenied:
            EmptyView()
        }
    }

    // MARK: – Article not found overlay
    @ViewBuilder
    private func articleNotFoundOverlay(barcode: String) -> some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { viewModel.reset() } }

            VStack(spacing: 0) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppColor.danger.opacity(0.15))
                        .frame(width: 88, height: 88)
                    Circle()
                        .fill(AppColor.danger.opacity(0.08))
                        .frame(width: 108, height: 108)
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(AppColor.danger)
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppColor.danger)
                        .offset(x: 26, y: -26)
                }
                .padding(.bottom, AppSpacing.lg)

                // Title
                Text("Référence introuvable")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(.bottom, AppSpacing.xs)

                // Barcode badge
                Text(barcode)
                    .font(.system(.callout, design: .monospaced).weight(.semibold))
                    .foregroundStyle(AppColor.brand)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, 6)
                    .background(AppColor.brand.opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.bottom, AppSpacing.md)

                // Subtitle
                Text("Ce code-barres n'existe pas\ndans votre base de données.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.bottom, AppSpacing.lg)

                Divider()
                    .background(AppColor.separator)
                    .padding(.bottom, AppSpacing.md)

                // Tip
                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(AppColor.textTertiary)
                    Text("Pour créer cet article, ajoutez-le\ndepuis l'interface web d'administration.")
                        .font(.caption)
                        .foregroundStyle(AppColor.textTertiary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.bottom, AppSpacing.xl)

                // CTA
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.reset()
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.subheadline.weight(.semibold))
                        Text("Scanner à nouveau")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            colors: [AppColor.brand, AppColor.brandDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.pill))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(AppColor.card)
                    .shadow(color: .black.opacity(0.35), radius: 32, y: 12)
            )
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    // MARK: – Permission denied
    private var permissionDeniedView: some View {
        ZStack {
            AppColor.pageGradient.ignoresSafeArea()
            VStack(spacing: AppSpacing.lg) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(AppColor.danger.opacity(0.15))
                        .frame(width: 96, height: 96)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColor.danger)
                }
                Text("Accès à la caméra refusé")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)
                Text("Autorisez l'accès dans\nRéglages > It-Inventory > Caméra.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.textSecondary)
                Button("Ouvrir les réglages") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.brand)
                Spacer()
            }
            .padding(AppSpacing.xl)
        }
    }

    // MARK: – Permission check
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermission = granted ? .authorized : .denied
                }
            }
        case let status:
            cameraPermission = status
        }
    }
}

// MARK: – Reverse mask helper
extension View {
    @ViewBuilder
    func reverseMask<M: View>(@ViewBuilder mask: () -> M) -> some View {
        self.mask(
            ZStack {
                Rectangle()
                mask().blendMode(.destinationOut)
            }
            .compositingGroup()
        )
    }
}

enum ScanMode: CaseIterable {
    case entree
    case sortie
    case consultation

    var title: String {
        switch self {
        case .entree: return "Entrée"
        case .sortie: return "Sortie"
        case .consultation: return "Consultation"
        }
    }
}

private struct ViewfinderCorners: View {
    let size: CGSize
    let active: Bool

    var body: some View {
        ZStack {
            cornerMark
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            cornerMark
                .rotationEffect(.degrees(90))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            cornerMark
                .rotationEffect(.degrees(-90))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            cornerMark
                .rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(width: size.width, height: size.height)
    }

    private var cornerMark: some View {
        ZStack(alignment: .topLeading) {
            Capsule(style: .continuous)
                .fill(AppColor.accent)
                .frame(width: 42, height: 4)
            Capsule(style: .continuous)
                .fill(AppColor.brand)
                .frame(width: 4, height: 42)
        }
        .shadow(color: active ? AppColor.accent.opacity(0.9) : AppColor.accent.opacity(0.45), radius: active ? 12 : 6)
        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: active)
    }
}

// MARK: - Scan Result Sheet

private struct ScanActionDestination: Hashable {
    let type: MovementType
    let targetSite: Site?
    func hash(into hasher: inout Hasher) {
        hasher.combine(type.rawValue)
        hasher.combine(targetSite?.id)
    }
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type == rhs.type && lhs.targetSite?.id == rhs.targetSite?.id
    }
}

private struct ScanResultSheet: View {
    let article: Article
    let currentStock: Int?
    let existsOnSelectedSite: Bool
    let selectedSiteName: String?
    let transferSites: [Site]
    let isProcessing: Bool
    let isReadOnly: Bool
    let onConsult: () -> Void
    let onConfirm: (MovementType, Int, String?, Site?) -> Void
    let onPCStatusChange: (PCStatus, @escaping (Bool, String?) -> Void) -> Void
    let onNewScan: () -> Void

    @State private var navPath = NavigationPath()
    @State private var isUpdatingPC = false
    @State private var pcUpdateError: String?
    @State private var showTransferList = false
    @State private var pcSuccessStatus: PCStatus?

    private var stockTint: Color {
        guard let currentStock else { return AppColor.textTertiary }
        if !existsOnSelectedSite { return AppColor.danger }
        return currentStock <= article.minStock ? AppColor.warning : AppColor.success
    }

    private var stockText: String {
        guard let currentStock else { return "—" }
        return "\(currentStock)"
    }

    private var isPCArticle: Bool {
        let type = (article.articleType ?? "")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return type.contains("pc")
    }

    private var currentPCStatus: PCStatus {
        PCStatus.from(description: article.descriptionText)
    }

    private var headerAvatarStyle: AnyShapeStyle {
        if isPCArticle {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(red: 0.24, green: 0.58, blue: 1.0), Color(red: 0.16, green: 0.34, blue: 0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(AppColor.brandGradient)
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // ── Article header ──────────────────────────────
                    VStack(spacing: 12) {
                        AsyncImage(url: article.imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
                            default:
                                ZStack {
                                    Circle()
                                        .fill(headerAvatarStyle)
                                        .frame(width: 80, height: 80)
                                        .shadow(color: AppColor.brand.opacity(0.4), radius: 12, y: 6)
                                    Image(systemName: isPCArticle ? "desktopcomputer" : "barcode.viewfinder")
                                        .font(.system(size: 30, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }

                        VStack(spacing: 4) {
                            Text(article.name)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(AppColor.textPrimary)
                                .multilineTextAlignment(.center)

                            if let brand = article.brand {
                                Text(brand + (article.model != nil ? " · \(article.model!)" : ""))
                                    .font(.subheadline)
                                    .foregroundStyle(AppColor.textSecondary)
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "number")
                                    .font(.caption2)
                                Text(article.reference)
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(AppColor.textTertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppColor.surface)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 8)

                    // ── Stock actuel (style iOS) ───────────────────
                    if !isPCArticle {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(stockTint.opacity(0.16))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "shippingbox.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(stockTint)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("STOCK ACTUEL")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(AppColor.textSecondary)
                                Text("Article correspondant")
                                    .font(.caption)
                                    .foregroundStyle(AppColor.textTertiary)
                            }

                            Spacer()

                            Text(stockText)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(stockTint)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }

                    if !isPCArticle && !existsOnSelectedSite {
                        HStack(alignment: .top, spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(AppColor.danger.opacity(0.15))
                                    .frame(width: 26, height: 26)
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppColor.danger)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Article indisponible sur ce site")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColor.textPrimary)
                                Text("\(article.name) n'existe pas dans \(selectedSiteName ?? "le site sélectionné").")
                                    .font(.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(AppColor.danger.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColor.danger.opacity(0.25), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }

                    Divider()
                        .background(AppColor.separator)
                        .padding(.horizontal, 20)

                    // ── Actions ─────────────────────────────────────
                    Group {
                        if isPCArticle {
                            if !isReadOnly {
                                pcStatusActionsSection
                            }
                        } else {
                            VStack(spacing: 10) {
                            // Consulter
                            ScanActionButton(
                                title: "Consulter l'article",
                                subtitle: "Voir le détail et les stocks",
                                icon: "doc.text.magnifyingglass",
                                color: AppColor.brand,
                                style: .primary,
                                isLoading: false,
                                action: onConsult
                            )

                            if !isReadOnly && existsOnSelectedSite {
                                HStack(spacing: 10) {
                                    // Entrée
                                    ScanActionButton(
                                        title: "Entrée",
                                        subtitle: "Choisir la quantité",
                                        icon: "arrow.down.circle.fill",
                                        color: AppColor.success,
                                        style: .secondary,
                                        isLoading: isProcessing,
                                        action: {
                                            navPath.append(ScanActionDestination(type: .entry, targetSite: nil))
                                        }
                                    )
                                    // Sortie
                                    ScanActionButton(
                                        title: "Sortie",
                                        subtitle: "Choisir la quantité",
                                        icon: "arrow.up.circle.fill",
                                        color: AppColor.danger,
                                        style: .secondary,
                                        isLoading: isProcessing,
                                        action: {
                                            navPath.append(ScanActionDestination(type: .exit, targetSite: nil))
                                        }
                                    )
                                }

                                HStack(spacing: 10) {
                                    // Ajustement
                                    ScanActionButton(
                                        title: "Ajustement",
                                        subtitle: "Corriger le stock",
                                        icon: "slider.horizontal.3",
                                        color: AppColor.warning,
                                        style: .secondary,
                                        isLoading: isProcessing,
                                        action: {
                                            navPath.append(ScanActionDestination(type: .adjustment, targetSite: nil))
                                        }
                                    )

                                    // Transfert
                                    if !transferSites.isEmpty {
                                        Menu {
                                            ForEach(transferSites) { site in
                                                Button {
                                                    navPath.append(ScanActionDestination(type: .transfer, targetSite: site))
                                                } label: {
                                                    Label(site.name, systemImage: "arrow.triangle.swap")
                                                }
                                            }
                                        } label: {
                                            ScanActionButtonLabel(
                                                title: "Transfert",
                                                subtitle: "Changer de site",
                                                icon: "arrow.triangle.swap",
                                                color: AppColor.accent,
                                                style: .secondary,
                                                isLoading: false
                                            )
                                        }
                                    }
                                }
                            } // if !isReadOnly && existsOnSelectedSite
                        }
                    }
                    }
                    .padding(.horizontal, 20)

                    // ── Nouveau scan ─────────────────────────────────
                    Button(action: onNewScan) {
                        HStack(spacing: 6) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.subheadline.weight(.semibold))
                            Text("Nouveau scan")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
            .background(AppColor.page.ignoresSafeArea())
            .navigationTitle("Article détecté")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Erreur", isPresented: Binding(
                get: { pcUpdateError != nil },
                set: { if !$0 { pcUpdateError = nil } }
            )) {
                Button("OK", role: .cancel) { pcUpdateError = nil }
            } message: {
                Text(pcUpdateError ?? "")
            }
            .navigationDestination(for: ScanActionDestination.self) { dest in
                ScanQuantityView(
                    type: dest.type,
                    targetSite: dest.targetSite,
                    currentStock: currentStock
                ) { qty, reason in
                    onConfirm(dest.type, qty, reason, dest.targetSite)
                }
            }
            } // ZStack
            .overlay {
                if let status = pcSuccessStatus {
                    PCStatusSuccessOverlay(status: status)
                        .transition(.opacity)
                }
            }
        }
    }

    private var pcStatusActionsSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Statut PC")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text(currentPCStatus.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(pcColor(currentPCStatus))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(pcColor(currentPCStatus).opacity(0.15))
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                pcStatusActionButton(status: .hot, title: "A chaud", icon: "flame.fill")
                pcStatusActionButton(status: .machining, title: "En usinage", icon: "gearshape.2.fill")
            }

            HStack(spacing: 10) {
                pcStatusActionButton(status: .sent, title: "A envoyer", icon: "paperplane.fill")
                pcStatusActionButton(status: .available, title: "Disponible", icon: "checkmark.circle.fill")
            }
        }
    }

    private func pcStatusActionButton(status: PCStatus, title: String, icon: String) -> some View {
        let color = pcColor(status)
        let isCurrent = status == currentPCStatus
        return ScanActionButton(
            title: title,
            subtitle: isCurrent ? "Statut actuel" : "Mettre à jour le statut",
            icon: icon,
            color: color,
            style: .secondary,
            isLoading: isUpdatingPC && !isCurrent,
            action: {
                guard !isUpdatingPC else { return }
                isUpdatingPC = true
                onPCStatusChange(status) { success, errorMsg in
                    isUpdatingPC = false
                    if success {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            pcSuccessStatus = status
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            onNewScan()
                        }
                    } else {
                        pcUpdateError = errorMsg ?? "Impossible de mettre à jour le statut."
                    }
                }
            }
        )
        .disabled(isCurrent || isUpdatingPC)
        .opacity(isCurrent ? 0.55 : 1.0)
    }

    private func pcColor(_ status: PCStatus) -> Color {
        switch status {
        case .hot:
            return AppColor.success
        case .machining, .rework:
            return AppColor.warning
        case .available:
            return AppColor.brand
        case .sent:
            return AppColor.danger
        case .unknown:
            return AppColor.textSecondary
        }
    }
}

private enum ScanActionButtonStyle { case primary, secondary }

private struct ScanActionButtonLabel: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let style: ScanActionButtonStyle
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                if isLoading {
                    ProgressView().tint(color).scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(color)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(style == .primary ? .headline : .subheadline.weight(.semibold))
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
        .padding(style == .primary ? 16 : 12)
        .frame(maxWidth: .infinity)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: style == .primary ? 16 : 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: style == .primary ? 16 : 14, style: .continuous)
                .stroke(
                    style == .primary ? color.opacity(0.25) : Color.white.opacity(0.07),
                    lineWidth: 1
                )
        )
    }
}

private struct ScanActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let style: ScanActionButtonStyle
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ScanActionButtonLabel(
                title: title,
                subtitle: subtitle,
                icon: icon,
                color: color,
                style: style,
                isLoading: isLoading
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - PC Status Success Overlay

private struct PCStatusSuccessOverlay: View {
    let status: PCStatus

    @State private var circleScale: CGFloat = 0.4
    @State private var circleOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.2
    @State private var iconOpacity: Double = 0
    @State private var labelOffset: CGFloat = 18
    @State private var labelOpacity: Double = 0
    @State private var bgOpacity: Double = 0
    @State private var rippleScale: CGFloat = 0.6
    @State private var rippleOpacity: Double = 0.4

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(bgOpacity)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(statusColor.opacity(rippleOpacity), lineWidth: 3)
                        .frame(width: 130, height: 130)
                        .scaleEffect(rippleScale)

                    Circle()
                        .fill(statusColor.opacity(0.18))
                        .frame(width: 100, height: 100)
                        .scaleEffect(circleScale)
                        .opacity(circleOpacity)

                    Image(systemName: statusIcon)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(statusColor)
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                }

                VStack(spacing: 6) {
                    Text("Statut mis à jour")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text(status.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .offset(y: labelOffset)
                .opacity(labelOpacity)
            }
        }
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        withAnimation(.easeOut(duration: 0.25)) { bgOpacity = 1 }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.05)) {
            circleScale = 1; circleOpacity = 1
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55).delay(0.15)) {
            iconScale = 1; iconOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.2)) {
            labelOffset = 0; labelOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.9).delay(0.1)) {
            rippleScale = 1.4; rippleOpacity = 0
        }
    }

    private var statusColor: Color {
        switch status {
        case .hot:              return AppColor.success
        case .machining, .rework: return AppColor.warning
        case .available:        return AppColor.brand
        case .sent:             return AppColor.danger
        case .unknown:          return AppColor.textSecondary
        }
    }

    private var statusIcon: String {
        switch status {
        case .hot:              return "flame.fill"
        case .rework:           return "wrench.and.screwdriver.fill"
        case .machining:        return "gearshape.2.fill"
        case .available:        return "checkmark.circle.fill"
        case .sent:             return "paperplane.fill"
        case .unknown:          return "questionmark.circle.fill"
        }
    }
}

// MARK: - Quantity Picker

private struct ScanQuantityView: View {
    let type: MovementType
    let targetSite: Site?
    let currentStock: Int?
    let onConfirm: (Int, String?) -> Void

    @State private var quantity = 1
    @State private var reason = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var scaleEffect: CGFloat = 1.0

    private var typeLabel: String {
        switch type {
        case .entry: return "Entrée"
        case .exit: return "Sortie"
        case .adjustment: return "Ajustement"
        case .transfer: return "Transfert"
        case .unknown: return "Mouvement"
        }
    }

    private var typeColor: Color {
        switch type {
        case .entry: return AppColor.success
        case .exit: return AppColor.danger
        case .adjustment: return AppColor.warning
        case .transfer: return AppColor.accent
        case .unknown: return AppColor.brand
        }
    }

    private var typeIcon: String {
        switch type {
        case .entry: return "arrow.down.circle.fill"
        case .exit: return "arrow.up.circle.fill"
        case .adjustment: return "slider.horizontal.3"
        case .transfer: return "arrow.triangle.swap"
        case .unknown: return "questionmark"
        }
    }

    private var projectedStock: Int? {
        guard let currentStock else { return nil }
        switch type {
        case .entry:
            return currentStock + quantity
        case .exit, .adjustment:
            return max(0, currentStock - quantity)
        case .transfer, .unknown:
            return nil
        }
    }

    private var shouldShowProjection: Bool {
        currentStock != nil && (type == .entry || type == .exit || type == .adjustment)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {

                // ── Site destination (Transfert) ──────────────────
                if let site = targetSite {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(typeColor.opacity(0.12)).frame(width: 40, height: 40)
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(typeColor)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SITE DESTINATION")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(AppColor.textSecondary)
                            Text(site.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppColor.textPrimary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(AppColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(typeColor.opacity(0.2), lineWidth: 1)
                    )
                }

                if shouldShowProjection {
                    HStack(spacing: 10) {
                        stockValueCard(
                            title: "Stock actuel",
                            value: currentStock ?? 0,
                            tint: AppColor.textSecondary
                        )

                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppColor.textTertiary)

                        stockValueCard(
                            title: type == .adjustment ? "Stock final (ajusté)" : "Stock final",
                            value: projectedStock ?? 0,
                            tint: typeColor
                        )
                    }
                }

                // ── Quantité ──────────────────────────────────────
                VStack(spacing: 16) {
                    Text("QUANTITÉ")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Stepper principal
                    HStack(spacing: 0) {
                        // Moins
                        Button {
                            if quantity > 1 {
                                quantity -= 1
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(quantity > 1 ? AppColor.textPrimary : AppColor.textTertiary)
                                .frame(width: 60, height: 72)
                        }
                        .buttonStyle(.plain)

                        Divider().frame(height: 36).background(AppColor.separator)

                        // Valeur
                        Text("\(quantity)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(maxWidth: .infinity)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: quantity)

                        Divider().frame(height: 36).background(AppColor.separator)

                        // Plus
                        Button {
                            quantity += 1
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(typeColor)
                                .frame(width: 60, height: 72)
                        }
                        .buttonStyle(.plain)
                    }
                    .background(AppColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                    // Raccourcis
                    HStack(spacing: 10) {
                        ForEach([5, 10, 25, 50], id: \.self) { amt in
                            Button {
                                quantity += amt
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Text("+\(amt)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(typeColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(typeColor.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // ── Motif ─────────────────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    Text("MOTIF (OPTIONNEL)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)

                    TextField("Ex : retour fournisseur, inventaire…", text: $reason, axis: .vertical)
                        .lineLimit(3...5)
                        .font(.body)
                        .padding(14)
                        .background(AppColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // ── Bouton Confirmer ──────────────────────────────
                Button {
                    confirm()
                } label: {
                    ZStack {
                        // Contenu normal
                        HStack(spacing: 10) {
                            Image(systemName: typeIcon)
                                .font(.headline)
                            Text("Confirmer \(typeLabel.lowercased()) × \(quantity)")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .opacity(showSuccess ? 0 : (isSubmitting ? 0 : 1))

                        // Spinner
                        if isSubmitting && !showSuccess {
                            ProgressView().tint(.white)
                        }

                        // Checkmark succès
                        if showSuccess {
                            Image(systemName: "checkmark")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(showSuccess ? AppColor.success : typeColor)
                    )
                    .scaleEffect(scaleEffect)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: showSuccess)
                }
                .buttonStyle(.plain)
                .disabled(isSubmitting)
            }
            .padding(20)
            .padding(.top, 8)
        }
        .background(AppColor.page.ignoresSafeArea())
        .navigationTitle(typeLabel)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stockValueCard(title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)
            Text("\(value)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func confirm() {
        guard !isSubmitting else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            scaleEffect = 0.96
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scaleEffect = 1.0
            }
        }
        isSubmitting = true
        let note = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        // Show success then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showSuccess = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                onConfirm(quantity, note.isEmpty ? nil : note)
            }
        }
    }
}