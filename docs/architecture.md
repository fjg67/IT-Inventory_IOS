# Proposed folder architecture

The project is organized by clean architecture boundaries and feature modules.

- App
  - App entrypoint and app lifecycle glue
- Core
  - Design system, configuration, shared utilities, DI container
- Domain
  - Entities, use cases, repository protocols, typed errors
- Data
  - DTOs, repository implementations, remote clients, local store
- Features
  - Feature modules with MVVM: Dashboard, Articles, Scan, PC, Movements, Settings, Auth
- Resources
  - App plist, assets, localized strings
- supabase
  - SQL migrations, policy scripts, optional seed data and edge functions

## Concrete source tree target

- Sources/App
- Sources/Core/Config
- Sources/Core/DI
- Sources/Core/DesignSystem
- Sources/Domain/Entities
- Sources/Domain/UseCases
- Sources/Domain/Repositories
- Sources/Domain/Errors
- Sources/Data/DTO
- Sources/Data/Remote
- Sources/Data/Local
- Sources/Data/Repositories
- Sources/Features/Auth
- Sources/Features/Dashboard
- Sources/Features/Articles
- Sources/Features/Scan
- Sources/Features/PC
- Sources/Features/Movements
- Sources/Features/Settings
- Resources
- Config
- supabase/migrations
- Tests/Unit
- Tests/Integration
- Tests/UI
