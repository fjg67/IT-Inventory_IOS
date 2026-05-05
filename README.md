# ItInventory iPhone App (SwiftUI + Supabase)

Production-focused iPhone inventory app scaffold, built for iOS 17+, Swift 6, and SwiftUI-first architecture.

## Phase 1 + 2 status

Implemented in this iteration:
- project scaffolding with XcodeGen
- iPhone-only app base and portrait orientation lock
- design system tokens and reusable card/scan components
- NavigationStack + TabView skeleton for all required modules
- premium Dashboard foundation with KPI cards and Apple Charts trend
- environment config strategy using xcconfig without hardcoded secrets
- Supabase schema migration and RLS policy migration files
- Supabase Swift SDK integration in app target
- Auth domain/data layers (repository, use cases, remote datasource)
- Keychain secure session storage for session payload
- Login UI flow with robust error states
- Auth-aware app root routing (session check -> login or main tabs)
- Logout action exposed in settings

## Quick start

1. Install Xcode 16+
2. Install XcodeGen:
   - brew install xcodegen
3. Create local secret config:
   - cp Config/Secrets.xcconfig.template Config/Secrets.xcconfig
   - fill SUPABASE_URL and SUPABASE_ANON_KEY
4. Generate project:
   - xcodegen generate
5. Open in Xcode:
   - open ItInventory.xcodeproj
6. Select target ItInventory and run on an iPhone simulator

## Apply Supabase migrations

Use Supabase CLI in project root:

1. supabase login
2. supabase link --project-ref YOUR_PROJECT_REF
3. supabase db push

## Build commands

After generating project:
- xcodebuild -project ItInventory.xcodeproj -scheme ItInventory -destination 'generic/platform=iOS Simulator' build
- xcodebuild -project ItInventory.xcodeproj -scheme ItInventory -destination 'platform=iOS Simulator,name=iPhone 17' test

## Current limitations (expected after Phase 2)

- Scanner camera integration is not implemented yet
- Offline queue and sync engine are not implemented yet
- Notification and biometric runtime integrations are not implemented yet
- Auth sign-up and password reset screens are not implemented yet
- Data repositories for Articles/Movements/Stock are not connected to Supabase yet

## Next phase

Phase 3 will implement business feature data flows (Dashboard, Articles, Mouvements, Scan) on real repositories with offline-first behavior.
