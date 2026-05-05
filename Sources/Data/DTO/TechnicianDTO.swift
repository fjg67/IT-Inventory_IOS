import Foundation

struct TechnicianDTO: Decodable {
    let id: String
    let technicianId: String
    let name: String
    let role: String
    let isActive: Bool?

    func toDomain() -> Technician {
        Technician(id: id, technicianId: technicianId, name: name, role: role)
    }
}
