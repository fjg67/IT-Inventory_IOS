import Foundation

@Observable
final class AddArticleViewModel: @unchecked Sendable {
    var reference: String = ""
    var name: String = ""
    var codeFamille: String = ""
    var category: String = ""
    var articleType: String = ""
    var sousType: String = ""
    var brand: String = ""
    var emplacement: String = ""
    var minStockText: String = "5"
    var stockActuelText: String = "0"
    var descriptionText: String = ""
    var barcode: String = ""

    var isSaving = false
    var errorMessage: String?
    var didSucceed = false

    private let createArticleUseCase: CreateArticleUseCase
    private let siteId: String?

    init(createArticleUseCase: CreateArticleUseCase, siteId: String?) {
        self.createArticleUseCase = createArticleUseCase
        self.siteId = siteId
    }

    var isFormValid: Bool {
        referenceTrimmed.count >= 7
            && nameTrimmed.count >= 2
            && minStockValue >= 0
            && !codeFamilleTrimmed.isEmpty
            && !categoryTrimmed.isEmpty
            && !articleTypeTrimmed.isEmpty
            && !sousTypeTrimmed.isEmpty
            && !brandTrimmed.isEmpty
    }

    var minStockValue: Int {
        Int(minStockText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? -1
    }

    var stockActuelValue: Int {
        Int(stockActuelText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    func sanitizeReference() {
        let normalized = reference.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized != reference {
            reference = normalized
        }
    }

    func submit(photoJPEGData: Data?) async -> Bool {
        guard isFormValid else {
            errorMessage = "Complète les champs obligatoires."
            return false
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let input = NewArticleInput(
            reference: referenceTrimmed,
            name: nameTrimmed,
            descriptionText: optional(descriptionTrimmed),
            category: optional(categoryTrimmed),
            brand: optional(brandTrimmed),
            model: nil,
            barcode: optional(barcodeTrimmed),
            unit: "Pcs",
            minStock: minStockValue,
            stockActuel: stockActuelValue,
            siteId: siteId,
            articleType: optional(articleTypeTrimmed),
            codeFamille: optional(codeFamilleTrimmed),
            emplacement: optional(emplacementTrimmed),
            sousType: optional(sousTypeTrimmed)
        )

        do {
            _ = try await createArticleUseCase.execute(input, photoJPEGData: photoJPEGData)
            didSucceed = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private var referenceTrimmed: String {
        reference.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var nameTrimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var codeFamilleTrimmed: String {
        codeFamille.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var categoryTrimmed: String {
        category.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var articleTypeTrimmed: String {
        articleType.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sousTypeTrimmed: String {
        sousType.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var brandTrimmed: String {
        brand.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var emplacementTrimmed: String {
        emplacement.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var descriptionTrimmed: String {
        descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var barcodeTrimmed: String {
        barcode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func optional(_ value: String) -> String? {
        value.isEmpty ? nil : value
    }
}
