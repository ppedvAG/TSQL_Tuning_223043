--Kompression
--für Client komplett transparent (bei SELECT wird dekomprimiert, User sieht nix)
--Tabellen -> Zeilen- und Seitenkompression
--40%-60% Platzersparnis

USE Demo;

--Große Tabelle erzeugen
SELECT  c.CustomerID
		, c.CompanyName
		, c.ContactName
		, c.ContactTitle
		, c.City
		, c.Country
		, o.EmployeeID
		, o.OrderDate
		, o.freight
		, o.shipcity
		, o.shipcountry
		, o.OrderID
		, od.ProductID
		, od.UnitPrice
		, od.Quantity
		, p.ProductName
		, e.LastName
		, e.FirstName
		, e.birthdate
INTO dbo.KundenUmsatz
FROM	Northwind.dbo.Customers c
		INNER JOIN Northwind.dbo.Orders o ON c.CustomerID = o.CustomerID
		INNER JOIN Northwind.dbo.Employees e ON o.EmployeeID = e.EmployeeID
		INNER JOIN Northwind.dbo.[Order Details] od ON o.orderid = od.orderid
		INNER JOIN Northwind.dbo.Products p ON od.productid = p.productid

INSERT INTO KundenUmsatz
SELECT * FROM KundenUmsatz
GO 9 --Viele Daten erzeugen

SELECT COUNT(*) FROM KundenUmsatz;

SET STATISTICS time, io ON;
SELECT * FROM KundenUmsatz;
--Reads: 41312, CPU: 3s, Gesamt 16.2s

DBCC showcontig('KundenUmsatz');
--Seiten: 41312, Dichte: 98.16%

--Nach Row Compression (322MB -> 179MB, ~45%)
SELECT * FROM KundenUmsatz;
--Reads: 22863, CPU: 4.4s, Gesamt: 23.5s

DBCC showcontig('KundenUmsatz');
--Seiten: 22863, Dichte: 98.96%

--Nach Page Compression (322MB -> 83MB, ~75%)
SELECT * FROM KundenUmsatz;
--Reads: 10680, CPU: 4.4s, Gesamt: 16.7s

DBCC showcontig('KundenUmsatz');
--Reads: 10680, Dichte: 99.28%

--Bestimmte Partition komprimieren
ALTER TABLE pTable REBUILD PARTITION = 1 WITH(DATA_COMPRESSION = ROW);

SELECT
COUNT(*)*8/1024 AS MB,
DB_NAME(database_id)
FROM sys.dm_os_buffer_descriptors
GROUP BY DB_NAME(database_id), database_id
ORDER BY MB DESC;

DBCC freeproccache();