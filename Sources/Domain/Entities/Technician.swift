import Foundation

struct Technician: Identifiable, Equatable, Sendable {
    let id: String
    let technicianId: String
    let name: String
    let role: String

    /// Initials from each word of the name (up to 3 letters)
    var initials: String {
        name.split(separator: " ")
            .prefix(3)
            .compactMap { $0.first.map { String($0).uppercased() } }
            .joined()
    }

    var displayRole: String {
        switch role.lowercased() {
        case "technician": return "Technicien"
        case "superviseur": return "Superviseur"
        case "admin": return "Admin"
        default: return role
        }
    }
}
