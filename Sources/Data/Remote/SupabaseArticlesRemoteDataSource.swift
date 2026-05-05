import Foundation
import Supabase

protocol ArticlesRemoteDataSource: Sendable {
    func fetchArticles() async throws -> [Article]
    func fetchArticlesPage(offset: Int, limit: Int, includeArchived: Bool) async throws -> [Article]
    func findArticle(barcode: String) async throws -> Article?
    func createArticle(input: NewArticleInput, photoJPEGData: Data?) async throws -> Article
    func updateArticlePCMetadata(
        articleID: UUID,
        descriptionText: String,
        codeFamille: String,
        isArchived: Bool
    ) async throws -> Article
    func createPCArticle(
        hostname: String,
        assetNumber: String,
        statusDescription: String,
        codeFamille: String,
        parcType: String,
        brand: String,
        model: String
    ) async throws -> Article
}

struct SupabaseArticlesRemoteDataSource: ArticlesRemoteDataSource {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchArticles() async throws -> [Article] {
        let pageSize = 200
        var offset = 0
        var allArticles: [Article] = []

        while true {
            let page = try await fetchArticlesPage(offset: offset, limit: pageSize, includeArchived: true)
            allArticles.append(contentsOf: page)

            if page.count < pageSize {
                break
            }
            offset += pageSize
        }

        return allArticles
    }

    func fetchArticlesPage(offset: Int, limit: Int, includeArchived: Bool) async throws -> [Article] {
        let from = max(0, offset)
        let to = max(0, offset + max(1, limit) - 1)
        let cols = "id,reference,name,description,category,brand,model,barcode,unit,minStock,imageUrl,isArchived,articleType,codeFamille,emplacement,sousType,createdAt,updatedAt"

        let items: [ArticleDTO]
        if includeArchived {
            items = try await client
                .from("Article")
                .select(cols)
                .order("updatedAt", ascending: false)
                .range(from: from, to: to)
                .execute()
                .value
        } else {
            items = try await client
                .from("Article")
                .select(cols)
                .eq("isArchived", value: false)
                .order("updatedAt", ascending: false)
                .range(from: from, to: to)
                .execute()
                .value
        }

        return items.map { $0.toDomain() }
    }

    func findArticle(barcode: String) async throws -> Article? {
        let cols = "id,reference,name,description,category,brand,model,barcode,unit,minStock,imageUrl,isArchived,articleType,codeFamille,emplacement,sousType,createdAt,updatedAt"
        let items: [ArticleDTO] = try await client
            .from("Article")
            .select(cols)
            .eq("barcode", value: barcode)
            .limit(1)
            .execute()
            .value

        return items.first?.toDomain()
    }

    func createArticle(input: NewArticleInput, photoJPEGData: Data?) async throws -> Article {
        let uploadedImageURL = await uploadArticlePhotoIfNeeded(photoJPEGData)

        let payload = NewArticleDTO(
            reference: input.reference,
            name: input.name,
            description: input.descriptionText,
            category: input.category,
            brand: input.brand,
            model: input.model,
            barcode: input.barcode,
            imageUrl: uploadedImageURL,
            unit: input.unit,
            minStock: input.minStock,
            articleType: input.articleType,
            codeFamille: input.codeFamille,
            emplacement: input.emplacement,
            sousType: input.sousType,
            isArchived: false
        )

        let items: [ArticleDTO] = try await client
            .from("Article")
            .insert(payload)
            .select("id,reference,name,description,category,brand,model,barcode,unit,minStock,imageUrl,isArchived,articleType,codeFamille,emplacement,sousType,createdAt,updatedAt")
            .single()
            .execute()
            .value

        guard let created = items.first else {
            throw NSError(domain: "SupabaseArticlesRemoteDataSource", code: -3)
        }

        // Create initial stock record if siteId and quantity are provided
        if let siteId = input.siteId, input.stockActuel > 0 {
            let stockPayload = NewInitialStockDTO(
                articleId: created.id.uuidString,
                siteId: siteId,
                quantity: input.stockActuel
            )
            try? await client
                .from("ArticleStock")
                .insert(stockPayload)
                .execute()
        }

        return created.toDomain()
    }

    private func uploadArticlePhotoIfNeeded(_ photoJPEGData: Data?) async -> String? {
        guard let photoJPEGData else { return nil }

        let objectPath = "articles/\(UUID().uuidString).jpg"
        do {
            _ = try await client.storage
                .from("article-images")
                .upload(path: objectPath, file: photoJPEGData)

            let publicURL = try client.storage
                .from("article-images")
                .getPublicURL(path: objectPath)

            return publicURL.absoluteString
        } catch {
            // Keep article creation successful even if photo upload fails.
            return nil
        }
    }

    func updateArticlePCMetadata(
        articleID: UUID,
        descriptionText: String,
        codeFamille: String,
        isArchived: Bool
    ) async throws -> Article {
        let payload = ArticlePCMetadataUpdateDTO(
            description: descriptionText,
            codeFamille: codeFamille,
            isArchived: isArchived
        )

        let items: [ArticleDTO] = try await client
            .from("Article")
            .update(payload)
            .eq("id", value: articleID.uuidString.lowercased())
            .select("id,reference,name,description,category,brand,model,barcode,unit,minStock,imageUrl,isArchived,articleType,codeFamille,emplacement,sousType,createdAt,updatedAt")
            .execute()
            .value

        guard let updated = items.first else {
            throw NSError(
                domain: "SupabaseArticlesRemoteDataSource",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Mise à jour refusée — vérifiez les permissions de votre compte (RLS)."]
            )
        }
        return updated.toDomain()
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
        let payload = NewPCArticleDTO(
            reference: assetNumber,
            name: hostname,
            description: statusDescription,
            category: "PC",
            brand: brand,
            model: model,
            articleType: "PC",
            codeFamille: codeFamille,
            sousType: parcType,
            isArchived: false,
            minStock: 0,
            unit: "Pcs"
        )

        let items: [ArticleDTO] = try await client
            .from("Article")
            .insert(payload)
            .select("id,reference,name,description,category,brand,model,barcode,unit,minStock,imageUrl,isArchived,articleType,codeFamille,emplacement,sousType,createdAt,updatedAt")
            .single()
            .execute()
            .value

        guard let created = items.first else {
            throw NSError(domain: "SupabaseArticlesRemoteDataSource", code: -2)
        }
        return created.toDomain()
    }
}

private struct ArticlePCMetadataUpdateDTO: Encodable {
    let description: String
    let codeFamille: String
    let isArchived: Bool
}

private struct NewPCArticleDTO: Encodable {
    let reference: String
    let name: String
    let description: String
    let category: String
    let brand: String
    let model: String
    let articleType: String
    let codeFamille: String
    let sousType: String
    let isArchived: Bool
    let minStock: Int
    let unit: String
}

private struct NewArticleDTO: Encodable {
    let reference: String
    let name: String
    let description: String?
    let category: String?
    let brand: String?
    let model: String?
    let barcode: String?
    let imageUrl: String?
    let unit: String
    let minStock: Int
    let articleType: String?
    let codeFamille: String?
    let emplacement: String?
    let sousType: String?
    let isArchived: Bool
}

private struct NewInitialStockDTO: Encodable {
    let articleId: String
    let siteId: String
    let quantity: Int
}
