import Foundation

struct ArticleStockDTO: Decodable {
    let id: String
    let articleId: UUID
    let siteId: String
    let quantity: Int

    func toDomain() -> ArticleStock {
        ArticleStock(id: id, articleId: articleId, siteId: siteId, quantity: quantity)
    }
}
