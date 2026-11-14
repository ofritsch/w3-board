# Baustein 2: Arbeitsweise mit GitHub

Für den Kollegen, der Baustein 2 mit Claude baut, und für seine Claude-Sitzungen.

## Ablauf für jede Änderung

1. Claude-Sitzung mit dem Repository `ofritsch/w3-board` starten. Claude liest dabei automatisch `CLAUDE.md`.
2. Auf dem Zweig `baustein-2` arbeiten (beim ersten Mal von `main` anlegen).
3. Dateien nur in `site/b2/` und `supabase/b2/` ändern.
4. Versionsnummer in der Oberfläche hochzählen und eine Zeile in `site/b2/VERSIONEN.md` ergänzen.
5. Auf `baustein-2` pushen. Netlify baut dafür eine eigene Vorschau-Adresse, sobald ein Pull Request offen ist.
6. Pull Request `baustein-2` → `main` öffnen (bzw. aktualisieren) und kurz beschreiben, was neu ist und ob ein SQL-Skript ausgeführt werden muss.
7. OF prüft und übernimmt. Erst dann ist die Änderung im echten Board.

## Erste Startnachricht im Claude-Chat

> Wir bauen Baustein 2 der w3rkraum-App im Repository ofritsch/w3-board. Lies zuerst CLAUDE.md, docs/DATENMODELL.md und docs/BAUSTEIN2.md und halte dich daran. Arbeite nur auf dem Zweig baustein-2 und nur in site/b2/ und supabase/b2/. Übernimm den vorhandenen Stand von Baustein 2 aus der angehängten Datei und stelle die Datenspeicherung auf Supabase um (Tabellen laut Datenmodell, Anmeldung wie im Board über ../config.js).

## Testen

- Im Board-Testprojekt in Supabase gibt es ein Konto für den Kollegen (von OF angelegt). Damit meldet er sich in der Vorschau-Adresse an.
- SQL-Skripte aus `supabase/b2/` führt OF im Supabase-SQL-Editor aus, wenn der Pull Request das ankündigt.
- Import-Testdateien (Kunden, Artikel) nicht ins Repository legen, sondern lokal oder im Chat verwenden.
