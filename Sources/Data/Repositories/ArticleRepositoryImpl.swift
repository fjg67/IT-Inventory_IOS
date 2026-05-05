import Foundation

struct ArticleRepositoryImpl: ArticleRepository {
    private let remote: any ArticlesRemoteDataSource

    init(remote: any ArticlesRemoteDataSource) {
        self.remote = remote
    }

    func fetchArticles(search: String?) async throws -> [Article] {
        let all = try await remote.fetchArticles()

        let query = (search ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return all
        }

        let normalized = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        return all.filter { article in
            let fields = [
                article.reference,
                article.name,
                article.category ?? "",
                article.brand ?? "",
                article.barcode ?? ""
            ]

            return fields.joined(separator: " ")
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .contains(normalized)
        }
    }

    func fetchArticlesPage(offset: Int, limit: Int, includeArchived: Bool) async throws -> [Article] {
        try await remote.fetchArticlesPage(offset: offset, limit: limit, includeArchived: includeArchived)
    }

    func findArticle(barcode: String) async throws -> Article? {
        let query = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }

        // Scan can target barcode, reference (asset), or hostname (name).
        let all = try await remote.fetchArticles()
        let normalized = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        // 1) Exact barcode first.
        if let exactBarcode = all.first(where: {
            ($0.barcode ?? "").folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) == normalized
        }) {
            return exactBarcode
        }

        // 2) Exact reference (asset number).
        if let exactReference = all.first(where: {
            $0.reference.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) == normalized
        }) {
            return exactReference
        }

        // 3) Exact hostname (mapped to article name).
        if let exactName = all.first(where: {
            $0.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) == normalized
        }) {
            return exactName
        }

        // 4) Fallback to partial match (reference/name/barcode).
        return all.first(where: { article in
            let fields = [article.reference, article.name, article.barcode ?? ""]
            return fields.joined(separator: " ")
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .contains(normalized)
        })
    }

    func createArticle(input: NewArticleInput, photoJPEGData: Data?) async throws -> Article {
        try await remote.createArticle(input: input, photoJPEGData: photoJPEGData)
    }

    func updateArticlePCMetadata(
        articleID: UUID,
        descriptionText: String,
        codeFamille: String,
        isArchived: Bool
    ) async throws -> Article {
        try await remote.updateArticlePCMetadata(
            articleID: articleID,
            descriptionText: descriptionText,
            codeFamille: codeFamille,
            isArchived: isArchived
        )
    }

    func createPCArticle(
        hostname: String,
        assetNumber: String,
        statusDescription: String,
        codeFamille: String,
        parcType: String,
        brand: String,
        model: String
    ) async throws -> Article {
        try await remote.createPCArticle(
            hostname: hostname,
            assetNumber: assetNumber,
            statusDescription: statusDescription,
            codeFamille: codeFamille,
            parcType: parcType,
            brand: brand,
            model: model
        )
    }
}
