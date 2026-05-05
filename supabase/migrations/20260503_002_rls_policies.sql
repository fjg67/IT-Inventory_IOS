begin;

create or replace function public.current_app_role()
returns public.app_role
language sql
stable
as $$
  select role
  from public.profiles
  where id = auth.uid() and is_deleted = false
$$;

create or replace function public.current_site_id()
returns uuid
language sql
stable
as $$
  select site_id
  from public.profiles
  where id = auth.uid() and is_deleted = false
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select public.current_app_role() = 'admin'::public.app_role
$$;

create or replace function public.is_superviseur_or_admin()
returns boolean
language sql
stable
as $$
  select public.current_app_role() in ('superviseur'::public.app_role, 'admin'::public.app_role)
$$;

alter table public.sites enable row level security;
alter table public.profiles enable row level security;
alter table public.articles enable row level security;
alter table public.stock_levels enable row level security;
alter table public.mouvements enable row level security;
alter table public.alerts enable row level security;
alter table public.devices enable row level security;
alter table public.app_settings enable row level security;

create policy profiles_select_self_or_admin
on public.profiles
for select
using (
  id = auth.uid() or public.is_admin()
);

create policy profiles_update_self_or_admin
on public.profiles
for update
using (
  id = auth.uid() or public.is_admin()
)
with check (
  id = auth.uid() or public.is_admin()
);

create policy sites_select_by_scope
on public.sites
for select
using (
  public.is_superviseur_or_admin() or id = public.current_site_id()
);

create policy sites_write_superviseur_admin
on public.sites
for all
using (public.is_superviseur_or_admin())
with check (public.is_superviseur_or_admin());

create policy articles_read_all_roles
on public.articles
for select
using (
  public.current_app_role() in ('technicien'::public.app_role, 'superviseur'::public.app_role, 'admin'::public.app_role)
);

create policy articles_write_superviseur_admin
on public.articles
for all
using (public.is_superviseur_or_admin())
with check (public.is_superviseur_or_admin());

create policy stock_levels_select_by_scope
on public.stock_levels
for select
using (
  public.is_superviseur_or_admin() or site_id = public.current_site_id()
);

create policy stock_levels_write_superviseur_admin
on public.stock_levels
for all
using (public.is_superviseur_or_admin())
with check (public.is_superviseur_or_admin());

create policy mouvements_select_by_scope
on public.mouvements
for select
using (
  public.is_superviseur_or_admin() or site_id = public.current_site_id()
);

create policy mouvements_insert_role_scoped
on public.mouvements
for insert
with check (
  public.current_app_role() in ('technicien'::public.app_role, 'superviseur'::public.app_role, 'admin'::public.app_role)
  and (public.is_superviseur_or_admin() or site_id = public.current_site_id())
  and created_by = auth.uid()
);

create policy mouvements_update_superviseur_admin
on public.mouvements
for update
using (public.is_superviseur_or_admin())
with check (public.is_superviseur_or_admin());

create policy alerts_select_by_scope
on public.alerts
for select
using (
  public.is_superviseur_or_admin() or site_id = public.current_site_id()
);

create policy alerts_write_superviseur_admin
on public.alerts
for all
using (public.is_superviseur_or_admin())
with check (public.is_superviseur_or_admin());

create policy devices_select_self_or_admin
on public.devices
for select
using (
  user_id = auth.uid() or public.is_admin()
);

create policy devices_insert_self_or_admin
on public.devices
for insert
with check (
  user_id = auth.uid() or public.is_admin()
);

create policy devices_update_self_or_admin
on public.devices
for update
using (
  user_id = auth.uid() or public.is_admin()
)
with check (
  user_id = auth.uid() or public.is_admin()
);

create policy app_settings_select_self
on public.app_settings
for select
using (user_id = auth.uid() or public.is_admin());

create policy app_settings_write_self
on public.app_settings
for all
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

commit;
