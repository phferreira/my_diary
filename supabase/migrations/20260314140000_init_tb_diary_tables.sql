create table if not exists tb_diaries (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  content text not null default '',
  password text,
  is_public boolean not null default false
);

create table if not exists tb_diary_entries (
  id uuid primary key default gen_random_uuid(),
  diary_id uuid not null references tb_diaries(id) on delete cascade,
  entry_date date not null,
  content text not null default ''
);

create unique index if not exists tb_diary_entries_diary_date_key
  on tb_diary_entries (diary_id, entry_date);
