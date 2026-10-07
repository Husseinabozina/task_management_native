-- Preserve the mutation timestamp used by both native clients for LWW.
-- The existing revision triggers already call this function.
create or replace function public.bump_revision() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.updated_at < old.updated_at then return old; end if;
  new.created_at = old.created_at;
  new.revision = old.revision + 1;
  return new;
end;
$$;

create or replace function public.sync_personal(
  p_projects jsonb default '[]'::jsonb,
  p_tasks jsonb default '[]'::jsonb,
  p_deleted_projects jsonb default '[]'::jsonb,
  p_deleted_tasks jsonb default '[]'::jsonb
) returns jsonb language plpgsql security invoker set search_path = '' as $$
declare
  caller uuid := auth.uid();
begin
  if caller is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if jsonb_typeof(p_projects) <> 'array' or jsonb_typeof(p_tasks) <> 'array'
    or jsonb_typeof(p_deleted_projects) <> 'array' or jsonb_typeof(p_deleted_tasks) <> 'array'
    or p_projects is null or p_tasks is null or p_deleted_projects is null or p_deleted_tasks is null then
    raise exception 'Expected arrays' using errcode = '22023';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(caller::text, 0));

  if exists (select 1 from jsonb_array_elements(p_projects) x
      where x->>'name' is null or length(btrim(x->>'name')) not between 1 and 80)
    or exists (select 1 from jsonb_array_elements(p_tasks) x
      where x->>'title' is null or length(btrim(x->>'title')) not between 1 and 200
        or length(coalesce(x->>'details', '')) > 5000
        or coalesce(x->>'status', '') not in ('active', 'inProgress', 'completed')
        or coalesce(x->>'priority', '') not in ('low', 'normal', 'high')) then
    raise exception 'Invalid task or project values' using errcode = '22023';
  end if;

  insert into public.projects as current
    (id, owner_id, name, emoji, color_key, created_at, updated_at, deleted_at)
  select r.id, caller, btrim(r.name), r.emoji, r.color_key, r.created_at, r.updated_at, null
  from jsonb_to_recordset(p_projects) as r(id uuid, name text, emoji text, color_key text,
    created_at timestamptz, updated_at timestamptz)
  on conflict (id) do update set name = excluded.name, emoji = excluded.emoji,
    color_key = excluded.color_key, updated_at = excluded.updated_at, deleted_at = null
  where current.owner_id = caller and excluded.updated_at > current.updated_at;

  insert into public.projects as current
    (id, owner_id, name, created_at, updated_at, deleted_at)
  select r.id, caller, '', r.deleted_at, r.deleted_at, r.deleted_at
  from jsonb_to_recordset(p_deleted_projects) as r(id uuid, deleted_at timestamptz)
  on conflict (id) do update set updated_at = excluded.updated_at, deleted_at = excluded.deleted_at
  where current.owner_id = caller and (excluded.updated_at > current.updated_at
    or (excluded.updated_at = current.updated_at and current.deleted_at is null));

  insert into public.tasks as current
    (id, owner_id, title, details, status, priority, is_pinned, due_day, project_id,
     reminder_date, completed_at, created_at, updated_at, deleted_at)
  select r.id, caller, btrim(r.title), r.details, r.status, r.priority, r.is_pinned, r.due_day,
    case when exists (select 1 from public.projects p where p.id = r.project_id
      and p.owner_id = caller and p.deleted_at is null) then r.project_id else null end,
    r.reminder_date, case when r.status = 'completed' then coalesce(r.completed_at, r.updated_at) else null end,
    r.created_at, r.updated_at, null
  from jsonb_to_recordset(p_tasks) as r(id uuid, title text, details text, status text,
    priority text, is_pinned boolean, due_day date, project_id uuid, reminder_date timestamptz,
    completed_at timestamptz, created_at timestamptz, updated_at timestamptz)
  on conflict (id) do update set title = excluded.title, details = excluded.details,
    status = excluded.status, priority = excluded.priority, is_pinned = excluded.is_pinned,
    due_day = excluded.due_day, project_id = excluded.project_id, reminder_date = excluded.reminder_date,
    completed_at = excluded.completed_at, updated_at = excluded.updated_at, deleted_at = null
  where current.owner_id = caller and excluded.updated_at > current.updated_at;

  insert into public.tasks as current (id, owner_id, title, created_at, updated_at, deleted_at)
  select r.id, caller, '', r.deleted_at, r.deleted_at, r.deleted_at
  from jsonb_to_recordset(p_deleted_tasks) as r(id uuid, deleted_at timestamptz)
  on conflict (id) do update set updated_at = excluded.updated_at, deleted_at = excluded.deleted_at
  where current.owner_id = caller and (excluded.updated_at > current.updated_at
    or (excluded.updated_at = current.updated_at and current.deleted_at is null));

  -- A soft-deleted project retains its tasks, detached from the deleted grouping.
  update public.tasks t set project_id = null, updated_at = greatest(t.updated_at, p.updated_at)
  from public.projects p where t.project_id = p.id and t.owner_id = caller
    and p.owner_id = caller and p.deleted_at is not null;

  return jsonb_build_object(
    'projects', coalesce((select jsonb_agg(to_jsonb(p) order by p.id)
      from public.projects p where p.owner_id = caller), '[]'::jsonb),
    'tasks', coalesce((select jsonb_agg(to_jsonb(t) order by t.id)
      from public.tasks t where t.owner_id = caller), '[]'::jsonb)
  );
end;
$$;

revoke all on function public.sync_personal(jsonb, jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.sync_personal(jsonb, jsonb, jsonb, jsonb) to authenticated;
revoke execute on function public.bump_revision() from public, anon, authenticated;
