Modulename: Auditing  
Kurzbeschrieb: Alle Aktionen welche im User Interface oder durch das Reporting ausgeführt werden, sollen in ein Remote Log geschrieben werden. (Beispiel remote syslog Server)  
Wichtige Funktionen: Logging von Reporting und User Aktionen.  
Abhängigkeiten: Damit das Logging funktioniert, müssen vom Interface und vom Reporting Logs gesendet werden. Ausserdem ist ein syslog Server (oder ähnliches) benötigt.  

Modulename: Reporting  
Kurzbeschrieb: Reports anhand von gewünschten Einstellungen durchführen und diese in ein gewünschtes Format bringen. (Beispiel PDF). Reports sollen von Hand (per UI) oder als regelmässiger Job ausgeführt werden können.  
Wichtige Funktionen: Reports generieren und verschicken.  
Abhängigkeiten: Das Reporting ist teils vom UI abhängig, da darüber die Einstellungen für die Reports gemacht werden.  

Modulename: IST-SOLL Vergleich  
Kurzbeschrieb: Eine zentrale Funktion des Programms. Hier soll der gewünschte Berechtigungs-Zustand (SOLL) eingelesen und mit dem momentanen Zustand (IST) verglichen werden können. Daraus sollen dann Abweichungen der beiden Zustände ersichtlich werden.  
Wichtige Funktionen: Delta der beiden Zustände eruieren.  
Abhängigkeiten: Der IST-SOLL Vergleich ist primär vom Datencontainer abhängig. Dort sind sowohl IST als auch SOLL Zustand gespeichert, weswegen der Vergleich nur funktioniert wenn diese Daten vom Datencontainer geholt werden können.  

Modulename: (OPTION) Remediation  
Kurzbeschrieb: Dies ist eine Option welche in einer späteren Phase des Projekts (falls genügend Zeit vorhanden ist) eingebaut werden kann. Damit soll es Möglich sein beim IST-SOLL Vergleich gewisse Deltas direkt im AD angleichen zu können.  
Wichtige Funktionen:  Angleichung von Differenzen der Zustände direkt im AD.  
Abhängigkeiten:  IST-SOLL Vergleich  
