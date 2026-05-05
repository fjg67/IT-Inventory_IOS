import Foundation

protocol TechnicianRepository: Sendable {
    func fetchActiveTechnicians() async throws -> [Technician]
    func fetchActiveTechnicians(forSiteId: String, parentSiteId: String?) async throws -> [Technician]
}
