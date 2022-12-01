/*
	Normalerweise:
	1. Jede Zelle hat einen Wert
	2. Jeder Datensatz hat einen PK
	3. Keine Beziehungen zwischen nicht-PK Spalten

	Redundanz verringern (Daten nicht doppelt speichern)
	- Beziehungen zwischen Tabellen
	PK -- Beziehung -- FK

	Kundentabelle: 1 Mio. Datens�tze
	Bestellungen: 2 Mio. Datens�tze
	Bestellungen -> Beziehung -> Kunden
*/

/*
	8192 Bytes gesamt
	132 Byte f�r Management Daten
	8060 Byte f�r tats�chliche Daten

	Max. 700 Datens�tze
	Leerer Raum kann existieren
	Seiten werden 1:1 geladen
*/

CREATE DATABASE Demo;
USE Demo;

CREATE TABLE T1 (id int identity, test char(4100)); --Absichtlich ineffiziente Tabelle

INSERT INTO T1
SELECT 'xy'
GO 20000 --GO <Zahl>: f�hrt einen Befehl X-mal aus

--DBCC: Database Console Commands
dbcc showcontig('T1');

--Wie gro� ist die Tabelle?
--4100B * 20000 = 80MB, .mdf hat aber 200MB

CREATE TABLE T2 (id int identity, test varchar(max));

INSERT INTO T2
SELECT 'xy'
GO 20000

--Durch 700 Datens�tze "nur" 93.87%
dbcc showcontig('T2');

--Gibt verschiedene Page-Daten �ber die Tabellen zur�ck
SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED');

--Object ID �ber Tabellenname finden
SELECT OBJECT_ID('T1'); --581577110

--Bestimmte Tabelle anschauen mit WHERE
SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED')
WHERE object_id = OBJECT_ID('T1');

USE Northwind;

--Customers Tabelle: CustomerID ist ein nchar(5) -> 10 Byte pro Datensatz, k�nnte ein char(5) sein -> 5 Byte pro Datensatz
DBCC showcontig('Customers');

--INFORMATION_SCHEMA: Gibt verschiedene Informationen �ber die Datenbank zur�ck
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Customers';
--nvarchar kann auf varchar optimiert werden in mehreren Spalten

--Zeigt die Ausf�hrungszeiten und Lesevorg�nge einer Abfrage an
SET STATISTICS time, io ON;

USE Demo;

SELECT * FROM T1;
--Logische Lesevorg�nge: 20000 (weil 20000 Seiten), CPU-Zeit: 125ms, Gesamtzeit: 765ms
--Lesevorg�nge m�glichst reduzieren, danach Gesamtzeit, danach CPU-Zeit

SELECT * FROM T2;
--Logische Lesevorg�nge: 50, CPU-Zeit: 79ms, Gesamtzeit: 216ms
--weniger Lesevorg�nge -> weniger Gesamtzeit

SELECT * FROM T1 WHERE id = 50;
--Logische Lesevorg�nge: 20000, CPU-Zeit: 16ms, Gesamtzeit: 19ms
--Nicht relevante Datens�tze einfach �berspringen

SELECT TOP 1 * FROM T1 WHERE id = 50;
--Logische Lesevorg�nge: 50, CPU-Zeit: 0ms, Gesamtzeit: 0ms
--Durch TOP 1 wird bei dem ersten Datensatz aufgeh�rt

--Seiten reduzieren
--Bessere Datentypen oder durch Redesign (mehr Tabellen und Beziehungen)
--Bessere Verteilung der Daten, andere Schl�ssel, ...

--1 Mio. * 2DS/Seite -> 500000 Seiten -> 4GB
--1 Mio. * 50DS/Seite -> 12500 Seiten -> 110MB

SET STATISTICS time, io OFF

CREATE TABLE T3 (id int identity, test nvarchar(max));

INSERT INTO T3
SELECT 'xy'
GO 20000

DBCC showcontig('T2'); --50 Seiten
DBCC showcontig('T3'); --55 Seiten durch nvarchar

--Northwind
--CustomerID = nchar(5) -> char(5)
--varchar(50) -> standardm��ig 4B
--nvarchar(50) -> 2 * 4B = 8B
--text: Deprecated seit 2005

--float: 4B bei kleinen Zahlen, 8B bei gro�en Zahlen
--decimal(X, Y): je weniger Platz desto weniger Byte

--tinyint: 1B, smallint: 2B, int: 4B, bigint: 8B

USE Northwind;

SET STATISTICS time, io ON;

SELECT * FROM Orders WHERE YEAR(OrderDate) = 1997; --YEAR am besten
SELECT * FROM Orders WHERE OrderDate BETWEEN '19970101' AND '19971231';
SELECT * FROM Orders WHERE OrderDate >= '19970101' AND OrderDate <= '19971231';