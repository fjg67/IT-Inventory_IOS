// HomeViewModel.swift
import Foundation
import SwiftUI

enum OpsCrystal {
    static let backgroundDeep = AppColor.page
    static let surface = AppColor.card.opacity(0.92)
    static let border = AppColor.separator

    static let accentPrimary = Color(hex: 0x6C5CE7)
    static let accentSecondary = Color(hex: 0x00D2FF)

    static let positive = Color(hex: 0x00C896)
    static let negative = Color(hex: 0xFF6B6B)
    static let warning = Color(hex: 0xFFB347)

    static let textPrimary = AppColor.textPrimary
    static let textSecondary = AppColor.textSecondary

    static let pageGradient = AppColor.pageGradient
}

enum HomeQuickActionKind: String, CaseIterable, Identifiable {
    case entry
    case exit
    case articles
    case transfer

    var id: String { rawValue }
}

struct HomeKPI: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    let tint: Color
    let showsPulseBadge: Bool
}

struct HomeQuickAction: Identifiable {
    let id = UUID()
    let kind: HomeQuickActionKind
    let title: String
    let icon: String
    let color: Color
    let isSquare: Bool
}

struct HomeMovementItem: Identifiable {
    let id = UUID()
    let articleName: String
    let type: HomeQuickActionKind
    let code: String
    let technicianAcronym: String
    let delta: Int
    let ageLabel: String

    var typeLabel: String {
        switch type {
        case .entry: return "Entree"
        case .exit: return "Sortie"
        case .transfer: return "Transfert"
        case .articles: return "Article"
        }
    }

    var typeColor: Color {
        switch type {
        case .entry: return OpsCrystal.positive
        case .exit: return OpsCrystal.negative
        case .transfer: return OpsCrystal.accentSecondary
        case .articles: return OpsCrystal.accentPrimary
        }
    }

    var icon: String {
        switch type {
        case .entry: return "arrow.down.circle.fill"
        case .exit: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right"
        case .articles: return "cube.box.fill"
        }
    }
}

struct HomeTrendPoint: Identifiable {
    let id = UUID()
    let day: String
    let value: Int
}

final class HomeViewModel: ObservableObject {
    @Published var greeting: String = HomeViewModel.makeGreeting(for: Date())
    @Published var title: String = "Stock Ops"
    @Published var selectedSiteLabel: String = "Stock 5eme"
    @Published var initials: String = "FJG"
    @Published var technicianBadge: String = "T099007"

    @Published var kpis: [HomeKPI] = []
    @Published var actions: [HomeQuickAction] = []
    @Published var recentMovements: [HomeMovementItem] = []
    @Published var trendPoints: [HomeTrendPoint] = []

    private let fetchArticlesUseCase: FetchArticlesUseCase?
    private let fetchMovementsUseCase: FetchMovementsUseCase?
    private let articleStockRepository: ArticleStockRepository?
    private let technicianRepository: TechnicianRepository?

    init(
        fetchArticlesUseCase: FetchArticlesUseCase? = nil,
        fetchMovementsUseCase: FetchMovementsUseCase? = nil,
        articleStockRepository: ArticleStockRepository? = nil,
        technicianRepository: TechnicianRepository? = nil
    ) {
        self.fetchArticlesUseCase = fetchArticlesUseCase
        self.fetchMovementsUseCase = fetchMovementsUseCase
        self.articleStockRepository = articleStockRepository
        self.technicianRepository = technicianRepository
        loadMock()
    }

    func loadMock() {
        kpis = [
            HomeKPI(
                title: "Articles",
                value: "-",
                icon: "tag.fill",
                gradient: LinearGradient(colors: [Color(hex: 0x6C5CE7), Color(hex: 0xA29BFE)], startPoint: .topLeading, endPoint: .bottomTrailing),
                tint: OpsCrystal.accentPrimary,
                showsPulseBadge: false
            ),
            HomeKPI(
                title: "Alertes",
                value: "-",
                icon: "exclamationmark.triangle.fill",
                gradient: LinearGradient(colors: [Color(hex: 0xFFB347), Color(hex: 0xFF7675)], startPoint: .topLeading, endPoint: .bottomTrailing),
                tint: OpsCrystal.warning,
                showsPulseBadge: false
            )
        ]

        actions = [
            HomeQuickAction(kind: .entry, title: "Entree", icon: "arrow.down.circle.fill", color: OpsCrystal.positive, isSquare: false),
            HomeQuickAction(kind: .exit, title: "Sortie", icon: "arrow.up.circle.fill", color: OpsCrystal.negative, isSquare: false),
            HomeQuickAction(kind: .articles, title: "Articles", icon: "cube.fill", color: OpsCrystal.accentPrimary, isSquare: true),
            HomeQuickAction(kind: .transfer, title: "Transfert", icon: "arrow.triangle.2.circlepath", color: OpsCrystal.accentSecondary, isSquare: false)
        ]

        recentMovements = [
            HomeMovementItem(articleName: "Chargeur USB-C 65W", type: .entry, code: "CHG-65W", technicianAcronym: "FJG", delta: 1, ageLabel: "-2 j"),
            HomeMovementItem(articleName: "Dock Thunderbolt", type: .exit, code: "DOCK-TB4", technicianAcronym: "MLE", delta: -1, ageLabel: "-2 j"),
            HomeMovementItem(articleName: "Ecran 27 pouces", type: .entry, code: "MON-27Q", technicianAcronym: "NGR", delta: 2, ageLabel: "-2 j"),
            HomeMovementItem(articleName: "Clavier MX", type: .entry, code: "KEY-MX", technicianAcronym: "FJG", delta: 12, ageLabel: "-2 j"),
            HomeMovementItem(articleName: "Souris verticale", type: .exit, code: "MOU-VRT", technicianAcronym: "JDL", delta: -5, ageLabel: "-5 j")
        ]

        trendPoints = [
            HomeTrendPoint(day: "Lun", value: 6),
            HomeTrendPoint(day: "Mar", value: 1),
            HomeTrendPoint(day: "Mer", value: 0),
            HomeTrendPoint(day: "Jeu", value: 4),
            HomeTrendPoint(day: "Ven", value: 0),
            HomeTrendPoint(day: "Sam", value: 1),
            HomeTrendPoint(day: "Dim", value: 1)
        ]
    }

    @MainActor
    func load(siteId: String?) async {
        await loadKPIs(siteId: siteId)
        await loadRecentMovements(siteId: siteId)
    }

    @MainActor
    private func loadTrend(from movements: [StockMovement]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayNames = ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"]

        var points: [HomeTrendPoint] = []
        for offset in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let count = movements.filter { calendar.isDate($0.createdAt, inSameDayAs: day) }.count
            let weekday = calendar.component(.weekday, from: day) - 1
            points.append(HomeTrendPoint(day: dayNames[weekday], value: count))
        }
        trendPoints = points
    }

    @MainActor
    private func loadKPIs(siteId: String?) async {
        guard let fetchArticlesUseCase, let articleStockRepository else { return }
        do {
            async let articlesTask = fetchArticlesUseCase.execute(search: nil)

            let stocksTask: [ArticleStock]
            if let siteId {
                stocksTask = try await articleStockRepository.fetchAllStocks(forSite: siteId)
            } else {
                stocksTask = try await articleStockRepository.fetchAllStocks()
            }

            let articles = try await articlesTask
            let stockByArticle = Dictionary(
                stocksTask.map { ($0.articleId, $0.quantity) },
                uniquingKeysWith: { $1 }
            )

            let articleIds = Set(stocksTask.filter { $0.quantity > 0 }.map { $0.articleId })
            let validArticles = articles.filter {
                !$0.isArchived && articleIds.contains($0.id)
            }

            let articlesCount = validArticles.count
            let alertCount = validArticles.filter { article in
                guard article.minStock > 0 else { return false }
                return (stockByArticle[article.id] ?? 0) < article.minStock
            }.count

            kpis = [
                HomeKPI(
                    title: "Articles",
                    value: "\(articlesCount)",
                    icon: "tag.fill",
                    gradient: LinearGradient(colors: [Color(hex: 0x6C5CE7), Color(hex: 0xA29BFE)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    tint: OpsCrystal.accentPrimary,
                    showsPulseBadge: false
                ),
                HomeKPI(
                    title: "Alertes",
                    value: "\(alertCount)",
                    icon: "exclamationmark.triangle.fill",
                    gradient: LinearGradient(colors: [Color(hex: 0xFFB347), Color(hex: 0xFF7675)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    tint: OpsCrystal.warning,
                    showsPulseBadge: alertCount > 0
                )
            ]
        } catch {
            // Keep placeholder values on error.
        }
    }

    @MainActor
    func loadRecentMovements(siteId: String?) async {
        guard let fetchArticlesUseCase, let fetchMovementsUseCase else {
            return
        }

        do {
            async let articlesTask = fetchArticlesUseCase.execute(search: nil)
            let techniciansTask: [Technician]
            if let technicianRepository {
                techniciansTask = try await technicianRepository.fetchActiveTechnicians()
            } else {
                techniciansTask = []
            }

            let movementsTask: [StockMovement]
            if let siteId {
                movementsTask = try await fetchMovementsUseCase.execute(forSite: siteId, limit: 200)
            } else {
                movementsTask = try await fetchMovementsUseCase.execute(limit: 200)
            }

            let articles = try await articlesTask
            let technicians = techniciansTask
            let articleMap = Dictionary(uniqueKeysWithValues: articles.map { ($0.id, $0) })
            let technicianMap = Dictionary(uniqueKeysWithValues: technicians.map { ($0.id, $0.initials) })

            recentMovements = movementsTask
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(5)
                .map { movement in
                    let article = articleMap[movement.articleId]
                    let code = article?.reference ?? String(movement.articleId.uuidString.prefix(8))
                    let type = mapMovementType(movement.type)
                    let technicianAcronym = technicianMap[movement.userId] ?? "---"

                    return HomeMovementItem(
                        articleName: article?.name ?? "Article inconnu",
                        type: type,
                        code: code,
                        technicianAcronym: technicianAcronym,
                        delta: movement.quantity,
                        ageLabel: relativeLabel(for: movement.createdAt)
                    )
                }

            loadTrend(from: movementsTask)
        } catch {
            // Keep previous data to avoid blank UI on transient network errors.
        }
    }

    private func mapMovementType(_ type: MovementType) -> HomeQuickActionKind {
        switch type {
        case .entry:
            return .entry
        case .exit:
            return .exit
        case .transfer:
            return .transfer
        case .adjustment, .unknown:
            return .articles
        }
    }

    private func relativeLabel(for date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "-\(max(days, 0)) j"
    }

    private static func makeGreeting(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Bonjour"
        case 12..<18: return "Bon apres-midi"
        default: return "Bonsoir"
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
