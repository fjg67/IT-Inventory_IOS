# Manual QA checklist (Phase 1)

## App launch and navigation

- App launches without crash on iPhone simulator
- Tab bar displays 6 modules: Accueil, Articles, Scan, PC, Mouvements, Reglages
- Each tab opens its own navigation stack and title
- App remains portrait-only

## Visual and UX baseline

- Dashboard shows greeting, KPI cards, trend chart, XXL Scan CTA
- Card spacing and typography are consistent
- Light mode and dark mode both readable
- Dynamic Type scales without clipping critical text

## Accessibility baseline

- VoiceOver can focus tab items and major controls
- XXL scan button has accessibility label
- Contrast remains acceptable on KPI cards and chart

## Configuration and security baseline

- No Supabase secret hardcoded in Swift source
- Config/Secrets.xcconfig is local-only and git-ignored
- Missing secrets in debug does not hard-crash unit test execution
- Release config remains strict on missing env values

## Database and policies baseline

- Supabase migration 001 applies cleanly
- Supabase migration 002 applies cleanly
- RLS enabled on all sensitive tables
- Role-based access behavior validated for technicien/superviseur/admin

## Test baseline

- Unit tests run successfully from scheme ItInventory
- FetchArticlesUseCaseTests passes
