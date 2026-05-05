import SwiftUI

struct AddPCView: View {
    private enum FormField: Hashable {
        case hostname
        case asset
        case brand
        case model
    }

    @Bindable var viewModel: PCViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var draft = PCCreateDraft()
    @State private var isSaving = false
    @State private var showScanner = false
    @State private var scanTarget: ScanTarget = .hostname
    @State private var manualScanCode = ""
    @State private var lastScannedCode = ""
    @FocusState private var focusedField: FormField?

    private enum ScanTarget {
        case hostname
        case asset
    }

    private struct DeviceOption: Identifiable, Hashable {
        let id: String
        let label: String
        let brand: String
        let model: String
    }

    @State private var selectedDeviceID: String = "siege_5440_non_tactile"

    var body: some View {
        ZStack {
            AppColor.pageGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    header

                    if !lastScannedCode.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColor.success)
                            Text("Code scanné: \(lastScannedCode)")
                                .font(.footnote)
                                .foregroundStyle(AppColor.textSecondary)
                            Spacer()
                        }
                    }

                    fieldCard(title: "Hostname") {
                        HStack(spacing: 10) {
                            TextField("Ex: KSAOPSTR2188", text: $draft.hostname)
                                .focused($focusedField, equals: .hostname)
                                .textInputAutocapitalization(.characters)

                            Button {
                                beginScan(for: .hostname)
                            } label: {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppColor.brand)
                                    .frame(width: 30, height: 30)
                                    .background(AppColor.brand.opacity(0.16))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Scanner pour hostname")
                        }
                    }

                    if !hostnameError.isEmpty {
                        validationMessage(hostnameError)
                    }

                    fieldCard(title: "Asset") {
                        HStack(spacing: 10) {
                            TextField("Ex: AO44XXXX", text: $draft.assetNumber)
                                .focused($focusedField, equals: .asset)
                                .textInputAutocapitalization(.characters)

                            Button {
                                beginScan(for: .asset)
                            } label: {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppColor.brand)
                                    .frame(width: 30, height: 30)
                                    .background(AppColor.brand.opacity(0.16))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Scanner pour asset")
                        }
                    }

                    if !assetError.isEmpty {
                        validationMessage(assetError)
                    }

                    fieldCard(title: "Statut initial") {
                        Menu {
                            ForEach(allowedCreateStatuses, id: \.self) { status in
                                Button {
                                    draft.status = status
                                } label: {
                                    HStack {
                                        Text(status.rawValue)
                                        if draft.status == status {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(draft.status.rawValue)
                                    .foregroundStyle(AppColor.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppColor.brand)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type de parc")
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)

                        Picker("Type de parc", selection: $draft.parcType) {
                            Text("Portable siege").tag("Portable siege")
                            Text("Portable agence").tag("Portable agence")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                    fieldCard(title: "Modèle autorisé") {
                        Menu {
                            ForEach(deviceOptions) { option in
                                Button(option.label) {
                                    applyDevice(option)
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedDeviceLabel)
                                    .foregroundStyle(AppColor.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppColor.brand)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    fieldCard(title: "Constructeur") {
                        Text(draft.brand)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(AppColor.textPrimary)
                    }

                    fieldCard(title: "Modèle") {
                        Text(draft.model)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(AppColor.textPrimary)
                    }

                    if !modelError.isEmpty {
                        validationMessage(modelError)
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
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    actionButtons
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 120)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationTitle("Ajouter un PC")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: draft.hostname) { _, newValue in
            let uppercased = newValue.uppercased()
            if uppercased != newValue {
                draft.hostname = uppercased
            }
        }
        .onChange(of: draft.assetNumber) { _, newValue in
            let normalized = normalizeAsset(newValue)
            if normalized != newValue {
                draft.assetNumber = normalized
            }
        }
        .onChange(of: draft.parcType) { _, _ in
            syncDeviceSelectionForParcType()
        }
        .onAppear {
            syncDeviceSelectionForParcType()
        }
        .sheet(isPresented: $showScanner) {
            scannerSheet
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button("Annuler") {
                dismiss()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppColor.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                save()
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark")
                        Text("Enregistrer")
                    }
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColor.brandGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!isFormValid || isSaving)
            .opacity(isFormValid && !isSaving ? 1.0 : 0.55)
        }
        .padding(AppSpacing.md)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nouveau matériel")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)
            Text("Renseigne les infos minimales pour créer le PC")
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
    }

    private func fieldCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)

            content()
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
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

    private func save() {
        guard !isSaving && isFormValid else { return }
        isSaving = true
        viewModel.errorMessage = nil
        Task {
            let success = await viewModel.createPC(draft: draft)
            await MainActor.run {
                isSaving = false
                if success { dismiss() }
            }
        }
    }

    private var hostnameError: String {
        let trimmed = draft.hostname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Le hostname est obligatoire." : ""
    }

    private var assetError: String {
        let trimmed = draft.assetNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Le numéro d'asset est obligatoire." }
        if !trimmed.hasPrefix("AO44") { return "L'asset doit commencer par AO44." }
        return ""
    }

    private var modelError: String {
        let trimmed = draft.model.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Le modèle est obligatoire." : ""
    }

    private var isFormValid: Bool {
        hostnameError.isEmpty && assetError.isEmpty && modelError.isEmpty
    }

    private var allowedCreateStatuses: [PCStatus] {
        [.hot, .rework, .machining, .available]
    }

    private func validationMessage(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(AppColor.warning)
        .padding(.horizontal, AppSpacing.xs)
    }

    private var deviceOptions: [DeviceOption] {
        if draft.parcType == "Portable siege" {
            return [
                DeviceOption(
                    id: "siege_5440_tactile",
                    label: "DELL Latitude 5440 tactile",
                    brand: "DELL",
                    model: "Latitude 5440 tactile"
                ),
                DeviceOption(
                    id: "siege_5440_non_tactile",
                    label: "DELL Latitude 5440 non tactile",
                    brand: "DELL",
                    model: "Latitude 5440 non tactile"
                )
            ]
        }

        return [
            DeviceOption(
                id: "agence_5550",
                label: "DELL Latitude 5550",
                brand: "DELL",
                model: "Latitude 5550"
            ),
            DeviceOption(
                id: "agence_elitebook",
                label: "HP Elitebook",
                brand: "HP",
                model: "Elitebook"
            )
        ]
    }

    private var selectedDeviceLabel: String {
        deviceOptions.first(where: { $0.id == selectedDeviceID })?.label ?? "Choisir"
    }

    private func applyDevice(_ option: DeviceOption) {
        selectedDeviceID = option.id
        draft.brand = option.brand
        draft.model = option.model
    }

    private func syncDeviceSelectionForParcType() {
        if let selected = deviceOptions.first(where: { $0.id == selectedDeviceID }) {
            applyDevice(selected)
            return
        }
        if let first = deviceOptions.first {
            applyDevice(first)
        }
    }

    private func normalizeAsset(_ raw: String) -> String {
        let upper = raw
            .uppercased()
            .replacingOccurrences(of: " ", with: "")

        guard !upper.isEmpty else { return "" }
        return upper.hasPrefix("AO44") ? upper : "AO44\(upper)"
    }

    private func applyScannedCode(_ code: String) {
        let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleaned.isEmpty else { return }

        switch scanTarget {
        case .hostname:
            draft.hostname = cleaned
        case .asset:
            draft.assetNumber = normalizeAsset(cleaned)
        }

        lastScannedCode = cleaned
        showScanner = false
    }

    private func beginScan(for target: ScanTarget) {
        scanTarget = target
        manualScanCode = ""
        showScanner = true
    }

    private var scannerSheet: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
#if targetEnvironment(simulator)
                LinearGradient(
                    colors: [Color.black.opacity(0.92), Color.black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 14) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(AppColor.brand)

                    Text("Caméra indisponible sur simulateur")
                        .font(.headline)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Saisis le code-barres pour remplir \(scanTarget == .hostname ? "Hostname" : "Asset").")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white.opacity(0.82))

                    TextField("Ex: AO44XXXX", text: $manualScanCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .foregroundStyle(AppColor.textPrimary)

                    Button("Valider le code") {
                        applyScannedCode(manualScanCode)
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColor.brandGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .disabled(manualScanCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(manualScanCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                }
                .padding(20)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 170)
#else
                BarcodeScannerView { code in
                    applyScannedCode(code)
                }
                .ignoresSafeArea()

                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                .ignoresSafeArea(edges: .bottom)
#endif

                VStack(spacing: 10) {
                    Text("Scanne un code-barres")
                        .font(.headline)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(scanTarget == .hostname ? "Le code remplira Hostname" : "Le code remplira Asset")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.8))

                    Button("Fermer") {
                        showScanner = false
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
