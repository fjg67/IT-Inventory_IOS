import Foundation

struct SiteRepositoryImpl: SiteRepository {
    private let remote: SiteRemoteDataSource

    init(remote: SiteRemoteDataSource) {
        self.remote = remote
    }

    func fetchAllSites() async throws -> [Site] {
        try await remote.fetchAllSites()
    }
}
