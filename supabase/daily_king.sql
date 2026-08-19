-- DAILY KING / MOST CLICKER
-- Run this once in Supabase SQL Editor.

alter table public.leadboard
  add column if not exists daily_clicks integer not null default 0,
  add column if not exists daily_date date not null default current_date;

create or replace function public.track_daily_clicks()
returns trigger
language plpgsql
as $$
begin
  if new.clicks > old.clicks then
    if new.daily_date = current_date then
      new.daily_clicks := coalesce(new.daily_clicks, 0) + (new.clicks - old.clicks);
    else
      new.daily_date := current_date;
      new.daily_clicks := new.clicks - old.clicks;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists leadboard_daily_clicks_trigger on public.leadboard;

create trigger leadboard_daily_clicks_trigger
before update of clicks on public.leadboard
for each row
execute function public.track_daily_clicks();

-- Reset stale rows automatically when the app reads them by date.
-- The frontend only considers rows where daily_date = current_date.
