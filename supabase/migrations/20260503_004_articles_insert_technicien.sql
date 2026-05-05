begin;

drop policy if exists articles_insert_all_roles on public.articles;

create policy articles_insert_all_roles
on public.articles
for insert
with check (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.is_deleted = false
      and p.role in (
        'technicien'::public.app_role,
        'superviseur'::public.app_role,
        'admin'::public.app_role
      )
  )
);

commit;
