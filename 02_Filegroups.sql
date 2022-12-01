/*
	Dateigruppen:
	[PRIMARY]: Hauptgruppe: enthält Systemdatenbanken, Tabellen sind standardmäßig auf PRIMARY, kann nicht entfernt werden (.mdf)
	Nebengruppen: Datenbankobjekte können auf Nebengruppen gelegt werden (.ndf)
*/

USE Demo;

CREATE TABLE XYZ (id int);

CREATE TABLE XYZ1 (id int) ON [PRIMARY]; --Auf Primärgruppe legen, nur sinnvoll wenn die Primärgruppe nicht die Standardgruppe ist

CREATE TABLE XYZ2 (id int) ON [AKTIV]; --Tabelle auf andere Gruppe legen

--File per Befehl erstellen
ALTER DATABASE Demo ADD FILE
(
	NAME='DemoAktiv',
	FILENAME='C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\DemoAktiv.ndf',
	SIZE=8192KB,
	FILEGROWTH=64MB
);

--Wie bewegt man eine Tabelle auf eine andere FileGroup?
--Tabelle auf der anderen Seite erstellen und Daten bewegen
CREATE TABLE Test (id int) ON [AKTIV];
INSERT INTO Test SELECT * from XYZ;
DROP TABLE XYZ;

--Salamitaktik
--Aufteilung von großen Tabellen auf mehrere kleine Tabellen
--Zusammenbauen mit partitionierter Sicht

CREATE TABLE Umsatz
(
	Datum date,
	Umsatz float
);

DECLARE @i int = 0; --Testtabellen befüllen
WHILE @i < 19000
BEGIN
	INSERT INTO Umsatz VALUES
	(DATEADD(DAY, FLOOR(RAND()*365), '20190101'), RAND() * 1000);
	SET @i += 1;
END

SELECT * FROM Umsatz;

SET STATISTICS time, io OFF;

SELECT * FROM Umsatz WHERE MONTH(Datum) = 1; --Estimated Operator Cost: 0.91

CREATE TABLE Umsatz2021
(
	Datum date,
	Umsatz float
);

DECLARE @i2 int = 0; --Testtabellen befüllen
WHILE @i2 < 20000
BEGIN
	INSERT INTO Umsatz2021 VALUES
	(DATEADD(DAY, FLOOR(RAND()*365), '20210101'), RAND() * 1000);
	SET @i2 += 1;
END

GO
DROP VIEW UmsatzGesamt;
GO
CREATE VIEW UmsatzGesamt
AS
SELECT * FROM Umsatz2019
UNION ALL
SELECT * FROM Umsatz2020
UNION ALL
SELECT * FROM Umsatz2021
GO

SELECT * FROM UmsatzGesamt; --View muss auf alle Tabellen zugreifen

SELECT * FROM UmsatzGesamt WHERE YEAR(Datum) = 2020; --28% Scan auf alle Tabellen (bringt nix, 2020 kann nur in einer Tabelle enthalten sein)

ALTER TABLE Umsatz2019 ADD CONSTRAINT CHK_Year2019 CHECK (YEAR(Datum) = 2019); --Check Constraints hinzufügen
ALTER TABLE Umsatz2020 ADD CONSTRAINT CHK_Year2020 CHECK (YEAR(Datum) = 2020);
ALTER TABLE Umsatz2021 ADD CONSTRAINT CHK_Year2021 CHECK (YEAR(Datum) = 2021);

SELECT * FROM UmsatzGesamt WHERE YEAR(Datum) = 2020;