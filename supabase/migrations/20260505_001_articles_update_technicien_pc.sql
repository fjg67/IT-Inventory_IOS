begin;

-- Allow techniciens (and all authenticated roles) to update PC article metadata
-- (description, codeFamille, isArchived) from the scan flow.
-- The existing articles_write_superviseur_admin policy only covers superviseur/admin.

drop policy if exists articles_update_pc_technicien on public."Article";

create policy articles_update_pc_technicien
on public."Article"
for update
using (
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
)
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
