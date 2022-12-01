USE Demo;

--Partition Function
--Werden verwendet um Daten auf Partitionen aufzuteilen
--Benötigt ein Partitionsschema
CREATE PARTITION FUNCTION pf_Zahl(int)
AS
RANGE LEFT FOR VALUES (100, 200); --Ranges festlegen von links (0-100, 101-200, 201-unendlich)

--Partitionsfunktion testen
SELECT $partition.pf_Zahl(50);
SELECT $partition.pf_Zahl(150);
SELECT $partition.pf_Zahl(250);

--Partitionsschema
--Legt fest welche File Gruppe welchen Datensatz bekommt
--Benötigt eine Partitionsfunktion
--Benötigt eine FileGroup + ein File pro Range
CREATE PARTITION SCHEME sch_Zahl
AS
PARTITION pf_Zahl TO (Bis100, Bis200, Ab201);

--Mit ON <Partitionsschema>(<Spalte>) Tabelle auf ein Schema legen
CREATE TABLE pTable (id int identity, partitionNumber int, test char(5000)) ON sch_Zahl(partitionNumber);

DECLARE @i int = 0;
WHILE @i < 20000
BEGIN
	INSERT INTO pTable VALUES (@i, 'XY');
	SET @i += 1;
END

SET STATISTICS time, io ON;

SELECT * FROM pTable WHERE partitionNumber = 150;
--Reads: 100, CPU: 0ms, Gesamt: 0ms
--150 kann nur in der mittleren Partition sein

SELECT * FROM pTable WHERE partitionNumber = 50;
--Reads: 101, CPU: 0ms, Gesamt: 0ms

SELECT * FROM pTable WHERE partitionNumber = 2000;
--Reads: 19799, CPU: 31ms, Gesamt: 51ms
--Große Partition musste durchsucht werden, kleine Partitionen wurden weggelassen

--Neue Grenze einfügen
--Davor neue FileGroup + File erstellen

ALTER PARTITION SCHEME sch_Zahl NEXT USED bis5000; -----bis100-----bis200-----ab201-----bis5000-----
ALTER PARTITION FUNCTION pf_Zahl() SPLIT RANGE(5000); --Neue Range hinzufügen -----100-----200-----5000-----

SELECT $partition.pf_Zahl(6000); --Partition 4

ALTER PARTITION FUNCTION pf_Zahl() MERGE RANGE(100); --Teil einer Range entfernen (100) -> (200, 5000)

CREATE TABLE archiv(id int identity, partitionNumber int, test char(5000)) ON bis200;

ALTER TABLE pTable SWITCH PARTITION 1 TO archiv; --Datensätze von einer Partition ins Archiv bewegen

SELECT * FROM archiv;
SELECT * FROM pTable;

