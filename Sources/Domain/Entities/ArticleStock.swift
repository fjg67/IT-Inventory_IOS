import Foundation

struct ArticleStock: Identifiable, Equatable, Sendable {
    let id: String
    let articleId: UUID
    let siteId: String
    let quantity: Int
}
