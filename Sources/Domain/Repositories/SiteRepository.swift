import Foundation

protocol SiteRepository: Sendable {
    func fetchAllSites() async throws -> [Site]
}
