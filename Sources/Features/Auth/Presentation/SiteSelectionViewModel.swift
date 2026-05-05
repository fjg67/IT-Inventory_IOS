import Foundation

@Observable
final class SiteSelectionViewModel: @unchecked Sendable {
    // All fetched sites
    private(set) var allSites: [Site] = []
    var isLoading = false
    var errorMessage: String?

    // Two-step navigation: nil = showing top-level, set = showing children
    var selectedParent: Site? = nil

    /// Sites shown at step 1 (no parent)
    var topLevelSites: [Site] {
        allSites.filter { $0.parentSiteId == nil }.sorted { $0.name < $1.name }
    }

    /// Children of a given parent site
    func children(of parent: Site) -> [Site] {
        allSites.filter { $0.parentSiteId == parent.id }.sorted { $0.name < $1.name }
    }

    /// Whether a site has sub-sites
    func hasChildren(_ site: Site) -> Bool {
        allSites.contains { $0.parentSiteId == site.id }
    }

    private let siteRepository: SiteRepository

    init(siteRepository: SiteRepository) {
        self.siteRepository = siteRepository
    }

    func loadSites() {
        guard allSites.isEmpty else { return }
        Task { await fetchSites() }
    }

    func reload() async {
        await fetchSites()
    }

    private func fetchSites() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            // Fetch all sites regardless of isActive so children are visible
            let all = try await siteRepository.fetchAllSites()
            allSites = all
        } catch {
            errorMessage = "Erreur: \(error.localizedDescription)"
        }
    }
}
