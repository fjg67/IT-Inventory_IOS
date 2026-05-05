import Foundation

struct NewArticleInput: Sendable {
    let reference: String
    let name: String
    let descriptionText: String?
    let category: String?
    let brand: String?
    let model: String?
    let barcode: String?
    let unit: String
    let minStock: Int
    let stockActuel: Int
    let siteId: String?
    let articleType: String?
    let codeFamille: String?
    let emplacement: String?
    let sousType: String?
}
