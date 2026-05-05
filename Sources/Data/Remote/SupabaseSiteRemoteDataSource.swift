import Foundation
import Supabase

protocol SiteRemoteDataSource: Sendable {
    func fetchAllSites() async throws -> [Site]
}

struct SupabaseSiteRemoteDataSource: SiteRemoteDataSource {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchAllSites() async throws -> [Site] {
        let items: [SiteDTO] = try await client
            .from("Site")
            .select("*")
            .execute()
            .value
        return items.map { $0.toDomain() }
    }
}
