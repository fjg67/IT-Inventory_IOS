import Foundation

struct Article: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let reference: String
    let name: String
    let descriptionText: String?
    let category: String?
    let brand: String?
    let model: String?
    let barcode: String?
    let unit: String?
    let minStock: Int
    let imageURL: URL?
    let isArchived: Bool
    let articleType: String?
    let codeFamille: String?
    let emplacement: String?
    let sousType: String?
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID,
        reference: String,
        name: String,
        descriptionText: String? = nil,
        category: String? = nil,
        brand: String? = nil,
        model: String? = nil,
        barcode: String? = nil,
        unit: String? = nil,
        minStock: Int = 0,
        imageURL: URL? = nil,
        isArchived: Bool = false,
        articleType: String? = nil,
        codeFamille: String? = nil,
        emplacement: String? = nil,
        sousType: String? = nil,
        createdAt: Date = .distantPast,
        updatedAt: Date = .distantPast
    ) {
        self.id = id
        self.reference = reference
        self.name = name
        self.descriptionText = descriptionText
        self.category = category
        self.brand = brand
        self.model = model
        self.barcode = barcode
        self.unit = unit
        self.minStock = minStock
        self.imageURL = imageURL
        self.isArchived = isArchived
        self.articleType = articleType
        self.codeFamille = codeFamille
        self.emplacement = emplacement
        self.sousType = sousType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
