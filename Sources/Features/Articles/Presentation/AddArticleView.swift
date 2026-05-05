import SwiftUI
import PhotosUI
import UIKit

struct AddArticleView: View {
    @State private var viewModel: AddArticleViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showMainInfo = true
    @State private var showStockInfo = true
    @State private var showOptionalInfo = false
    @State private var animateIn = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoImage: UIImage?
    @State private var showCameraPicker = false

    let onCreated: () -> Void

    init(viewModel: AddArticleViewModel, onCreated: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onCreated = onCreated
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.pageGradient.ignoresSafeArea()
                ambientBackdrop

                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        header
                        visualInspirationStrip
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 10)

                        collapsibleSection(
                            title: "🧾 Informations principales",
                            subtitle: "Champs obligatoires",
                            isExpanded: $showMainInfo
                        ) {
                            fieldCard(title: "🏷️ Reference") {
                                TextField("Ex: 1200017", text: $viewModel.reference)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .keyboardType(.asciiCapable)
                            }

                            fieldCard(title: "📝 Nom") {
                                TextField("Ex: Câble RJ-45 2 mètres", text: $viewModel.name)
                                    .autocorrectionDisabled()
                            }

                            fieldCard(title: "🧬 Code famille") {
                                Menu {
                                    ForEach(Self.codeFamilleOptions, id: \.self) { value in
                                        Button(value) { viewModel.codeFamille = value }
                                    }
                                } label: {
                                    menuLabel(viewModel.codeFamille, placeholder: "Choisir un code")
                                }
                            }

                            fieldCard(title: "🗂️ Famille") {
                                Menu {
                                    ForEach(Self.categoryOptions, id: \.self) { value in
                                        Button(value) { viewModel.category = value }
                                    }
                                } label: {
                                    menuLabel(viewModel.category, placeholder: "Choisir une famille")
                                }
                            }

                            fieldCard(title: "🧩 Type") {
                                Menu {
                                    ForEach(Self.typeOptions, id: \.self) { value in
                                        Button(value) { viewModel.articleType = value }
                                    }
                                } label: {
                                    menuLabel(viewModel.articleType, placeholder: "Choisir un type")
                                }
                            }

                            fieldCard(title: "🔎 Sous-type") {
                                Menu {
                                    ForEach(Self.subTypeOptions, id: \.self) { value in
                                        Button(value) { viewModel.sousType = value }
                                    }
                                } label: {
                                    menuLabel(viewModel.sousType, placeholder: "Choisir un sous-type")
                                }
                            }

                            fieldCard(title: "🏢 Marque") {
                                Menu {
                                    ForEach(Self.brandOptions, id: \.self) { value in
                                        Button(value) { viewModel.brand = value }
                                    }
                                } label: {
                                    menuLabel(viewModel.brand, placeholder: "Choisir une marque")
                                }
                            }
                        }

                        collapsibleSection(
                            title: "📦 Stock & emplacement",
                            subtitle: "Gestion du stock",
                            isExpanded: $showStockInfo
                        ) {
                            fieldCard(title: "📍 Emplacement (optionnel)") {
                                Menu {
                                    ForEach(Self.emplacementOptions, id: \.self) { value in
                                        Button(value) { viewModel.emplacement = value }
                                    }
                                } label: {
                                    menuLabel(viewModel.emplacement, placeholder: "Aucun emplacement")
                                }
                            }

                            fieldCard(title: "📊 Quantité initiale") {
                                TextField("0", text: $viewModel.stockActuelText)
                                    .keyboardType(.numberPad)
                            }

                            fieldCard(title: "⚠️ Seuil d'alerte") {
                                TextField("5", text: $viewModel.minStockText)
                                    .keyboardType(.numberPad)
                            }
                        }

                        collapsibleSection(
                            title: "✨ Détails optionnels",
                            subtitle: "Compléments visuels",
                            isExpanded: $showOptionalInfo
                        ) {
                            fieldCard(title: "🖼️ Photo (optionnel)") {
                                VStack(alignment: .leading, spacing: 10) {
                                    photoPreview

                                    HStack(spacing: 10) {
                                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                            actionPill(title: "Galerie", icon: "photo.on.rectangle")
                                        }

                                        Button {
                                            showCameraPicker = true
                                        } label: {
                                            actionPill(title: "Caméra", icon: "camera")
                                        }
                                        .buttonStyle(.plain)

                                        if selectedPhotoImage != nil {
                                            Button {
                                                selectedPhotoItem = nil
                                                selectedPhotoImage = nil
                                            } label: {
                                                actionPill(title: "Supprimer", icon: "trash")
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }

                            fieldCard(title: "📶 Code-barres (optionnel)") {
                                TextField("Ex: 3660619400017", text: $viewModel.barcode)
                                    .keyboardType(.asciiCapable)
                                    .autocorrectionDisabled()
                            }

                            fieldCard(title: "🗒️ Description (optionnel)") {
                                TextField("Détails utiles", text: $viewModel.descriptionText, axis: .vertical)
                                    .lineLimit(3...6)
                            }
                        }

                        if let error = viewModel.errorMessage, !error.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(AppColor.danger)
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(AppColor.textPrimary)
                                Spacer()
                            }
                            .padding(AppSpacing.md)
                            .background(AppColor.danger.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 8)
                }
            }
            .navigationTitle("Ajouter un article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            let saved = await viewModel.submit(photoJPEGData: selectedPhotoImage?.jpegData(compressionQuality: 0.82))
                            if saved {
                                onCreated()
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(AppColor.textPrimary)
                        } else {
                            Text("Enregistrer")
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundStyle(viewModel.isFormValid ? AppColor.brand : AppColor.textTertiary)
                    .disabled(!viewModel.isFormValid || viewModel.isSaving)
                }
            }
            .onChange(of: viewModel.reference) {
                viewModel.sanitizeReference()
            }
            .onChange(of: selectedPhotoItem) {
                guard let selectedPhotoItem else { return }
                Task {
                    if let data = try? await selectedPhotoItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedPhotoImage = image
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                    animateIn = true
                }
            }
            .sheet(isPresented: $showCameraPicker) {
                CameraImagePicker(image: $selectedPhotoImage)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColor.brandGradient)
                    .frame(width: 64, height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                Text("📦")
                    .font(.system(size: 30))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Nouvel article")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(AppColor.textPrimary)
                Text("Renseigne les informations principales pour l'ajouter au catalogue.")
                    .font(.footnote)
                    .foregroundStyle(AppColor.textSecondary)
            }

            VStack(spacing: 4) {
                Text(currentHero.emoji)
                    .font(.system(size: 24))
                Text(currentHero.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .background(AppColor.surface.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ambientBackdrop: some View {
        ZStack {
            Circle()
                .fill(AppColor.brand.opacity(0.2))
                .frame(width: 260)
                .blur(radius: 90)
                .offset(x: -130, y: -280)

            Ellipse()
                .fill(AppColor.accent.opacity(0.14))
                .frame(width: 300, height: 220)
                .blur(radius: 95)
                .offset(x: 120, y: -200)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var visualInspirationStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🎨 Aperçu visuel")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text("Style iOS")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }

            HStack(spacing: 10) {
                inspirationCard(icon: currentHero.icon, emoji: currentHero.emoji, title: currentHero.title)
                inspirationCard(icon: "keyboard", emoji: "⌨️", title: "Clavier")
                inspirationCard(icon: "headphones", emoji: "🎧", title: "Audio")
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(AppColor.card.opacity(0.62))
                .overlay(.ultraThinMaterial.opacity(0.36))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func inspirationCard(icon: String, emoji: String, title: String) -> some View {
        VStack(spacing: 7) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppColor.surface, AppColor.card],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 74)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColor.brand)

                Text(emoji)
                    .font(.system(size: 16))
                    .padding(4)
                    .background(Color.white.opacity(0.76))
                    .clipShape(Circle())
                    .offset(x: 6, y: 6)
            }

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var photoPreview: some View {
        Group {
            if let selectedPhotoImage {
                Image(uiImage: selectedPhotoImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColor.surface)
                    .frame(height: 96)
                    .overlay {
                        VStack(spacing: 6) {
                            Image(systemName: "photo")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(AppColor.textSecondary)
                            Text("Ajoute une photo du produit")
                                .font(.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
            }
        }
    }

    nonisolated private func actionPill(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(AppColor.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AppColor.surface)
        .clipShape(Capsule())
    }

    private func collapsibleSection<Content: View>(
        title: String,
        subtitle: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppColor.textPrimary)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColor.brand)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppColor.surface.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                VStack(spacing: AppSpacing.sm) {
                    content()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func fieldCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)

            content()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func menuLabel(_ value: String, placeholder: String) -> some View {
        HStack {
            Text(value.isEmpty ? placeholder : value)
                .foregroundStyle(value.isEmpty ? AppColor.textTertiary : AppColor.textPrimary)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppColor.brand)
        }
    }

    private var currentHero: (icon: String, emoji: String, title: String) {
        let normalized = (viewModel.articleType.isEmpty ? viewModel.category : viewModel.articleType)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        if normalized.contains("clavier") {
            return ("keyboard", "⌨️", "Clavier")
        }
        if normalized.contains("souris") {
            return ("computermouse", "🖱️", "Souris")
        }
        if normalized.contains("casque") || normalized.contains("audio") {
            return ("headphones", "🎧", "Audio")
        }
        if normalized.contains("reseau") || normalized.contains("cable") {
            return ("cable.connector", "🔌", "Câble")
        }
        return ("shippingbox.fill", "📦", "Article")
    }

    private static let codeFamilleOptions = ["10", "11", "12", "13", "14", "15", "16", "17", "50"]
    private static let categoryOptions = ["Accessoires", "Audio", "Cable", "Chargeur", "Electrique", "Ergonomie", "Kit"]
    private static let typeOptions = ["Souris", "Clavier", "Dock", "HUB USB", "Casque", "Reseau", "Alimentation"]
    private static let subTypeOptions = ["Filaire", "Sans fil", "Agence", "Siege", "2m", "3m", "Generique"]
    private static let brandOptions = ["DELL", "Cherry", "StarTec", "Generique", "Plantronics", "HP", "Fujitsu"]
    private static let emplacementOptions = [
        "Stock 5 - R2E3",
        "Stock 5 - R2E4",
        "Stock 5 - R4E3",
        "Stock 8 - Armoire",
        "Stock 8 - Tiroir"
    ]
}

private struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraImagePicker

        init(parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let picked = info[.originalImage] as? UIImage {
                parent.image = picked
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
}
