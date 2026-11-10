-- =====================================================================
-- w3rkraum Auftragsboard · Update 1.4: alle Dokumentarten erlauben
-- Einmal im Supabase SQL Editor ausführen (New query -> einfügen -> Run).
-- Danach nimmt der Dokumente-Ordner neben Fotos und PDFs auch z. B.
-- Word, Excel, CAD-Dateien an. Die Grenze von 20 MB je Datei bleibt.
-- =====================================================================
update storage.buckets
   set allowed_mime_types = null,
       file_size_limit    = 20971520
 where id = 'board-dokumente';
