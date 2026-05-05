begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'article-images',
  'article-images',
  true,
  5242880,
  array['image/jpeg', 'image/png']
)
on conflict (id) do nothing;

drop policy if exists "article_images_read_public" on storage.objects;
drop policy if exists "article_images_insert_superviseur_admin" on storage.objects;
drop policy if exists "article_images_update_superviseur_admin" on storage.objects;
drop policy if exists "article_images_delete_superviseur_admin" on storage.objects;

create policy "article_images_read_public"
on storage.objects
for select
using (bucket_id = 'article-images');

create policy "article_images_insert_superviseur_admin"
on storage.objects
for insert
with check (
  bucket_id = 'article-images'
  and exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.is_deleted = false
      and p.role in ('superviseur'::public.app_role, 'admin'::public.app_role)
  )
);

create policy "article_images_update_superviseur_admin"
on storage.objects
for update
using (
  bucket_id = 'article-images'
  and exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.is_deleted = false
      and p.role in ('superviseur'::public.app_role, 'admin'::public.app_role)
  )
)
with check (
  bucket_id = 'article-images'
  and exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.is_deleted = false
      and p.role in ('superviseur'::public.app_role, 'admin'::public.app_role)
  )
);

create policy "article_images_delete_superviseur_admin"
on storage.objects
for delete
using (
  bucket_id = 'article-images'
  and exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.is_deleted = false
      and p.role in ('superviseur'::public.app_role, 'admin'::public.app_role)
  )
);

commit;
