# Regeln für Claude in diesem Repository

Dieses Repository enthält die w3rkraum-App: Baustein 1 (Auftragsboard, `site/index.html`) und Baustein 2 (Artikelstamm, Kalkulation, Angebot, Rechnung, `site/b2/`). Beide nutzen eine gemeinsame Supabase-Datenbank. Das verbindliche Datenmodell steht in `docs/DATENMODELL.md`, die Arbeitsweise für Baustein 2 in `docs/BAUSTEIN2.md`. Lies beide Dateien, bevor du etwas änderst.

## Zweige: niemals direkt auf `main`

- `main` wird von Netlify automatisch veröffentlicht (w3-planung-test.netlify.app). Ein Push auf `main` geht sofort an alle Nutzer.
- Baustein 2 arbeitet ausschließlich auf dem Zweig `baustein-2` (oder einem Zweig `b2-<thema>`). Nie auf `main` pushen, nie `main` umschreiben, nie `--force` auf fremde Zweige.
- Fertige Stände kommen per Pull Request von `baustein-2` nach `main`. Den Pull Request prüft und übernimmt OF (bzw. Claude in seinem Chat).

## Ordner

| Ordner / Datei | Wer ändert |
| --- | --- |
| `site/index.html`, `site/config.js`, `site/*.png`, `site/manifest.webmanifest` | nur Baustein 1 |
| `supabase/supabase.sql`, `supabase/update-*.sql` | nur Baustein 1 |
| `site/b2/` | Baustein 2 |
| `supabase/b2/` | Baustein 2 (Update-Skripte `b2-<version>-<thema>.sql`) |
| `docs/` | beide, Änderungen am Datenmodell vorher absprechen |

## Datenbank

- Tabellen von Baustein 2 beginnen mit `b2_`, dazu die gemeinsame Tabelle `kunden`. `board_*`-Tabellen werden von Baustein 2 nur gelesen (einzige Ausnahme laut Datenmodell: Feld `c` in `board_projekte`, erst nach Absprache).
- Jede neue Tabelle bekommt Row Level Security mit `board_ist_team()` / `board_ist_voll()`.
- Datenbankänderungen nur als SQL-Datei im Repository. Ausgeführt werden sie von OF im Supabase-SQL-Editor, nicht automatisch.

## Sicherheit

- Niemals Passwörter, den `service_role`-Schlüssel, `SUPABASE_SECRET_KEY` oder `.env`-Inhalte ins Repository schreiben. In `site/config.js` steht nur die öffentliche Adresse und der anon-Schlüssel.
- Keine echten Kundendaten ins Repository (auch nicht als Test- oder Importdatei). Beispieldaten nur erfunden.
