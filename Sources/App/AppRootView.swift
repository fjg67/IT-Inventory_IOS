import SwiftUI
import UIKit
import Network

struct AppRootView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var connectivityMonitor = ConnectivityMonitor()
    @State private var biometricLockViewModel = BiometricLockViewModel()

    var body: some View {
        ZStack {
            Group {
                switch container.authViewModel.status {
                case .checking:
                    ProgressView("Verification de session...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppColor.page)
                case .unauthenticated:
                    LoginView(viewModel: container.authViewModel)
                case .authenticated:
                    if container.isRestoringSessionContext {
                        ProgressView("Restauration du contexte...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(AppColor.page)
                    } else if container.selectedSite == nil {
                        SiteSelectionView(viewModel: container.makeSiteSelectionViewModel())
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else if container.selectedTechnician == nil {
                        TechnicianSelectionView(
                            viewModel: container.makeTechnicianSelectionViewModel(
                                siteId: container.selectedSite?.id,
                                parentSiteId: container.selectedSite?.parentSiteId
                            ),
                            site: container.selectedSite!,
                            onBack: {
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                    container.selectedSite = nil
                                }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    } else {
                        RootTabView()
                    }
                }
            }

            if biometricLockViewModel.isLocked && isAuthenticated {
                biometricOverlay
            }

            if !connectivityMonitor.isConnected {
                offlineOverlay
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.page.ignoresSafeArea())
        .preferredColorScheme(container.appTheme.preferredColorScheme)
        .task {
            connectivityMonitor.start()
            container.authViewModel.bootstrapIfNeeded()
        }
        .onChange(of: container.authViewModel.status) { _, status in
            switch status {
            case .authenticated:
                Task { @MainActor in
                    await container.restoreSessionContextIfNeeded()
                }
            case .checking, .unauthenticated:
                container.resetSessionContextRestoreState()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard isAuthenticated else {
                biometricLockViewModel.reset()
                return
            }

            guard container.authViewModel.isBiometricEnabled else {
                biometricLockViewModel.reset()
                return
            }

            switch phase {
            case .inactive, .background:
                biometricLockViewModel.lock()
            case .active:
                biometricLockViewModel.unlockIfNeeded()
            @unknown default:
                break
            }
        }
        .onChange(of: isAuthenticated) { _, authenticated in
            if !authenticated {
                biometricLockViewModel.reset()
                container.selectedSite = nil
                container.selectedTechnician = nil
            }
        }
        .onChange(of: container.authViewModel.isBiometricEnabled) { _, enabled in
            if !enabled {
                biometricLockViewModel.reset()
            }
        }
    }

    private var biometricOverlay: some View {
        ZStack {
            // Blur backdrop
            AppColor.page.opacity(0.85)
                .ignoresSafeArea()
                .background(.ultraThinMaterial.opacity(0.6))

            VStack(spacing: AppSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(AppColor.brandGradient)
                        .frame(width: 80, height: 80)
                        .shadow(color: AppColor.brand.opacity(0.5), radius: 20, x: 0, y: 8)
                    Image(systemName: "faceid")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary)
                }

                VStack(spacing: 6) {
                    Text("Application Verrouillée")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Utilisez Face ID / Touch ID pour reprendre.")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if let errorMessage = biometricLockViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(AppColor.danger)
                        .multilineTextAlignment(.center)
                }

                Button {
                    biometricLockViewModel.unlock()
                } label: {
                    HStack(spacing: 8) {
                        if biometricLockViewModel.isUnlocking {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "lock.open.fill")
                            Text("Déverrouiller")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(width: 200)
                    .frame(height: 50)
                    .foregroundStyle(AppColor.textPrimary)
                    .background(AppColor.brandGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .shadow(color: AppColor.brand.opacity(0.45), radius: 14, x: 0, y: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(AppSpacing.xl)
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 40, x: 0, y: 16)
            .padding(.horizontal, AppSpacing.xl)
        }
    }

    private var offlineOverlay: some View {
        ZStack {
            AppColor.pageGradient
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppColor.warning.opacity(0.18))
                        .frame(width: 110, height: 110)
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(AppColor.warning)
                }

                VStack(spacing: 8) {
                    Text("Connexion Internet requise")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Pour continuer sur l'application, connectez-vous a Internet puis revenez ici.")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: AppSpacing.sm) {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Ouvrir les reglages")
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(AppColor.textPrimary)
                            .background(AppColor.brandGradient)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Text("L'ecran disparait automatiquement des que la connexion revient.")
                        .font(.caption)
                        .foregroundStyle(AppColor.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 320)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.xl)
        }
    }

    private var isAuthenticated: Bool {
        if case .authenticated = container.authViewModel.status {
            return true
        }
        return false
    }
}

@MainActor
final class ConnectivityMonitor: ObservableObject {
    @Published private(set) var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ConnectivityMonitor.queue")
    private var isStarted = false

    func start() {
        guard !isStarted else { return }
        isStarted = true

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
