import Foundation

struct ArticleDTO: Decodable {
    let id: UUID
    let reference: String
    let name: String
    let descriptionText: String?
    let category: String?
    let brand: String?
    let model: String?
    let barcode: String?
    let unit: String?
    let minStock: Int?
    let imageUrl: String?
    let isArchived: Bool?
    let articleType: String?
    let codeFamille: String?
    let emplacement: String?
    let sousType: String?
    let createdAt: String
    let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case reference
        case name
        case descriptionText = "description"
        case category
        case brand
        case model
        case barcode
        case unit
        case minStock
        case imageUrl
        case isArchived
        case articleType
        case codeFamille
        case emplacement
        case sousType
        case createdAt
        case updatedAt
    }

    func toDomain() -> Article {
        Article(
            id: id,
            reference: reference,
            name: name,
            descriptionText: descriptionText,
            category: category,
            brand: brand,
            model: model,
            barcode: barcode,
            unit: unit,
            minStock: minStock ?? 0,
            imageURL: imageUrl.flatMap(URL.init(string:)),
            isArchived: isArchived ?? false,
            articleType: articleType,
            codeFamille: codeFamille,
            emplacement: emplacement,
            sousType: sousType,
            createdAt: DateParser.parse(createdAt) ?? .distantPast,
            updatedAt: DateParser.parse(updatedAt) ?? .distantPast
        )
    }
}
