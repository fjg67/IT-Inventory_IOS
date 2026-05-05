import Foundation

struct SiteDTO: Decodable {
    let id: String
    let name: String
    let address: String?
    let isActive: Bool?
    let parentSiteId: String?
    let edsNumber: String?
    let createdAt: String?
    let updatedAt: String?

    func toDomain() -> Site {
        Site(id: id, name: name, isActive: isActive ?? true, parentSiteId: parentSiteId)
    }
}

