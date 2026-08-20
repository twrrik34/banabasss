-- DAILY KING / TODAY'S WINNER
-- Run this once in Supabase SQL Editor.
--
-- The frontend uses daily_clicks + daily_click_date.
-- The day boundary is explicitly Europe/Istanbul so 00:00 in Turkey
-- is the boundary used by the leaderboard.

alter table public.leadboard
  add column if not exists daily_clicks integer not null default 0,
  add column if not exists daily_click_date date;

update public.leadboard
set daily_click_date = (now() at time zone 'Europe/Istanbul')::date
where daily_click_date is null;

alter table public.leadboard
  alter column daily_click_date set default (now() at time zone 'Europe/Istanbul')::date;

create or replace function public.track_daily_clicks()
returns trigger
language plpgsql
as $$
declare
  istanbul_date date := (now() at time zone 'Europe/Istanbul')::date;
begin
  if new.clicks > old.clicks then
    if new.daily_click_date = istanbul_date then
      new.daily_clicks := coalesce(new.daily_clicks, 0) + (new.clicks - old.clicks);
    else
      new.daily_click_date := istanbul_date;
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

-- IMPORTANT:
-- Today's Winner should filter daily_click_date using yesterday's
-- Europe/Istanbul calendar date. This keeps yesterday's leader visible
-- throughout the current Turkish calendar day.
