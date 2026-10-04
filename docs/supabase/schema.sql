-- ============================================================
-- TaskManagement — C1 Schema (Supabase / Postgres)
-- المصدر: docs/architecture/CLOUD_PLAN.md (قرار D23)
-- نفّذ الملف كاملًا في SQL Editor مرة واحدة.
-- C3 سيضيف workspaces/الصلاحيات لاحقًا — الآن مزامنة شخصية بـ owner_id.
-- ============================================================

-- 1) بروفايل المستخدم (يُنشأ تلقائيًا عند التسجيل)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

-- 2) المشاريع
create table if not exists public.projects (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  emoji text,
  color_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revision bigint not null default 1,
  deleted_at timestamptz
);

-- 3) المهام
create table if not exists public.tasks (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  details text,
  status text not null default 'active',
  priority text not null default 'normal',
  is_pinned boolean not null default false,
  due_day date,
  project_id uuid references public.projects(id) on delete set null,
  reminder_date timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revision bigint not null default 1,
  deleted_at timestamptz
);

create index if not exists tasks_owner_updated_idx on public.tasks (owner_id, updated_at);
create index if not exists projects_owner_updated_idx on public.projects (owner_id, updated_at);

-- 4) triggers: revision يتزايد وupdated_at يتحدث مع كل تعديل
create or replace function public.bump_revision() returns trigger as $$
begin
  new.updated_at = now();
  new.revision = coalesce(old.revision, 0) + 1;
  return new;
end;
$$ language plpgsql;

drop trigger if exists tasks_bump on public.tasks;
create trigger tasks_bump before update on public.tasks
  for each row execute function public.bump_revision();

drop trigger if exists projects_bump on public.projects;
create trigger projects_bump before update on public.projects
  for each row execute function public.bump_revision();

-- 5) إنشاء بروفايل تلقائي عند التسجيل
create or replace function public.handle_new_user() returns trigger as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)));
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- 6) Row-Level Security — كل مستخدم يرى/يعدل بياناته فقط
alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.tasks enable row level security;

create policy "profiles own" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

create policy "projects own all" on public.projects
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

create policy "tasks own all" on public.tasks
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
