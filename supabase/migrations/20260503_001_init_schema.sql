begin;

create extension if not exists pgcrypto;

create type public.app_role as enum ('technicien', 'superviseur', 'admin');
create type public.movement_type as enum ('entree', 'sortie', 'consultation', 'ajustement');

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.sites (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text not null unique,
  address text,
  is_deleted boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  created_by uuid,
  updated_by uuid,
  version bigint not null default 1,
  last_synced_at timestamptz
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text,
  role public.app_role not null default 'technicien',
  site_id uuid references public.sites(id),
  is_deleted boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  created_by uuid,
  updated_by uuid,
  version bigint not null default 1,
  last_synced_at timestamptz
);

create table if not exists public.articles (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  barcode text unique,
  name text not null,
  description text,
  category text,
  unit text not null default 'piece',
  reorder_threshold integer not null default 0,
  is_deleted boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id),
  version bigint not null default 1,
  last_synced_at timestamptz
);

create table if not exists public.stock_levels (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.sites(id),
  article_id uuid not null references public.articles(id),
  quantity integer not null default 0,
  min_threshold integer not null default 0,
  is_deleted boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id),
  version bigint not null default 1,
  last_synced_at timestamptz,
  unique(site_id, article_id)
);

create table if not exists public.mouvements (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.sites(id),
  article_id uuid not null references public.articles(id),
  movement_type public.movement_type not null,
  quantity integer not null,
  note text,
  performed_at timestamptz not null default timezone('utc', now()),
  is_deleted boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  created_by uuid not null references auth.users(id),
  updated_by uuid references auth.users(id),
  version bigint not null default 1,
  last_synced_at timestamptz
);

create table if not exists public.alerts (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.sites(id),
  article_id uuid references public.articles(id),
  title text not null,
  message text not null,
  severity text not null check (severity in ('info', 'warning', 'critical')),
  is_read boolean not null default false,
  is_deleted boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id),
  version bigint not null default 1,
  last_synced_at timestamptz
);

create table if not exists public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  apns_token text,
  device_name text,
  os_version text,
  app_version text,
  push_enabled boolean not null default false,
  is_deleted boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  created_by uuid,
  updated_by uuid,
  version bigint not null default 1,
  last_synced_at timestamptz
);

create table if not exists public.app_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  preferred_theme text not null default 'system' check (preferred_theme in ('light', 'dark', 'system')),
  biometric_enabled boolean not null default false,
  notifications_enabled boolean not null default true,
  is_deleted boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  created_by uuid,
  updated_by uuid,
  version bigint not null default 1,
  last_synced_at timestamptz
);

create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_profiles_site_id on public.profiles(site_id);
create index if not exists idx_articles_sku on public.articles(sku);
create index if not exists idx_stock_levels_site_article on public.stock_levels(site_id, article_id);
create index if not exists idx_mouvements_site_performed_at on public.mouvements(site_id, performed_at desc);
create index if not exists idx_alerts_site_severity on public.alerts(site_id, severity);
create index if not exists idx_devices_user_id on public.devices(user_id);

create trigger trg_sites_updated_at
before update on public.sites
for each row execute procedure public.set_updated_at();

create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute procedure public.set_updated_at();

create trigger trg_articles_updated_at
before update on public.articles
for each row execute procedure public.set_updated_at();

create trigger trg_stock_levels_updated_at
before update on public.stock_levels
for each row execute procedure public.set_updated_at();

create trigger trg_mouvements_updated_at
before update on public.mouvements
for each row execute procedure public.set_updated_at();

create trigger trg_alerts_updated_at
before update on public.alerts
for each row execute procedure public.set_updated_at();

create trigger trg_devices_updated_at
before update on public.devices
for each row execute procedure public.set_updated_at();

create trigger trg_app_settings_updated_at
before update on public.app_settings
for each row execute procedure public.set_updated_at();

commit;
