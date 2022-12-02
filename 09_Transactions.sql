--Transactions
--Alle Statements in der Transaction m�ssen fehlerfrei durchgelaufen sein
--Sonst wird alles R�ckg�ngig gemacht

CREATE TABLE Transactions (test varchar(10));

BEGIN TRANSACTION;
	INSERT INTO Transactions VALUES ('Test2');
COMMIT; --�nderungen Final auf die Datenbank schreiben

SELECT * FROM Transactions; --Hier ist die Transaction sichtbar und "fertig", in einer anderen Session ist die �nderung nicht sichtbar

ROLLBACK; --�nderungen in der Transaktion r�ckg�ngig machen

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; --Nicht gemachte �nderungen sind so in anderen Sessions sichtbar
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRANSACTION;
UPDATE Transactions SET test = 'x' WHERE test = 'Test2'; --Nicht Fehlerhaft
UPDATE Transactions SET test = 'TestTestTestTest' WHERE test = 'Test'; --Fehlerhafte Abfrage (SET > varchar(10))
ROLLBACK;

BEGIN TRY --Block der nur vollst�ndig ausgef�hrt wird wenn keine Fehler auftreten
	BEGIN TRANSACTION;
	UPDATE Transactions SET test = 'x' WHERE test = 'Test2'; --Nicht Fehlerhaft
	UPDATE Transactions SET test = 'TestTestTestTest' WHERE test = 'Test'; --Fehlerhafte Abfrage (SET > varchar(10))
	COMMIT;
	Print 'erfolg'
END TRY
BEGIN CATCH --Wenn Fehler auftreten komme ich in diesen Block
	ROLLBACK;
	Print 'fehler'
END CATCH