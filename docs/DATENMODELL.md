# w3rkraum App: Gemeinsames Datenmodell Baustein 1 + 2

Stand 14.11.2026 · Kopie des Claude-Docs-Dokuments „Gemeinsames Datenmodell“ (Original: https://claude.ai/artifact/19Xjn44jVXkXdvDcQVfEAA). Bei Abweichungen gilt das Original; Änderungen bitte dort besprechen und diese Datei nachziehen.

Baustein 1 (Auftragsboard) und Baustein 2 (Artikelstamm, Kalkulation, Angebot, Rechnung) werden getrennt mit Claude gebaut und später zu einer App mit einer Supabase-Datenbank zusammengeführt. Dieses Dokument legt fest, welche Tabellen es gibt, wer sie schreibt und wie sie verbunden sind.

## Grundregeln

Beide Bausteine nutzen dieselbe Datenbank, aber jeder schreibt nur in seine eigenen Tabellen.

1. **Eine Datenbank:** Testphase im Supabase-Projekt von w3-planung-test, später auf dem Server im Haus (Mac mini). Kein zweites Supabase-Projekt für Baustein 2.
2. **Vorsilben:** Baustein 1 nutzt `board_`, Baustein 2 nutzt `b2_`. Gemeinsame Stammdaten ohne Vorsilbe: `kunden`.
3. **Jeder schreibt nur seine Tabellen:** Baustein 2 ändert keine `board_`-Tabellen und umgekehrt. Lesen ist erlaubt. Ausnahme: die festgelegten Verknüpfungsfelder (Kapitel Verbindung).
4. **Ein Login, ein Team:** Anmeldung über Supabase Auth. Wer zum Team gehört und volle Rechte hat, steht nur in `board_team`. Baustein 2 nutzt die vorhandenen Funktionen `board_ist_team()` und `board_ist_voll()`.
5. **Zugriffsregeln in der Datenbank:** Jede neue Tabelle bekommt Row Level Security. Rechte nur in der Oberfläche zu prüfen reicht nicht.
6. **Änderungen nur per Skript:** Jede Datenbankänderung als Datei `supabase/update-<version>-<thema>.sql` (Baustein 2: `supabase/b2/…`), nie direkt im Dashboard herumklicken.
7. **Ein Repository:** GitHub-Repository `ofritsch/w3-board`. Baustein 2 im Ordner `site/b2/` und `supabase/b2/`, bis die Navigation zusammengeführt ist.

## Baustein 1 heute

Das Board speichert jeden Datensatz als JSON in einer Spalte `data`. Die Tabellen haben je `id` (text), `data` (jsonb) und `updated_at`.

| Tabelle | Inhalt | Schreiben |
| --- | --- | --- |
| `board_team` | E-Mail, Kürzel (SD, OF, LD, SA, JY), `voll` = alle Rechte | nur per SQL |
| `board_projekte` | ein Projekt je Zeile, Felder siehe unten | Team; anlegen und löschen nur `voll` |
| `board_mitarbeiter` | Mitarbeiter mit Kontakt, Abwesenheiten, Aufgaben | Team |
| `board_bestellung` | Zeile `extra`: Bestellartikel ohne Projekt | Team |
| `board_privat` | persönliche ToDos, eine Zeile je Nutzer | nur die Person selbst |
| Storage `board-dokumente` | Fotos und Dokumente, Pfad `<projekt-id>/<zeit>-<name>` | Team |

Ein Datenbank-Trigger (`board_schutz`) verhindert, dass Personen ohne `voll` die Felder `rnr`, `rnrKeep`, `rdate`, `typ`, `ord` ändern oder Karten in oder aus der Spalte Rechnung schieben.

**Projekt-Datensatz (`board_projekte.data`)**

| Feld | Bedeutung |
| --- | --- |
| `id` | Projekt-ID, Zahl; Beispielprojekte unter 1000 |
| `pnr` | Projektnummer JJ-NNN (seit 1.14, automatisch) |
| `c` | Spalte: 0 Anfrage, 1 Angebot, 2 Auftrag, 3 Produktion, 4 Archiv/Rechnung |
| `av` | AV-Stand (seit 1.9): 0 Auftrag erteilt, 1 AV läuft, 2 AV fertig |
| `t`, `b` | Projekt und Bauteil, z. B. „Küche L-Form“, „Küchenzeile“ |
| `anrede`, `vn`, `nn` | Kunde: Anrede, Vorname, Nachname oder Firma |
| `str`, `plz`, `ort`, `tel1`, `tel2`, `mail1`, `mail2` | Adresse und Kontakt des Kunden |
| `kd`, `ad` | Datum Erstkontakt, Auftragsdatum (JJJJ-MM-TT) |
| `ord` | eigene Reihenfolge in Auftrag (nur SD/OF) |
| `termine` | Liste `{n, d, end}`; `end:true` = Montage oder Auslieferung |
| `stn`, `st` | Werkstatt-Schritte und ihr Stand (0 offen, 1 läuft, 2 fertig) |
| `pos` | Angebotspositionen `[Text, Menge, Einzelpreis netto, Erläuterung]` |
| `anz` | Anzahlung in Prozent |
| `typ`, `rnr`, `rdate`, `rnrKeep` | Angebot/Rechnung, Rechnungsnummer JJMM-001, Rechnungsdatum |
| `mat` | Material `[Text, Menge, Status, Lieferant, Artikel-Nr., bestellen]` |
| `zeit` | gebuchte Zeit `[Wer, Stunden, Tätigkeit]` |
| `todos` | Aufgaben `[Text, erledigt, Mitarbeiter-ID]` |
| `docs`, `tf` | Dokumente `{path, n, t, s}`, Titelfoto (Pfad) |
| `note`, `log` | Beschreibung, Verlauf |

Die Felder `pos`, `anz`, `typ`, `rnr`, `rdate` gehören fachlich zu Baustein 2 und werden beim Zusammenführen dorthin verlegt.

## Gemeinsame Kundentabelle `kunden`

Baustein 2 legt die Tabelle an und füllt sie, auch mit dem Import der Kunden aus GrandTotal (rund 700–800). Baustein 1 liest sie und verweist darauf. Normale Spalten statt JSON, damit Suche und Import einfach bleiben.

| Spalte | Typ | Hinweis |
| --- | --- | --- |
| `id` | uuid | Primärschlüssel, `gen_random_uuid()` |
| `kundennr` | text, eindeutig | Format offen (siehe Offene Fragen) |
| `anrede` | text | Herr, Frau, Familie, Firma |
| `vorname`, `name` | text | `name` = Nachname oder Firmenname |
| `strasse`, `plz`, `ort` | text | |
| `tel1`, `tel2`, `mail1`, `mail2` | text | wie im Board |
| `ustid` | text | für Firmenkunden, wichtig für E-Rechnungen |
| `notiz` | text | |
| `grandtotal_id` | text | Herkunft beim Import, hilft gegen Doppelte |
| `angelegt`, `geaendert` | timestamptz | `default now()` |

Die Feldnamen im Board (`vn`, `nn`, `str` …) bleiben vorerst. Beim Zusammenführen bekommt jedes Projekt zusätzlich `kunde_id`, und die Kundenfelder im Projekt werden aus `kunden` gefüllt.

## Tabellen von Baustein 2

Beträge in Euro netto, mit zwei Nachkommastellen (`numeric(12,2)`).

| Tabelle | Wichtige Spalten | Verknüpft mit |
| --- | --- | --- |
| `b2_artikel` | `id`, `artnr`, `lieferant`, `bezeichnung`, `einheit`, `vk`, `mwst_pct`, `warengruppe`, `quelle` (z. B. Häfele-Import), `aktualisiert` | – |
| `b2_artikel_ek` | `artikel_id`, `ek`, `aufschlag_pct` (nur `voll` darf lesen) | `b2_artikel.id` |
| `b2_angebote` | `id`, `nummer`, `datum`, `status` (Entwurf, versendet, angenommen, abgelehnt), `gueltig_bis`, `anzahlung_pct`, `summe_netto` | `projekt_id` → `board_projekte.id`, `kunde_id` → `kunden.id` |
| `b2_rechnungen` | `id`, `nummer` (eindeutig), `art` (Anzahlung, Schluss, Einzel), `datum`, `leistungsdatum`, `status`, `festgeschrieben`, `summe_netto`, `mwst`, `summe_brutto`, `erechnung_pfad` | `projekt_id`, `kunde_id`, `angebot_id` → `b2_angebote.id` |
| `b2_positionen` | `id`, `beleg_art` (angebot, rechnung), `beleg_id`, `pos_nr`, `text`, `erlaeuterung`, `menge`, `einheit`, `ek`, `vk`, `rabatt_pct`, `mwst_pct` | `artikel_id` → `b2_artikel.id` (optional, freie Positionen erlaubt) |

- **Kalkulation:** Steckt in den Positionen (`ek`, Aufschlag, `vk`), daraus ergibt sich der Deckungsbeitrag je Angebot.
- **Festgeschrieben:** Ist eine Rechnung erstellt, wird `festgeschrieben = true` gesetzt. Danach verhindert ein Trigger jede Änderung, Korrekturen laufen über eine Stornorechnung (GoBD).
- **Artikel ohne Projekt:** Positionen dürfen frei sein, z. B. „Montage (Std.)“.

## Verbindung und Übergang

Die Klammer zwischen beiden Bausteinen ist die Projekt-ID: Jedes Angebot und jede Rechnung trägt `projekt_id` = `board_projekte.id` (als Text).

1. **Testphase:** Beide Bausteine laufen getrennt. Baustein 2 testet mit eigenen Beispieldaten und mit Kopien der Projekt-IDs.
2. **Zusammenführen:** Der Knopf „Angebot/Rechnung“ im Board öffnet `site/b2/` mit `?projekt=<id>`. Das Board zeigt Status, Nummer und Summe aus `b2_angebote` und `b2_rechnungen`. „Angebot → Rechnung“ und die Rechnungsnummer vergibt nur noch Baustein 2.
3. **Spalten bleiben im Board:** Später darf Baustein 2 die Karte automatisch verschieben (Feld `c` in `board_projekte`), wenn ein Angebot angenommen oder eine Rechnung gestellt wird. Das ist die einzige erlaubte Schreibstelle von Baustein 2 in `board_projekte`.
4. **Umzug der Altdaten:** Ein Skript überträgt `pos`, `anz` und `rnr` aus den Board-Projekten in `b2_angebote`, `b2_rechnungen` und `b2_positionen`.
5. **Gemeinsame Navigation:** Board · Werkstatt · Kalender · Mitarbeiter · Kunden · Artikel · Angebote · Rechnungen, ein Login.

**Nummernkreise**

| Beleg | Format | Beispiel | Vergibt |
| --- | --- | --- | --- |
| Projekt | JJ-NNN | 26-004 | Board |
| Rechnung | JJMM-NNN | 2611-001 | heute Board, später Baustein 2 |
| Angebot | A-JJMM-NNN | A-2611-001 | Baustein 2 |
| Kunde | offen | – | Baustein 2 |

Rechnungsnummern müssen lückenlos sein und dürfen nicht doppelt vergeben werden. Baustein 2 vergibt sie in der Datenbank (SQL-Funktion mit Sperre).

## Rechte

SD und OF haben `voll = true` und dürfen alles. LD, SA und JY dürfen im Board fast alles, Geld und Rechnungen bleiben gesperrt.

| Tabelle | Lesen | Schreiben |
| --- | --- | --- |
| `board_*` | Team | wie in Baustein 1 |
| `kunden` | Team | Team; löschen nur `voll` |
| `b2_artikel` | Team | nur `voll` |
| `b2_artikel_ek` | nur `voll` | nur `voll` |
| `b2_angebote`, `b2_positionen` | Team (Vorschlag) | nur `voll` |
| `b2_rechnungen` | Team (Vorschlag) | nur `voll`; nach `festgeschrieben` niemand |

## Technik und Aussehen

- Eine HTML-Datei je Ansicht, supabase-js 2.45.4 über jsDelivr, Verbindung über dieselbe `site/config.js` (aus `site/b2/` als `../config.js`).
- Grautöne des Boards ab Version 1.7. Hell: Hintergrund #ECEDEE, Flächen #FFFFFF, Text #1F2326, gedämpfter Text #555B61, Rahmen #C9CCCF, Akzent #2B2F33, Akzent hell #DFE1E3, Kopfzeile #2B2F33. Dunkel: Hintergrund #17191B, Flächen #24272A, Text #E8EAEC, gedämpfter Text #A6ACB2, Rahmen #41464B, Akzent #D5D8DB, Akzent hell #2C3033. Statusfarben: Grün #2F8A5B, Orange #B7770E. Schrift „IBM Plex Sans“ mit system-ui als Ersatz, Logo „3“ und „Projektsteuerung“ in der Kopfzeile.
- Versionsnummer sichtbar in der Oberfläche und eine Zeile in der Versionsliste je Version.

## Offene Fragen

- [ ] Format der Kundennummer (fortlaufend ab 10001 oder aus GrandTotal übernehmen)?
- [ ] Exportformat aus GrandTotal (CSV, Excel)? Beispieldatei für den Import.
- [ ] Dürfen LD, SA und JY Angebote und Rechnungen sehen, oder nur Status und Nummer?
- [ ] Rechnungsnummern: JJMM-NNN oder fortlaufend über das Jahr? Mit dem Steuerbüro klären.
- [ ] E-Rechnung (XRechnung/ZUGFeRD): selbst erzeugen oder über ein Buchhaltungsprogramm? Mit dem Steuerbüro klären.
- [ ] Welche Daten liefert Häfele (Datanorm, BMEcat, CSV, OCI/IDS)?
