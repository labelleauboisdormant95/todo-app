create type public.workspace_role as enum ('leader', 'member');
create type public.task_status as enum ('backlog', 'progress', 'review', 'done');
create type public.task_priority as enum ('Low', 'Medium', 'High');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  initials text not null default '??',
  avatar_color text not null default '#6657bd',
  created_at timestamptz not null default now()
);

create table public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.workspace_role not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create table public.workspace_invites (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  invite_code text not null unique,
  invited_email text,
  expires_at timestamptz not null default (now() + interval '7 days'),
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  creator_id uuid not null references public.profiles(id),
  assignee_id uuid references public.profiles(id),
  title text not null,
  description text not null default '',
  status public.task_status not null default 'backlog',
  priority public.task_priority not null default 'Medium',
  due_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.workspace_invites enable row level security;
alter table public.tasks enable row level security;

create or replace function public.is_workspace_member(target_workspace uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.workspace_members where workspace_id = target_workspace and user_id = auth.uid());
$$;

create policy "members can read their profiles" on public.profiles for select using (
  id = auth.uid() or exists (select 1 from public.workspace_members wm where wm.user_id = profiles.id and public.is_workspace_member(wm.workspace_id))
);
create policy "members can read workspaces" on public.workspaces for select using (public.is_workspace_member(id));
create policy "members can read membership" on public.workspace_members for select using (public.is_workspace_member(workspace_id));
create policy "members can read invites" on public.workspace_invites for select using (public.is_workspace_member(workspace_id));
create policy "members can read tasks" on public.tasks for select using (public.is_workspace_member(workspace_id));
create policy "members can create tasks" on public.tasks for insert with check (public.is_workspace_member(workspace_id) and creator_id = auth.uid());
create policy "members can update tasks" on public.tasks for update using (public.is_workspace_member(workspace_id));
create policy "leaders can delete tasks" on public.tasks for delete using (exists (select 1 from public.workspace_members where workspace_id = tasks.workspace_id and user_id = auth.uid() and role = 'leader'));

create index tasks_workspace_status_idx on public.tasks(workspace_id, status);
create index tasks_assignee_idx on public.tasks(assignee_id);
