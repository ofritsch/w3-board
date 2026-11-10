-- =====================================================================
-- w3rkraum Auftragsboard · Einrichtung in Supabase (Testlauf)
-- Im Supabase-Dashboard: SQL Editor -> New query -> alles einfügen -> Run.
-- Das Skript legt nur neue Tabellen mit dem Präfix "board_" an.
-- Bestehende Tabellen der alten Testversion bleiben unangetastet.
-- Es kann gefahrlos mehrfach ausgeführt werden.
-- =====================================================================

-- 1) TEAM ---------------------------------------------------------------
--    voll = true heißt: alle Rechte (SD und OF).
--    LD, SA und JY werden später ergänzt, z. B. so:
--    insert into public.board_team (email, kz, voll) values
--      (lower('name@w3rkraum.de'), 'LD', false)
--    on conflict (kz) do update set email = excluded.email, voll = excluded.voll;
create table if not exists public.board_team (
  email text primary key,
  kz    text unique not null,
  voll  boolean not null default false
);

insert into public.board_team (email, kz, voll) values
  (lower('dauster@w3rkraum.de'), 'SD', true),
  (lower('fritsch@w3rkraum.de'), 'OF', true)
on conflict (kz) do update set email = excluded.email, voll = excluded.voll;

-- 2) HILFSFUNKTIONEN ------------------------------------------------------
create or replace function public.board_ist_team() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.board_team
                 where email = lower(coalesce(auth.jwt() ->> 'email', '')));
$$;

create or replace function public.board_ist_voll() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select voll from public.board_team
                   where email = lower(coalesce(auth.jwt() ->> 'email', ''))), false);
$$;

-- 3) DATENTABELLEN --------------------------------------------------------
create table if not exists public.board_projekte (
  id text primary key, data jsonb not null, updated_at timestamptz not null default now());
create table if not exists public.board_mitarbeiter (
  id text primary key, data jsonb not null, updated_at timestamptz not null default now());
create table if not exists public.board_bestellung (
  id text primary key, data jsonb not null, updated_at timestamptz not null default now());

alter table public.board_team        enable row level security;
alter table public.board_projekte    enable row level security;
alter table public.board_mitarbeiter enable row level security;
alter table public.board_bestellung  enable row level security;

-- 4) ZUGRIFFSREGELN -------------------------------------------------------
drop policy if exists "team liest team" on public.board_team;
create policy "team liest team" on public.board_team
  for select to authenticated using (public.board_ist_team());

-- Projekte: alle im Team lesen und ändern, nur SD/OF legen an oder löschen
drop policy if exists "projekte lesen"   on public.board_projekte;
drop policy if exists "projekte anlegen" on public.board_projekte;
drop policy if exists "projekte aendern" on public.board_projekte;
drop policy if exists "projekte loeschen" on public.board_projekte;
create policy "projekte lesen"   on public.board_projekte for select to authenticated using (public.board_ist_team());
create policy "projekte anlegen" on public.board_projekte for insert to authenticated with check (public.board_ist_voll());
create policy "projekte aendern" on public.board_projekte for update to authenticated using (public.board_ist_team()) with check (public.board_ist_team());
create policy "projekte loeschen" on public.board_projekte for delete to authenticated using (public.board_ist_voll());

-- Mitarbeiter und Bestellung: ganzes Team
drop policy if exists "mitarbeiter team" on public.board_mitarbeiter;
create policy "mitarbeiter team" on public.board_mitarbeiter for all to authenticated
  using (public.board_ist_team()) with check (public.board_ist_team());
drop policy if exists "bestellung team" on public.board_bestellung;
create policy "bestellung team" on public.board_bestellung for all to authenticated
  using (public.board_ist_team()) with check (public.board_ist_team());

-- 5) SCHUTZ: Rechnung und Reihenfolge in "Auftrag" nur für SD/OF -----------
create or replace function public.board_schutz() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if public.board_ist_voll() then
    new.updated_at := now();
    return new;
  end if;
  if (new.data -> 'rnr')     is distinct from (old.data -> 'rnr')
  or (new.data -> 'rnrKeep') is distinct from (old.data -> 'rnrKeep')
  or (new.data -> 'rdate')   is distinct from (old.data -> 'rdate')
  or (new.data -> 'typ')     is distinct from (old.data -> 'typ')
  or (new.data -> 'ord')     is distinct from (old.data -> 'ord')
  or (coalesce(new.data ->> 'c', '') = '4') <> (coalesce(old.data ->> 'c', '') = '4') then
    raise exception 'Nur SD und OF dürfen Rechnungen und die Reihenfolge in Auftrag ändern'
      using errcode = '42501';
  end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists board_schutz on public.board_projekte;
create trigger board_schutz before update on public.board_projekte
  for each row execute function public.board_schutz();

-- 6) LIVE-ABGLEICH (Realtime) ----------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['board_projekte','board_mitarbeiter','board_bestellung'] loop
    if not exists (select 1 from pg_publication_tables
                   where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- 7) DOKUMENTE (Storage, nicht öffentlich, max. 20 MB, alle Dateiarten) ------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('board-dokumente', 'board-dokumente', false, 20971520,
        null)
on conflict (id) do update set file_size_limit = excluded.file_size_limit,
                               allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "board dokumente lesen"    on storage.objects;
drop policy if exists "board dokumente hochladen" on storage.objects;
drop policy if exists "board dokumente aendern"  on storage.objects;
drop policy if exists "board dokumente loeschen" on storage.objects;
create policy "board dokumente lesen" on storage.objects for select to authenticated
  using (bucket_id = 'board-dokumente' and public.board_ist_team());
create policy "board dokumente hochladen" on storage.objects for insert to authenticated
  with check (bucket_id = 'board-dokumente' and public.board_ist_team());
create policy "board dokumente aendern" on storage.objects for update to authenticated
  using (bucket_id = 'board-dokumente' and public.board_ist_team());
create policy "board dokumente loeschen" on storage.objects for delete to authenticated
  using (bucket_id = 'board-dokumente' and public.board_ist_team());

-- 7b) MEINE TODOS (persönliche Liste je Person) -------------------------
create table if not exists public.board_privat (
  user_id    uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  data       jsonb not null default '{"items":[]}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.board_privat enable row level security;

drop policy if exists "privat nur selbst" on public.board_privat;
create policy "privat nur selbst" on public.board_privat for all to authenticated
  using      (user_id = auth.uid() and public.board_ist_team())
  with check (user_id = auth.uid() and public.board_ist_team());

do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public'
                   and tablename = 'board_privat') then
    alter publication supabase_realtime add table public.board_privat;
  end if;
end $$;

-- 8) BEISPIELDATEN (werden nur angelegt, wenn noch nicht vorhanden) ---------
insert into public.board_projekte (id, data) values
  ('11', $j${"id":11,"anrede":"Familie","vn":"","nn":"Becker","t":"Einbauschrank Flur","b":"Garderobe Nische","c":0,"typ":"Angebot","termine":[{"n":"Aufmaß","d":""},{"n":"Beginn Anfertigung","d":""},{"n":"Montage","d":"2026-11-05","end":true}],"ts":0,"inProd":false,"stn":["Aufmaß","Zeichnung / CAD","Material bestellen","Zuschnitt","CNC","Kanten","Zusammenbau","Fertig / Montage"],"rnr":"","rdate":"","st":[0,0,0,0,0,0,0,0],"pos":[["Korpus Eiche, 3 Türen",1,1480,""],["Beschläge",1,240,""]],"note":"","str":"","plz":"","ort":"","tel1":"","tel2":"","mail1":"","mail2":"","mat":[["Mehrschichtplatte Eiche 19 mm",6,0,"Holz Müller","MP-E19",false],["Beschlagset",1,0,"Hettich Großhandel","HB-100",false]],"zeit":[["Jonas",3.5,"Aufmaß"]],"todos":[],"log":[["28.10.","Angelegt"]],"anz":30,"docs":[]}$j$::jsonb),
  ('12', $j${"id":12,"anrede":"Herr","vn":"Peter","nn":"Hofmann","t":"Badmöbel Gäste-WC","b":"Waschtisch","c":1,"typ":"Angebot","termine":[{"n":"Aufmaß","d":""},{"n":"Beginn Anfertigung","d":""},{"n":"Montage","d":"2026-11-28","end":true}],"ts":0,"inProd":false,"stn":["Aufmaß","Zeichnung / CAD","Material bestellen","Zuschnitt","CNC","Kanten","Zusammenbau","Fertig / Montage"],"rnr":"","rdate":"","st":[0,0,0,0,0,0,0,0],"pos":[["Waschtischunterschrank",1,980,""]],"note":"","str":"","plz":"","ort":"","tel1":"","tel2":"","mail1":"","mail2":"","mat":[["Mehrschichtplatte Eiche 19 mm",6,0,"Holz Müller","MP-E19",false],["Beschlagset",1,0,"Hettich Großhandel","HB-100",false]],"zeit":[["Jonas",3.5,"Aufmaß"]],"todos":[],"log":[["28.10.","Angelegt"]],"anz":30,"docs":[]}$j$::jsonb),
  ('13', $j${"id":13,"anrede":"Firma","vn":"","nn":"Meyer GmbH","t":"Küche L-Form","b":"Küchenzeile","c":2,"typ":"Angebot","termine":[{"n":"Aufmaß","d":""},{"n":"Beginn Anfertigung","d":""},{"n":"Montage","d":"2026-11-21","end":true}],"ts":0,"inProd":false,"stn":["Aufmaß","Zeichnung / CAD","Material bestellen","Zuschnitt","CNC","Kanten","Zusammenbau","Fertig / Montage"],"rnr":"","rdate":"","st":[0,0,0,0,0,0,0,0],"pos":[["Küchenzeile Nussbaum",1,6200,""],["Arbeitsplatte Quarz, lfm",4,380,""],["Montage (Std.)",16,62,""]],"note":"","str":"Industrieweg 5","plz":"66130","ort":"Saarbrücken","tel1":"0681 998877","tel2":"","mail1":"info@meyer-gmbh.example","mail2":"buero@meyer-gmbh.example","mat":[["Küchenfronten Nussbaum",12,0,"Holz Müller","NB-18",true],["Arbeitsplatte Quarz",4,0,"Stein Schmidt","QZ-30",false],["Spülenschrank-Beschläge",1,0,"Hettich Großhandel","SP-90",false]],"zeit":[["Jonas",3.5,"Aufmaß"]],"todos":[["Aufmaß-Skizze mit Kunde abstimmen",0,0]],"log":[["28.10.","Angelegt"]],"anz":30,"ad":"2026-10-20","docs":[]}$j$::jsonb),
  ('14', $j${"id":14,"anrede":"Frau","vn":"Anna","nn":"Kunz","t":"Küche Altbau","b":"Hochschrank","c":3,"typ":"Angebot","termine":[{"n":"Aufmaß","d":""},{"n":"Beginn Anfertigung","d":""},{"n":"Montage","d":"2026-11-14","end":true}],"ts":0,"inProd":true,"stn":["Aufmaß","Zeichnung / CAD","Material bestellen","Zuschnitt","CNC","Kanten","Zusammenbau","Fertig / Montage"],"rnr":"","rdate":"","st":[2,2,1,1,0,0,0,0],"pos":[["Hochschrank",1,2100,""]],"note":"","str":"Hauptstraße 12","plz":"66111","ort":"Saarbrücken","tel1":"0681 123456","tel2":"","mail1":"anna.kunz@example.de","mail2":"","mat":[["Mehrschichtplatte Eiche 19 mm",6,1,"Holz Müller","MP-E19",true],["Kantenband Eiche",30,0,"Holz Müller","KB-E22",true],["Auszugsbeschläge",4,0,"Hettich Großhandel","AZ-450",true]],"zeit":[["Jonas",3.5,"Aufmaß"]],"todos":[["Hochschrank: Tür links 2 mm kürzen",0,1],["Auszüge vor Montage prüfen",0,0]],"log":[["28.10.","Angelegt"]],"anz":30,"ad":"2026-10-05","docs":[]}$j$::jsonb),
  ('15', $j${"id":15,"anrede":"Herr","vn":"Jörg","nn":"Schmitt","t":"Badmöbel","b":"Spiegelschrank","c":3,"typ":"Angebot","termine":[{"n":"Aufmaß","d":""},{"n":"Beginn Anfertigung","d":""},{"n":"Montage","d":"2026-11-12","end":true}],"ts":0,"inProd":true,"stn":["Aufmaß","Zeichnung / CAD","Material bestellen","Zuschnitt","CNC","Kanten","Zusammenbau","Fertig / Montage"],"rnr":"","rdate":"","st":[2,2,2,2,2,1,0,0],"pos":[["Spiegelschrank",1,690,""]],"note":"","str":"Bahnhofstraße 3","plz":"66117","ort":"Saarbrücken","tel1":"0171 5551234","tel2":"","mail1":"j.schmitt@example.de","mail2":"","mat":[["Spiegelschrank-Glas",2,2,"Glas Becker","SG-60",true],["Mehrschichtplatte Weiß 19 mm",3,1,"Holz Müller","MP-W19",true]],"zeit":[["Jonas",3.5,"Aufmaß"]],"todos":[["Spiegelschrank: Beleuchtung mit Kunde klären",0,0],["Silikon am Waschtisch nach Montage",1,0]],"log":[["28.10.","Angelegt"]],"anz":30,"ad":"2026-10-02","docs":[]}$j$::jsonb),
  ('16', $j${"id":16,"anrede":"Frau","vn":"Sabine","nn":"Wagner","t":"Einbauschrank","b":"Schiebetür Flur","c":3,"typ":"Angebot","termine":[{"n":"Aufmaß","d":""},{"n":"Beginn Anfertigung","d":""},{"n":"Montage","d":"2026-11-18","end":true}],"ts":0,"inProd":true,"stn":["Aufmaß","Zeichnung / CAD","Material bestellen","Zuschnitt","CNC","Kanten","Zusammenbau","Fertig / Montage"],"rnr":"","rdate":"","st":[2,1,0,0,0,0,0,0],"pos":[["Schiebetüranlage",1,1750,""]],"note":"","str":"","plz":"","ort":"","tel1":"","tel2":"","mail1":"","mail2":"","mat":[["Schiebetürsystem",1,0,"Hettich Großhandel","ST-2400",true],["Mehrschichtplatte Eiche 19 mm",5,0,"Holz Müller","MP-E19",true]],"zeit":[["Jonas",3.5,"Aufmaß"]],"todos":[["Schiebetür: Laufschiene lackieren",0,2]],"log":[["28.10.","Angelegt"]],"anz":30,"ad":"2026-10-12","docs":[]}$j$::jsonb),
  ('17', $j${"id":17,"anrede":"Herr","vn":"Max","nn":"Lang","t":"Küche","b":"Kücheninsel","c":4,"typ":"Rechnung","termine":[{"n":"Aufmaß","d":""},{"n":"Beginn Anfertigung","d":""},{"n":"Montage","d":"","end":true}],"ts":0,"inProd":false,"stn":["Aufmaß","Zeichnung / CAD","Material bestellen","Zuschnitt","CNC","Kanten","Zusammenbau","Fertig / Montage"],"rnr":"","rdate":"","st":[2,2,2,2,2,2,2,2],"pos":[["Kücheninsel",1,3400,""],["Montage (Std.)",8,62,""]],"note":"","str":"","plz":"","ort":"","tel1":"","tel2":"","mail1":"","mail2":"","mat":[["Mehrschichtplatte Eiche 19 mm",6,0,"Holz Müller","MP-E19",true],["Beschlagset",1,0,"Hettich Großhandel","HB-100",true]],"zeit":[["Jonas",3.5,"Aufmaß"]],"todos":[],"log":[["28.10.","Angelegt"]],"anz":30,"ad":"2026-09-25","docs":[]}$j$::jsonb),
  ('18', $j${"id":18,"anrede":"Herr","vn":"Klaus","nn":"Berg","t":"Küche","b":"Küchenzeile","c":4,"typ":"Rechnung","termine":[{"n":"Aufmaß","d":""},{"n":"Beginn Anfertigung","d":""},{"n":"Montage","d":"","end":true}],"ts":0,"inProd":false,"stn":["Aufmaß","Zeichnung / CAD","Material bestellen","Zuschnitt","CNC","Kanten","Zusammenbau","Fertig / Montage"],"rnr":"2609-001","rdate":"2026-09-14","st":[0,0,0,0,0,0,0,0],"pos":[["Küchenzeile",1,5200,""],["Montage (Std.)",12,62,""]],"note":"","str":"","plz":"","ort":"","tel1":"","tel2":"","mail1":"","mail2":"","mat":[["Mehrschichtplatte Eiche 19 mm",6,0,"Holz Müller","MP-E19",true],["Beschlagset",1,0,"Hettich Großhandel","HB-100",true]],"zeit":[["Jonas",3.5,"Aufmaß"]],"todos":[],"log":[["28.10.","Angelegt"]],"anz":30,"ad":"2026-08-20","docs":[]}$j$::jsonb),
  ('19', $j${"id":19,"anrede":"Frau","vn":"Eva","nn":"Roth","t":"Badmöbel","b":"Waschtisch","c":4,"typ":"Rechnung","termine":[{"n":"Aufmaß","d":""},{"n":"Beginn Anfertigung","d":""},{"n":"Montage","d":"","end":true}],"ts":0,"inProd":false,"stn":["Aufmaß","Zeichnung / CAD","Material bestellen","Zuschnitt","CNC","Kanten","Zusammenbau","Fertig / Montage"],"rnr":"2609-002","rdate":"2026-09-28","st":[0,0,0,0,0,0,0,0],"pos":[["Waschtischunterschrank",1,1180,""]],"note":"","str":"","plz":"","ort":"","tel1":"","tel2":"","mail1":"","mail2":"","mat":[["Mehrschichtplatte Eiche 19 mm",6,0,"Holz Müller","MP-E19",true],["Beschlagset",1,0,"Hettich Großhandel","HB-100",true]],"zeit":[["Jonas",3.5,"Aufmaß"]],"todos":[],"log":[["28.10.","Angelegt"]],"anz":30,"ad":"2026-09-03","docs":[]}$j$::jsonb),
  ('20', $j${"id":20,"anrede":"Herr","vn":"Uwe","nn":"Fuchs","t":"Einbauschrank","b":"Flur","c":4,"typ":"Rechnung","termine":[{"n":"Aufmaß","d":""},{"n":"Beginn Anfertigung","d":""},{"n":"Montage","d":"","end":true}],"ts":0,"inProd":false,"stn":["Aufmaß","Zeichnung / CAD","Material bestellen","Zuschnitt","CNC","Kanten","Zusammenbau","Fertig / Montage"],"rnr":"2610-001","rdate":"2026-10-05","st":[0,0,0,0,0,0,0,0],"pos":[["Einbauschrank Flur",1,2450,""]],"note":"","str":"","plz":"","ort":"","tel1":"","tel2":"","mail1":"","mail2":"","mat":[["Mehrschichtplatte Eiche 19 mm",6,0,"Holz Müller","MP-E19",true],["Beschlagset",1,0,"Hettich Großhandel","HB-100",true]],"zeit":[["Jonas",3.5,"Aufmaß"]],"todos":[],"log":[["28.10.","Angelegt"]],"anz":30,"ad":"2026-09-10","docs":[]}$j$::jsonb),
  ('21', $j${"id":21,"anrede":"Firma","vn":"","nn":"Kurz GmbH","t":"Küche","b":"Büroküche","c":4,"typ":"Rechnung","termine":[{"n":"Aufmaß","d":""},{"n":"Beginn Anfertigung","d":""},{"n":"Montage","d":"","end":true}],"ts":0,"inProd":false,"stn":["Aufmaß","Zeichnung / CAD","Material bestellen","Zuschnitt","CNC","Kanten","Zusammenbau","Fertig / Montage"],"rnr":"2512-001","rdate":"2025-12-11","st":[0,0,0,0,0,0,0,0],"pos":[["Büroküche",1,3900,""]],"note":"","str":"","plz":"","ort":"","tel1":"","tel2":"","mail1":"","mail2":"","mat":[["Mehrschichtplatte Eiche 19 mm",6,0,"Holz Müller","MP-E19",true],["Beschlagset",1,0,"Hettich Großhandel","HB-100",true]],"zeit":[["Jonas",3.5,"Aufmaß"]],"todos":[],"log":[["28.10.","Angelegt"]],"anz":30,"ad":"2025-11-14","docs":[]}$j$::jsonb)
on conflict (id) do nothing;

insert into public.board_mitarbeiter (id, data) values
  ('1', $j${"id":1,"nick":"Jo","img":"","vn":"Jonas","nn":"Keller","str":"Waldweg 4","plz":"66119","ort":"Saarbrücken","tel":"0176 1112233","mail":"j.keller@example.de","todos":[["CNC-Maschine reinigen, Späneabsaugung leeren",0,1]],"abw":[{"d":"2026-10-29","t":"Schule"},{"d":"2026-10-30","t":"Schule"}]}$j$::jsonb),
  ('2', $j${"id":2,"nick":"Lenni","img":"","vn":"Lena","nn":"Brandt","str":"Gartenstraße 18","plz":"66111","ort":"Saarbrücken","tel":"0151 4445566","mail":"l.brandt@example.de","todos":[],"abw":[{"d":"2026-10-28","t":"Urlaub"}]}$j$::jsonb),
  ('3', $j${"id":3,"nick":"","img":"","vn":"Markus","nn":"Weber","str":"Am Markt 7","plz":"66123","ort":"Saarbrücken","tel":"0160 7778899","mail":"m.weber@example.de","todos":[]}$j$::jsonb),
  ('4', $j${"id":4,"nick":"Tobi","img":"","arch":true,"vn":"Tobias","nn":"Neumann","str":"Bergstraße 9","plz":"66113","ort":"Saarbrücken","tel":"0171 2223344","mail":"t.neumann@example.de","todos":[]}$j$::jsonb)
on conflict (id) do nothing;

insert into public.board_bestellung (id, data) values
  ('extra', $j${"items":[]}$j$::jsonb)
on conflict (id) do nothing;
