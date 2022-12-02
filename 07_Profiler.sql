--Profiler: Live mitverfolgen was auf der Datenbank passiert
--Tools -> SQL Server Profiler

--Name: Dateiname
--Template: Tuning
--Save to File: Dateinamen
--File Rollover aktivieren
--Enable Stop Trace Time: Duration 30min

--Events: SP:StmtStarting, SP:StmtStopping, SP:BatchStarted, SP:BatchCompleted, ...
--ColumnFilter: DatebaseName Like <Name> (muss als Spalte aktiviert werden)

SELECT * FROM KundenUmsatz; --Abfrage ist im Profiler sichtbar

--Tuning Advisor
--Tools -> Database Engine Tuning Advisor

--braucht ein .trc File (vom Profiler)
--Datenbank für Workload auswählen (tempdb)
--Datenbank auswählen (Demo) oder einzelne Tabellen

--Indizes, filtered Indizes, Columnstore Indizes oder Partitionen
--Start Analysis

--Ergebnisse auswählen die implementiert werden sollen -> Select recommendation
--Action -> Apply Recommendations