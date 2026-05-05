# Phase 2 report

## 1) What was implemented

- Supabase SDK integrated through Swift Package Manager
- Auth architecture added:
  - Domain entity: AuthSession
  - Repository protocol + implementation
  - Use cases: restore session, sign-in, sign-out
- Remote auth datasource using Supabase Auth email/password
- Keychain-backed secure session store
- AuthViewModel with robust state handling
- Login screen (email/password) with loading and error states
- App root routing based on auth state
- Logout action available in settings

## 2) Why key technical choices were made

- Repository + use-case boundaries preserve clean architecture and testability
- Keychain store uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for stricter local security
- Root auth gate avoids invalid UI states and ensures deterministic startup
- Strict URL validation prevents unresolved build variables from crashing Supabase client boot

## 3) Exact files created or modified

Created:
- Sources/Domain/Entities/AuthSession.swift
- Sources/Domain/Repositories/AuthRepository.swift
- Sources/Domain/UseCases/RestoreSessionUseCase.swift
- Sources/Domain/UseCases/SignInUseCase.swift
- Sources/Domain/UseCases/SignOutUseCase.swift
- Sources/Core/Security/KeychainClient.swift
- Sources/Data/Local/SecureSessionStore.swift
- Sources/Data/Remote/SupabaseAuthRemoteDataSource.swift
- Sources/Data/Repositories/AuthRepositoryImpl.swift
- Sources/Data/Repositories/AuthErrorMapper.swift
- Sources/Features/Auth/Presentation/AuthViewModel.swift
- Sources/Features/Auth/Presentation/LoginView.swift
- Sources/App/AppRootView.swift

Modified:
- project.yml
- Sources/Data/Remote/SupabaseClientProvider.swift
- Sources/Core/DI/AppContainer.swift
- Sources/App/ItInventoryApp.swift
- Sources/Core/Config/AppEnvironment.swift
- Sources/Features/Settings/Presentation/SettingsView.swift
- README.md

## 4) Build status and run steps

Build status:
- App build: success
- Unit tests: success

Run steps:
1. Ensure `Config/Secrets.xcconfig` exists with valid values
2. `xcodegen generate`
3. `open ItInventory.xcodeproj`
4. Run target `ItInventory` on iPhone simulator

CLI verification commands:
- `xcodebuild -project ItInventory.xcodeproj -scheme ItInventory -destination 'generic/platform=iOS Simulator' build`
- `xcodebuild -project ItInventory.xcodeproj -scheme ItInventory -destination 'platform=iOS Simulator,name=iPhone 17' test`

## 5) Known risks and next actions

Known risks:
- Auth currently supports sign-in/sign-out only (no sign-up/reset UI)
- Session refresh and conflict management are not yet tied to offline sync engine
- Business modules still use placeholder data

Next actions:
- Implement feature repositories backed by Supabase PostgREST
- Add biometric quick unlock (Face ID) tied to session restore policy
- Add offline mutation queue and retry/backoff engine
- Add integration tests for auth repository and keychain store
