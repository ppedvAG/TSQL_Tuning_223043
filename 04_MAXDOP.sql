--MAXDOP
--Maximum Degree of Parallelism

--ab einem Kostenschwellwert von 5 wird die Abfrage parallelisiert

--MAXDOP konfigurierbar auf 3 Ebenen: Server, DB, Query
--Query > DB > Server

SET STATISTICS time, io ON;

SELECT freight, birthdate FROM KundenUmsatz WHERE freight > 1000;
--Im Plan sichtbar mit 2 schwarzen Pfeilen im gelben Kreis auf der Abfrage
--Number of Executions: Anzahl Kerne
--Bei SELECT ganz links: Degree of Parallelism

SELECT freight, birthdate
FROM KundenUmsatz
WHERE freight > 1000
OPTION (MAXDOP 8); --OPTION (MAXDOP <Anzahl>)
--MAXDOP 8: 328ms, Gesamt: 129ms
--MAXDOP 4: 282ms, Gesamt: 106ms
--MAXDOP 1: 219ms, Gesamt: 211ms -> dauert länger

SELECT *, YEAR(OrderDate), CONCAT_WS(' ', FirstName, LastName)
FROM KundenUmsatz
WHERE Country IN(SELECT Country FROM KundenUmsatz WHERE Country LIKE 'A%');
--CPU: 1218ms, Gesamt: 1.5s

SELECT *, YEAR(OrderDate), CONCAT_WS(' ', FirstName, LastName)
FROM KundenUmsatz
WHERE Country IN(SELECT Country FROM KundenUmsatz WHERE Country LIKE 'A%')
OPTION (MAXDOP 4);
--CPU: 1188ms, Gesamt: 1.5s

SELECT *, YEAR(OrderDate), CONCAT_WS(' ', FirstName, LastName)
FROM KundenUmsatz
WHERE Country IN(SELECT Country FROM KundenUmsatz WHERE Country LIKE 'A%')
OPTION (MAXDOP 1);
--CPU: 1172ms, Gesamt: 2s