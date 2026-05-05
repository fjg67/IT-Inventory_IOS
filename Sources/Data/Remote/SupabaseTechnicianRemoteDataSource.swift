import Foundation
import Supabase

protocol TechnicianRemoteDataSource: Sendable {
    func fetchActiveTechnicians() async throws -> [Technician]
    func fetchActiveTechnicians(forSiteId: String, parentSiteId: String?) async throws -> [Technician]
}

struct SupabaseTechnicianRemoteDataSource: TechnicianRemoteDataSource {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchActiveTechnicians() async throws -> [Technician] {
        let items: [TechnicianDTO] = try await client
            .from("User")
            .select("id,technicianId,name,role,isActive")
            .eq("isActive", value: true)
            .execute()
            .value
        return items
            .map { $0.toDomain() }
            .filter { $0.name != "SUPPRIMÉ" }
            .sorted { $0.name < $1.name }
    }

    func fetchActiveTechnicians(forSiteId siteId: String, parentSiteId: String?) async throws -> [Technician] {
        // Fetch technicians assigned directly to this site
        let bySite: [TechnicianDTO] = try await client
            .from("User")
            .select("id,technicianId,name,role,isActive")
            .eq("isActive", value: true)
            .eq("siteId", value: siteId)
            .execute()
            .value
        // If no direct technicians, fall back to the parent site's pool
        var pool = bySite
        if pool.isEmpty, let parentSiteId {
            pool = try await client
                .from("User")
                .select("id,technicianId,name,role,isActive")
                .eq("isActive", value: true)
                .eq("siteId", value: parentSiteId)
                .execute()
                .value
        }
        // Always add superviseurs (they appear on all sites)
        let supervisors: [TechnicianDTO] = try await client
            .from("User")
            .select("id,technicianId,name,role,isActive")
            .eq("isActive", value: true)
            .eq("role", value: "superviseur")
            .execute()
            .value
        let combined = (pool + supervisors)
            .reduce(into: [String: TechnicianDTO]()) { $0[$1.id] = $1 }
            .values
        return combined
            .map { $0.toDomain() }
            .filter { $0.name != "SUPPRIMÉ" }
            .sorted { $0.name < $1.name }
    }
}
