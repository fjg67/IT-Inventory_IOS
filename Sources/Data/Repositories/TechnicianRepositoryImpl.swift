import Foundation

struct TechnicianRepositoryImpl: TechnicianRepository {
    private let remote: TechnicianRemoteDataSource

    init(remote: TechnicianRemoteDataSource) {
        self.remote = remote
    }

    func fetchActiveTechnicians() async throws -> [Technician] {
        try await remote.fetchActiveTechnicians()
    }

    func fetchActiveTechnicians(forSiteId siteId: String, parentSiteId: String?) async throws -> [Technician] {
        try await remote.fetchActiveTechnicians(forSiteId: siteId, parentSiteId: parentSiteId)
    }
}
