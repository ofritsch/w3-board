# w3rkraum Auftragsboard

```
w3rkraum Auftragsboard – aktueller Stand: Version 1.5 (09.11.2026)
===================================================================

Dieses Repository ist der Stand, der auf w3-planung-test.netlify.app läuft.
Jede Änderung im Zweig "main" veröffentlicht Netlify automatisch nach
etwa einer Minute.

Inhalt
  site/index.html                 das Board (Netlify + Supabase)
  site/config.js                  Supabase-Adresse und anon-Schlüssel
  netlify.toml                    Netlify veröffentlicht nur den Ordner site
  supabase/supabase.sql           komplette Einrichtung der Datenbank
  supabase/update-1.1-meine-todos.sql   Update von 1.0 auf 1.1
  supabase/update-1.4-dokumente.sql     Update auf 1.4 (alle Dateiarten)

Regeln für Änderungen (auch für Claude)
  1. Jede Funktionsänderung in BEIDEN Fassungen umsetzen: in site/index.html
     und im Teamboard-Artefakt in Claude. Die Oberfläche ist gleich, nur
     der Teil zum Speichern unterscheidet sich (Supabase bzw.
     Artefakt-Datenbank).
  2. Datenbank-Änderungen für Supabase als eigenes Update-Skript
     supabase/update-<version>-<thema>.sql ablegen und zusätzlich in
     supabase.sql nachtragen.
  3. Versionsnummer erhöhen (APPV im Code, Kopfzeile dieser Datei) und
     unten eine Zeile in der Versionsliste ergänzen.
  4. Daten in der Artefakt-Datenbank nie löschen oder überschreiben,
     außer es ist ausdrücklich gewünscht.

Rechte
  SD, OF        alles
  LD, SA, JY    alles außer: neues Projekt, Rechnungen, Archiv,
                Reihenfolge der Spalte "Auftrag"
  Im Artefakt kommen die Rechte aus dem Teilen-Menü (Bearbeiter = alles,
  Mitwirkende = eingeschränkt). In Supabase aus der Tabelle board_team.

Versionen
  1.0  28.10.2026  Supabase/Netlify-Testlauf, Kalender, Dokumente,
                   Rechte, Sortierung "Auftrag" nach Auftragsdatum
  1.1  29.10.2026  Foto-Knopf in der Werkstatt, Fotos werden verkleinert,
                   PDF-Ansicht mit Vorschau, "Meine ToDos" (persönlich)
  1.2  29.10.2026  Dokumente als Galerie (Fotos und PDFs), ein wählbares
                   Titelfoto im Reiter Projekt, Werkstatt mit Ordner-Knopf
                   statt einzelner Dokumente (keine Datenbank-Änderung)
  1.3  29.10.2026  Anfrage-Karten zeigen das Kontaktdatum (Feld Erstkontakt),
                   Fotos unbeschnitten, Foto- und PDF-Ansicht fürs Handy
                   (Vollbild, PDF.js-Legacy), getrennte Knöpfe Fotos / PDF
  1.4  29.10.2026  Foto-Knopf nur noch im Projektordner, "+ Dokument" für alle
                   Dateiarten (Supabase: update-1.4-dokumente.sql), Reihenfolge
                   in "Auftrag" nur per Ziehen (keine Pfeile)
  1.5  09.11.2026  Karten am Handy/Tablet per langem Drücken verschieben
                   (auch Reihenfolge in "Auftrag" für SD/OF), "Bestehenden Kunden
                   übernehmen" im Projekt, Beispieldaten entfernen (SD/OF,
                   Konto-Fenster); keine Datenbank-Änderung
```
