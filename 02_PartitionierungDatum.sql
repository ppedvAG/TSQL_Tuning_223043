CREATE PARTITION FUNCTION pf_Datum(datetime)
AS
RANGE LEFT FOR VALUES ('20181231', '20191231', '20201231', '20211231');
--Grenzen sind inklusiv ('20190101') -> Partition 1, würde bei Archivierung mitbewegt werden

CREATE PARTITION SCHEME datum_Scheme
AS
PARTITION pf_Datum TO (Bis2019, Bis2020, Bis2021, Bis2022, BisHeute); --BisHeute = Bis2023

CREATE TABLE Rechnungsdaten (id int identity, rechnungsdatum datetime, betrag float) ON datum_Scheme(rechnungsdatum);

DECLARE @i int = 0;
WHILE @i < 10000
BEGIN
	INSERT INTO Rechnungsdaten VALUES
	(DATEADD(DAY, FLOOR(RAND()*1795), '20180101'), RAND() * 1000);
	SET @i += 1;
END

SELECT * FROM Rechnungsdaten ORDER BY rechnungsdatum;

CREATE TABLE ArchivBis2019 (id int identity, rechnungsdatum datetime, betrag float) ON Bis2019; --Archivtabelle für bis 2019 erstellen

ALTER TABLE Rechnungsdaten SWITCH PARTITION 1 TO ArchivBis2019;

SELECT * FROM ArchivBis2019;

SELECT OBJECT_NAME(object_id), * FROM sys.dm_db_partition_stats; --Partitionsstatistiken auf der Datenbank einsehen

--Gibt eine Übersicht welche Datensätze in welchen Partitionen sind
SELECT
$partition.pf_Datum(rechnungsdatum) AS Partition,
COUNT(*) AS AnzahlDatensätze,
MIN(rechnungsdatum) AS Untergrenze,
MAX(rechnungsdatum) AS Obergrenze
FROM Rechnungsdaten
GROUP BY $partition.pf_Datum(rechnungsdatum);