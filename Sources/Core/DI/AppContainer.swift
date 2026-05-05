import Foundation

@MainActor
@Observable
final class AppContainer {
    let environment: AppEnvironment
    let authViewModel: AuthViewModel
    let articlesViewModel: ArticlesViewModel
    let movementsViewModel: MovementsViewModel
    let dashboardViewModel: DashboardViewModel
    let pcViewModel: PCViewModel
    let createMovementViewModel: CreateMovementViewModel

    var selectedSite: Site? = nil {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(selectedSite?.id, forKey: Self.persistedSiteIDKey)
        }
    }
    var availableSites: [Site] = []
    var selectedTechnician: Technician? = nil {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(selectedTechnician?.id, forKey: Self.persistedTechnicianIDKey)
        }
    }
    var selectedTab: AppTab = .dashboard
    var pendingQuickMovementType: MovementType?
    var isRestoringSessionContext = false

    /// Superviseurs sont en lecture seule — pas de mouvements ni de changements de statut PC.
    var isReadOnly: Bool {
        selectedTechnician?.role.lowercased() == "superviseur"
    }

    var appTheme: AppTheme = .dark {
        didSet {
            UserDefaults.standard.set(appTheme.rawValue, forKey: Self.persistedThemeKey)
        }
    }

    private let fetchArticleStocksUseCase: FetchArticleStocksUseCase
    private let articleRepository: ArticleRepository
    private let fetchArticlesUseCase: FetchArticlesUseCase
    private let createArticleUseCase: CreateArticleUseCase
    private let fetchMovementsUseCase: FetchMovementsUseCase
    private let createStockMovementUseCase: CreateStockMovementUseCase
    private let stockMovementNotificationService: StockMovementNotificationService
    private let articleStockRepository: ArticleStockRepository
    let siteRepository: SiteRepository
    let technicianRepository: TechnicianRepository
    private let findArticleByBarcodeUseCase: FindArticleByBarcodeUseCase
    private let pcStatusNotificationService: PCStatusNotificationService
    private var didAttemptSessionContextRestore = false

    private static let persistedSiteIDKey = "app.last.selected.site.id"
    private static let persistedTechnicianIDKey = "app.last.selected.technician.id"
    private static let persistedThemeKey = "app.theme"

    init(
        environment: AppEnvironment,
        authViewModel: AuthViewModel,
        articlesViewModel: ArticlesViewModel,
        movementsViewModel: MovementsViewModel,
        dashboardViewModel: DashboardViewModel,
        pcViewModel: PCViewModel,
        createMovementViewModel: CreateMovementViewModel,
        fetchArticleStocksUseCase: FetchArticleStocksUseCase,
        articleRepository: ArticleRepository,
        fetchArticlesUseCase: FetchArticlesUseCase,
        createArticleUseCase: CreateArticleUseCase,
        fetchMovementsUseCase: FetchMovementsUseCase,
        createStockMovementUseCase: CreateStockMovementUseCase,
        stockMovementNotificationService: StockMovementNotificationService,
        pcStatusNotificationService: PCStatusNotificationService,
        articleStockRepository: ArticleStockRepository,
        siteRepository: SiteRepository,
        technicianRepository: TechnicianRepository,
        findArticleByBarcodeUseCase: FindArticleByBarcodeUseCase
    ) {
        self.environment = environment
        self.authViewModel = authViewModel
        self.articlesViewModel = articlesViewModel
        self.movementsViewModel = movementsViewModel
        self.dashboardViewModel = dashboardViewModel
        self.pcViewModel = pcViewModel
        self.createMovementViewModel = createMovementViewModel
        self.fetchArticleStocksUseCase = fetchArticleStocksUseCase
        self.articleRepository = articleRepository
        self.fetchArticlesUseCase = fetchArticlesUseCase
        self.createArticleUseCase = createArticleUseCase
        self.fetchMovementsUseCase = fetchMovementsUseCase
        self.createStockMovementUseCase = createStockMovementUseCase
        self.stockMovementNotificationService = stockMovementNotificationService
        self.pcStatusNotificationService = pcStatusNotificationService
        self.articleStockRepository = articleStockRepository
        self.siteRepository = siteRepository
        self.technicianRepository = technicianRepository
        self.findArticleByBarcodeUseCase = findArticleByBarcodeUseCase
    }

    func makeArticleStockViewModel(for article: Article) -> ArticleStockViewModel {
        ArticleStockViewModel(
            article: article,
            fetchArticleStocksUseCase: fetchArticleStocksUseCase,
            articleStockRepository: articleStockRepository,
            fetchMovementsUseCase: fetchMovementsUseCase,
            siteRepository: siteRepository,
            createStockMovementUseCase: createStockMovementUseCase,
            stockMovementNotificationService: stockMovementNotificationService,
            selectedSiteId: selectedSite?.id
        )
    }

    func makeScanViewModel() -> ScanViewModel {
        ScanViewModel(
            findArticleByBarcodeUseCase: findArticleByBarcodeUseCase,
            articleRepository: articleRepository,
            createStockMovementUseCase: createStockMovementUseCase,
            stockMovementNotificationService: stockMovementNotificationService,
            pcStatusNotificationService: pcStatusNotificationService,
            articleStockRepository: articleStockRepository,
            siteRepository: siteRepository
        )
    }

    func makeSiteSelectionViewModel() -> SiteSelectionViewModel {
        SiteSelectionViewModel(siteRepository: siteRepository)
    }

    func makeTechnicianSelectionViewModel(siteId: String? = nil, parentSiteId: String? = nil) -> TechnicianSelectionViewModel {
        TechnicianSelectionViewModel(technicianRepository: technicianRepository, siteId: siteId, parentSiteId: parentSiteId)
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            fetchArticlesUseCase: fetchArticlesUseCase,
            fetchMovementsUseCase: fetchMovementsUseCase,
            articleStockRepository: articleStockRepository,
            technicianRepository: technicianRepository
        )
    }

    func makeAddArticleViewModel() -> AddArticleViewModel {
        AddArticleViewModel(createArticleUseCase: createArticleUseCase, siteId: selectedSite?.id)
    }

    func loadAvailableSitesIfNeeded() async {
        guard availableSites.isEmpty else { return }
        if let sites = try? await siteRepository.fetchAllSites() {
            availableSites = sites
        }
    }

    func resetSessionContextRestoreState() {
        didAttemptSessionContextRestore = false
        isRestoringSessionContext = false
    }

    func restoreSessionContextIfNeeded() async {
        guard selectedSite == nil, selectedTechnician == nil else {
            didAttemptSessionContextRestore = true
            return
        }

        guard !didAttemptSessionContextRestore else { return }
        didAttemptSessionContextRestore = true

        let defaults = UserDefaults.standard
        let persistedSiteID = defaults.string(forKey: Self.persistedSiteIDKey)
        let persistedTechnicianID = defaults.string(forKey: Self.persistedTechnicianIDKey)

        guard persistedSiteID != nil || persistedTechnicianID != nil else { return }

        isRestoringSessionContext = true
        defer { isRestoringSessionContext = false }

        do {
            if let persistedSiteID {
                let allSites = try await siteRepository.fetchAllSites()
                availableSites = allSites
                selectedSite = allSites.first(where: { $0.id == persistedSiteID })

                if selectedSite == nil {
                    defaults.removeObject(forKey: Self.persistedSiteIDKey)
                }
            }

            if let persistedTechnicianID {
                let technicians = try await technicianRepository.fetchActiveTechnicians()
                selectedTechnician = technicians.first(where: { $0.id == persistedTechnicianID })

                if selectedTechnician == nil {
                    defaults.removeObject(forKey: Self.persistedTechnicianIDKey)
                }
            }
        } catch {
            // Keep default flow (selection screens) if restore fails.
        }
    }

    static func bootstrap() -> AppContainer {
        let environment = AppEnvironment.current()
        let supabaseProvider = SupabaseClientProvider(
            baseURL: environment.supabaseURL,
            anonKey: environment.supabaseAnonKey
        )

        let authRemote = SupabaseAuthRemoteDataSource(client: supabaseProvider.client)
        let secureStore = KeychainSecureSessionStore(keychain: SystemKeychainClient())
        let authRepository = AuthRepositoryImpl(remote: authRemote, secureStore: secureStore)

        let restoreSessionUseCase = RestoreSessionUseCase(repository: authRepository)
        let signInUseCase = SignInUseCase(repository: authRepository)
        let signOutUseCase = SignOutUseCase(repository: authRepository)

        let authViewModel = AuthViewModel(
            restoreSessionUseCase: restoreSessionUseCase,
            signInUseCase: signInUseCase,
            signOutUseCase: signOutUseCase
        )

        let articlesRemote = SupabaseArticlesRemoteDataSource(client: supabaseProvider.client)
        let articleRepository = ArticleRepositoryImpl(remote: articlesRemote)
        let fetchArticlesUseCase = FetchArticlesUseCase(repository: articleRepository)
        let findArticleByBarcodeUseCase = FindArticleByBarcodeUseCase(repository: articleRepository)
        let createArticleUseCase = CreateArticleUseCase(repository: articleRepository)

        let movementsRemote = SupabaseMovementsRemoteDataSource(client: supabaseProvider.client)
        let movementRepository = MovementRepositoryImpl(remote: movementsRemote)
        let fetchMovementsUseCase = FetchMovementsUseCase(repository: movementRepository)
        let createStockMovementUseCase = CreateStockMovementUseCase(repository: movementRepository)
        let stockMovementNotificationService = LocalStockMovementNotificationService()
        let pcStatusNotificationService = LocalPCStatusNotificationService()

        let siteRemote = SupabaseSiteRemoteDataSource(client: supabaseProvider.client)
        let siteRepository = SiteRepositoryImpl(remote: siteRemote)

        let technicianRemote = SupabaseTechnicianRemoteDataSource(client: supabaseProvider.client)
        let technicianRepository = TechnicianRepositoryImpl(remote: technicianRemote)

        let movementsViewModel = MovementsViewModel(
            fetchMovementsUseCase: fetchMovementsUseCase,
            fetchArticlesUseCase: fetchArticlesUseCase,
            siteRepository: siteRepository,
            technicianRepository: technicianRepository
        )

        let createMovementViewModel = CreateMovementViewModel(
            createMovementUseCase: createStockMovementUseCase,
            fetchArticlesUseCase: fetchArticlesUseCase,
            siteRepository: siteRepository,
            stockMovementNotificationService: stockMovementNotificationService
        )

        let articleStockRemote = SupabaseArticleStockRemoteDataSource(client: supabaseProvider.client)
        let articleStockRepository = ArticleStockRepositoryImpl(remote: articleStockRemote)
        let fetchArticleStocksUseCase = FetchArticleStocksUseCase(repository: articleStockRepository)

        let articlesViewModel = ArticlesViewModel(
            fetchArticlesUseCase: fetchArticlesUseCase,
            articleStockRepository: articleStockRepository
        )

        let dashboardViewModel = DashboardViewModel(
            fetchArticlesUseCase: fetchArticlesUseCase,
            fetchMovementsUseCase: fetchMovementsUseCase,
            articleStockRepository: articleStockRepository
        )

        let pcViewModel = PCViewModel(
            articleRepository: articleRepository,
            articleStockRepository: articleStockRepository,
            historyStore: UserDefaultsPCSentHistoryStore(),
            notificationService: pcStatusNotificationService
        )

        let container = AppContainer(
            environment: environment,
            authViewModel: authViewModel,
            articlesViewModel: articlesViewModel,
            movementsViewModel: movementsViewModel,
            dashboardViewModel: dashboardViewModel,
            pcViewModel: pcViewModel,
            createMovementViewModel: createMovementViewModel,
            fetchArticleStocksUseCase: fetchArticleStocksUseCase,
            articleRepository: articleRepository,
            fetchArticlesUseCase: fetchArticlesUseCase,
            createArticleUseCase: createArticleUseCase,
            fetchMovementsUseCase: fetchMovementsUseCase,
            createStockMovementUseCase: createStockMovementUseCase,
            stockMovementNotificationService: stockMovementNotificationService,
            pcStatusNotificationService: pcStatusNotificationService,
            articleStockRepository: articleStockRepository,
            siteRepository: siteRepository,
            technicianRepository: technicianRepository,
            findArticleByBarcodeUseCase: findArticleByBarcodeUseCase
        )
        if let raw = UserDefaults.standard.string(forKey: Self.persistedThemeKey),
           let theme = AppTheme(rawValue: raw) {
            container.appTheme = theme
        }
        return container
    }
}
