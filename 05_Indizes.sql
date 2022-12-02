USE Demo;

SELECT * FROM KundenUmsatz; --Table Scan da kein Index vorhanden

/*
Heap: Tabelle in unsortierter Form (alle Daten)

Non-Clustered Index (NCIX):
Baumstruktur (von oben nach unten)
Maximal 1000 Stück pro Tabelle
Sollte auf häufig angewandte SQL-Statements angepasst werden
Auch auf Spalten die oft mit WHERE gesucht werden

Clustered Index (CIX):
Maximal 1 pro Tabelle
Am besten auf ID Spalte
Wird immer automatisch sortiert (bei INSERT wird der Datensatz automatisch an der richtigen Stelle eingefügt)
Sollte vermieden werden auf Tabellen mit vielen INSERTs -> viele Sortierungen

Table Scan: Suche die ganze Tabelle
Index Scan: Durchsuche den ganzen Index
Index Seek: bestimmte Daten im Index suchen (beste)
*/

USE Northwind;

--Clustered Index
SELECT * FROM Orders; --Clustered Index Scan (Kosten: 0.0182)
SELECT * FROM Orders WHERE OrderID = 10248; --Clustered Index Seek (Kosten: 0.0032)
INSERT INTO Customers (CustomerID, CompanyName) VALUES ('PPEDV', 'ppedv AG'); --Clustered Index Insert (Kosten: 0.05 da Sortierung)

USE Demo;

SET STATISTICS time, io ON;

SELECT * INTO KundenUmsatz2 FROM KundenUmsatz; --Neue Tabelle anlegen um Kompression zu entfernen

SELECT * FROM KundenUmsatz2; --Reads: 41329, CPU: 2.8s, Gesamt: 17s, Kosten: 30.6

ALTER TABLE KundenUmsatz2 ADD ID int identity primary key; --ID hinzufügen, Clustered Index automatisch

SELECT * FROM KundenUmsatz2; --Reads: 41957 -> Index Seiten müssen gelesen werden

SELECT * FROM KundenUmsatz2 WHERE ID = 50;
--Clustered Index Seek
--Reads: 3

SELECT * FROM KundenUmsatz2 WHERE ID = 50;
--Table Scan ohne Index -> Primärschlüssel kann nur einmal vorkommen, deshalb schnell
--Reads: 42168

--Alle Indexdaten der Datenbank anzeigen
--Indexbaum auch sichtbar
SELECT OBJECT_NAME(object_id), * FROM sys.dm_db_index_physical_stats(DB_ID(),0,-1,0,'DETAILED');

SELECT * FROM KundenUmsatz2 WHERE freight > 50;
--Index Seek über den NCIX_Freight Index
--Reads: 21451, CPU: 1.4s, Gesamt: 9.4s, Kosten: 16.7
--Reads: 42243, CPU: 1.2s, Gesamt: 9s, Kosten: 32.4

SELECT ID, birthdate FROM KundenUmsatz2 WHERE freight > 50; --Auch über NCIX_Freight gegangen

SELECT ID, birthdate FROM KundenUmsatz2 WHERE freight > 1000;
--NCIX_Freight entfernen (Index mit allen Spalten)
--Neuen Index anlegen mit nur ID als Included Column
--Key Lookup: Lookup über Index, Spalten die nicht im Index enthalten sind ohne Scan holen

SELECT CompanyName, birthdate FROM KundenUmsatz2 WHERE freight > 1000;
--Heap Lookup: Datensätze innerhalb der Seiten anschauen und so die Spalten holen
--Index ohne birthdate: Reads: 2064, CPU: 15ms, Gesamt: 122ms, Kosten: 6.8
--Index mit birthdate: Reads: 17, CPU: 0ms, Gesamt: 68ms, Kosten: 0.02

SELECT * FROM KundenUmsatz2; --Table Scan, da nicht über einen Indexteil gegangen werden kann

SELECT * FROM KundenUmsatz2 WHERE freight > 50; --Table Scan, da nicht über einen Indexteil gegangen werden kann

SELECT * FROM KundenUmsatz2 WHERE ID > 50 AND CustomerID LIKE 'A%'; --NCIX_ID_CustomerID Index wird verwendet

SELECT * FROM KundenUmsatz2 WHERE ID < 50; --Index wird nicht verwendet, weil nur teilweise im WHERE vorhanden

SELECT * FROM KundenUmsatz2 WHERE ID > 50 AND CustomerID LIKE 'A%' AND freight > 50;
--Index wird verwendet weil der Index vollständig im WHERE enthalten

SELECT * FROM KundenUmsatz2 WHERE CustomerID LIKE 'A%' AND ID > 50;
--Reihenfolge der Key-Columns relevant (Table Scan statt Index Seek bei anderer Reihenfolge der Index Spalten)

--Indizierte View
GO
CREATE VIEW IxDemo
AS
SELECT Country, COUNT(*) AS Anz
FROM KundenUmsatz2
GROUP BY Country;
GO

SELECT * FROM IxDemo; --Table Scan
GO

--WITH SCHEMABINDING: Verhindert Änderungen an der Tabelle dahinter
--Fehlermeldung wenn originale Tabelle verändert werden soll
ALTER VIEW IxDemo WITH SCHEMABINDING
AS
SELECT Country, COUNT_BIG(*) AS Anz --COUNT_BIG() statt COUNT() notwendig
FROM dbo.KundenUmsatz2 --dbo davor schreiben
GROUP BY Country;
GO

--Jetzt kann ich einen Index erstellen
SELECT * FROM IxDemo; --Index Scan
SELECT * FROM IxDemo WHERE Country LIKE 'A%'; --Index Seek

--Index von der View wurde auf die Tabelle übernommen
SELECT Country, COUNT_BIG(*) AS Anz
FROM dbo.KundenUmsatz2
GROUP BY Country;

GO
CREATE VIEW IxDemo2 WITH SCHEMABINDING
AS
SELECT freight FROM dbo.KundenUmsatz2;
GO

--Indizes von der Tabelle sind auch bei der View dabei
SELECT * FROM IxDemo2 WHERE freight > 50;

--Columnstore Index:
--Speichert eine Spalte als "eigene Tabelle"
--kann genau eine Spalte sehr effizient durchsuchen

SET STATISTICS time, io ON;

SELECT ID FROM KundenUmsatz2; --kein Index, Table Scan
--Reads:  42168, CPU: 360ms, Gesamt: 4.2s, Kosten: 32.4

SELECT ID FROM KundenUmsatz2; --normaler NCIX, Index Scan
--Reads: 2472, CPU: 281ms, Gesamt: 4.2s, Kosten: 3.03

SELECT ID FROM KundenUmsatz2; --Columnstore Index (Non-Clustered)
--Reads: 1505, CPU: 187ms, Gesamt: 4.2s, Kosten: 0.2

SELECT ID FROM KundenUmsatz2; --Columnstore Index (Non-Clustered) und normaler index
--Datenbank wählt aus welcher Index für die Aufgabe effizienter ist
--Datenbank hat ColumnStore Index ausgewählt

--Index auf Abfrage anpassen
GO
CREATE PROC p_Test
AS
SELECT LastName, YEAR(OrderDate), MONTH(OrderDate), SUM(UnitPrice * Quantity)
FROM KundenUmsatz2
WHERE shipcountry = 'UK'
GROUP BY LastName, YEAR(OrderDate), MONTH(OrderDate)
ORDER BY 1, 2, 3;

p_Test;

--Bedingung beim Index auch möglich (freight > 50)
SELECT * FROM KundenUmsatz2 WHERE freight > 50; --Index Scan
SELECT * FROM KundenUmsatz2 WHERE freight < 50; --Table Scan

--Indizes warten
--Indizes werden über Zeit veraltet (durch INSERT, UPDATE, DELETE)
--Index aktualisieren, 2 Möglichkeiten
--Reorganize: Index neu sortieren ohne Neuaufbau
--Rebuild: Von Grund auf neu aufbauen

--Top Fragmentierte Indizes anzeigen
--Oberste Zeilen in Betracht ziehen für einen Rebuild
SELECT OBJECT_NAME(object_id), *
FROM sys.dm_db_index_physical_stats(DB_ID(),0,-1,0,'DETAILED')
WHERE index_type_desc LIKE '%INDEX%' AND index_level = 0
ORDER BY avg_fragmentation_in_percent DESC;