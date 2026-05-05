# Supabase schema and RLS plan

## Scope

Primary tables for inventory lifecycle:
- profiles
- sites
- articles
- stock_levels
- mouvements
- alerts
- devices
- app_settings

All tables include audit and sync metadata fields where relevant:
- id uuid
- created_at
- updated_at
- created_by
- updated_by
- is_deleted
- version
- last_synced_at

## Auth model

- Supabase Auth email/password
- profile row keyed by auth.users.id
- role enum: technicien, superviseur, admin
- site scoping via profiles.site_id

## RLS strategy

RLS is enabled on all app tables. Policies are role and scope aware.

- technicien:
  - read own-site operational data
  - insert mouvements for own site
  - no direct write to articles, sites, stock_levels
- superviseur:
  - read and write operational tables
  - full access across sites for management workflows
- admin:
  - full access and cross-user visibility

Helper SQL functions centralize policy logic:
- current_app_role()
- current_site_id()
- is_admin()
- is_superviseur_or_admin()

## Security posture

- No service role key in iOS client
- anon key only on device
- least privilege enforced by RLS
- all sensitive writes validated with with check predicates

## Realtime and edge functions

- Realtime optional for dashboard counters and movement updates
- Edge functions reserved for high-trust workflows only (bulk reconciliation, privileged reports)
