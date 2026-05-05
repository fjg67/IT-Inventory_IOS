import Foundation

@Observable
final class TechnicianSelectionViewModel: @unchecked Sendable {
    private(set) var technicians: [Technician] = []
    var isLoading = false
    var errorMessage: String?

    private let technicianRepository: TechnicianRepository
    private let siteId: String?
    private let parentSiteId: String?

    init(technicianRepository: TechnicianRepository, siteId: String? = nil, parentSiteId: String? = nil) {
        self.technicianRepository = technicianRepository
        self.siteId = siteId
        self.parentSiteId = parentSiteId
    }

    func loadTechnicians() {
        guard technicians.isEmpty else { return }
        Task { await fetchTechnicians() }
    }

    func reload() async {
        await fetchTechnicians()
    }

    private func fetchTechnicians() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            if let siteId {
                technicians = try await technicianRepository.fetchActiveTechnicians(forSiteId: siteId, parentSiteId: parentSiteId)
            } else {
                technicians = try await technicianRepository.fetchActiveTechnicians()
            }
        } catch {
            errorMessage = "Erreur: \(error.localizedDescription)"
        }
    }
}
