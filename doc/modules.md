**Modulname: Auditing**<br>
Kurzbeschrieb: Alle Aktionen welche im User Interface oder durch das Reporting ausgeführt werden, sollen in ein Remote Log geschrieben werden. (Beispiel remote syslog Server)  
Wichtige Funktionen: Logging von Reporting und User Aktionen.  
Abhängigkeiten: Damit das Logging funktioniert, müssen vom Interface und vom Reporting Logs gesendet werden. Ausserdem ist ein syslog Server (oder ähnliches) benötigt.  

**Modulname: Reporting** <br>
Kurzbeschrieb: Reports anhand von gewünschten Einstellungen durchführen und diese in ein gewünschtes Format bringen. (Beispiel PDF). Reports sollen von Hand (per UI) oder als regelmässiger Job ausgeführt werden können.  
Wichtige Funktionen: Reports generieren und verschicken.  
Abhängigkeiten: Das Reporting ist teils vom UI abhängig, da darüber die Einstellungen für die Reports gemacht werden.  

**Modulname: IST-SOLL Vergleich** <br>
Kurzbeschrieb: Eine zentrale Funktion des Programms. Hier soll der gewünschte Berechtigungs-Zustand (SOLL) eingelesen und mit dem momentanen Zustand (IST) verglichen werden können. Daraus sollen dann Abweichungen der beiden Zustände ersichtlich werden.  
Wichtige Funktionen: Delta der beiden Zustände eruieren.  
Abhängigkeiten: Der IST-SOLL Vergleich ist primär vom Datencontainer abhängig. Dort sind sowohl IST als auch SOLL Zustand gespeichert, weswegen der Vergleich nur funktioniert wenn diese Daten vom Datencontainer geholt werden können.  

**Modulname: (OPTION) Remediation** <br>
Kurzbeschrieb: Dies ist eine Option welche in einer späteren Phase des Projekts (falls genügend Zeit vorhanden ist) eingebaut werden kann. Damit soll es Möglich sein beim IST-SOLL Vergleich gewisse Deltas direkt im AD angleichen zu können.  
Wichtige Funktionen:  Angleichung von Differenzen der Zustände direkt im AD.  
Abhängigkeiten:  IST-SOLL Vergleich  

**Modulname: Datencontainer**<br>
Kurzbeschrieb: Der Datencontainer dient dazu, die vom AD ausgelesenen IST-Daten oder vom User erfassten SOLL-Daten abzuspeichern. Diese Daten können in eine Datenbank oder als Files abgelegt werden. Dieser Datencontainer sollte Skalierbar und Erweiterbar sein.
Wichtige Funktionen: Speichern von Daten, Auslesen von Daten, Organisieren von Daten (Index)
Abhängigkeiten:  SOLL-Daten, IST-Daten, History

**Modulname: History**<br>
Kurzbeschrieb: Die History stellt im Datencontainer fest, dass alle Änderungen der IST-Daten historisch nachvollziehbar sind.
Wichtige Funktionen: Auslesen der historischen Zustände und Speichern des Deltas der IST-Daten.
Abhängigkeiten: Datencontainer, IST-Daten

**Modulname: (OPTION) Fileshares (Permissions)**<br>
Kurzbeschrieb: Dieser Modul ist optional und ermöglich das Sammeln der Berechtigungen auf definierten Filesshares. Es ermöglicht das Auditieren der Berechtigungen.
Wichtige Funktionen: Aulesen von Berechtigungen auf Fileshares
Abhängigkeiten: keine

**Modulname: Auslesen der Daten (Rohdaten)**<br>
Kurzbeschrieb: Dieses Modul dient zum auslesen der Rohdaten aus dem AD und anschliessendes abspeichern im Datencontainer. Diese Funktion sollte skalierbar, aktuell und vollständig sein.
Wichtige Funktionen: Auslesen von Daten, Speichern von Daten
Abhängigkeiten: Datencontainer, Rohdaten (Testdaten)

**Modulname: Testdaten (Testsystem)**<br>
Kurzbeschrieb: Eine Umgebung mit realitätsnahen Testdaten welche wir zum Entwickeln und Testen nutzen können. 
Wichtige Funktionen: Testing, Entwickeln
Abhängigkeiten: keine

**Modulname: Daten SOLL**<br>
Kurzbeschrieb: Der aktuell gewünschte Berechtigungs-Zustand (SOLL) wird im Datencontainer abgespeichert.
Wichtige Funktionen: Bereitstellen des Soll-Zustandes
Abhängigkeiten: Datencontainer

**Modulname: Einlesen Daten SOLL**<br>
Kurzbeschrieb: Die Daten des gewünschten Berechtigungs-Zustands (SOLL) können von den Anwendern importiert/aktualisiert werden. Diese Daten sind in Form eines .CSV-Files vorhanden.
Wichtige Funktionen: Einlesen von .CSV-Files in den Daten SOLL
Abhängigkeiten: Datencontainer, Daten SOLL

**Modulname: (OPTION) Exportieren Daten SOLL**<br>
Kurzbeschrieb: Der aktuell in der Applikation hinterlegte Berechtigungs-Zustands (SOLL) kann in ein .CSV-File exportieren werden. Dient zum anpassen und erneuten importieren des Berechtigungs-Zustands (SOLL).
Wichtige Funktionen: Exportieren des Daten SOLL in ein .CSV-File
Abhängigkeiten: Datencontainer, Daten SOLL

**Modulname: (OPTION) Alarmierung**<br>
Kurzbeschrieb: Ein Modul zur aktiven Alarmierung von bestimmten Administratoren bei Veränderung von Berechtigungen im AD.
Wichtige Funktionen: Alarmierung von Administratoren
Abhängigkeiten: keine
