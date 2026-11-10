# w3rkraum Auftragsboard

```
w3rkraum Auftragsboard – aktueller Stand: Version 1.11 (11.11.2026)
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
  1.6  10.11.2026  Graues Design mit der "3" (wie erste Projektsteuerung),
                   ohne Preise, Angebot/Rechnung, Material und Bestellung;
                   Knopf "Kalkulation & Angebot" (Baustein 2, Adresse in
                   config.js als b2Url); Ampel nach Fortschritt gegen Zeit;
                   Projektübersicht; Kalender mit gleitender Ampelfarbe
  1.7  10.11.2026  Datumsfelder Beginn Anfertigung und Montage im Projekt,
                   Aufgaben und ToDos nachträglich bearbeitbar, Spalte Rechnung
                   ersetzt durch Status "Abgeschlossen" (Archiv), Kopfzeile neu:
                   Reiter mittig inkl. Angebot/Rechnung, Datum, Suche und Kürzel
                   rechts; Kalender mit Spalten Auftrag und Produktion daneben
  1.8  10.11.2026  Montagetermin immer änderbar (auch Werkstatt) und im Kalender
                   per Ziehen verschiebbar; Beginn Anfertigung wird beim
                   Verschieben nach Produktion automatisch gesetzt; nur der
                   Fortschrittsbalken in Ampel Rot-Orange-Gelb-Grün; Meine ToDos
                   als Wochenansicht mit KW und Tagen; Projekt öffnet immer oben;
                   Board startet mit Auftrag, Produktion und ToDo aufgeklappt
  1.9  10.11.2026  AV-Stand im Projekt wählbar (Auftrag erteilt / AV läuft /
                   AV fertig – bereit für Produktion), Karten in der Spalte
                   Auftrag mit rotem, gelbem bzw. grünem Rand; Aufmaß und CAD
                   aus den Werkstatt-Schritten entfernt
  1.10 10.11.2026  Termine ändern mit Bestätigung: Datumsfelder im Projekt
                   (Erstkontakt, Montage), Tagesauswahl im Reiter Termine und
                   Verschieben im Kalender fragen „Ja, ändern“ / „Abbrechen“;
                   behebt, dass beim Eintippen eines Datums zu früh gespeichert
                   und das Feld zurückgesetzt wurde
  1.11 11.11.2026  Montagedatum (und Erstkontakt) im Projekt mit ✕ ganz
                   löschbar, ebenfalls mit Rückfrage „Ja, löschen“
```
