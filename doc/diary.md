# Meetings

## 2018-10-12
### Attendees
* Beat Schärz (pidu2)
* Dario Furigo (VirtSyntaxError)
* Philipp Köfer (kofep1)
* Nicola Michaelis (michn2)

### Agenda
* Database Design (SOLL, Events)
* Mapping SOLL-IST
* GUI Design
* Roles
* Timeplan

### Decisions
* SOLL-IST Comparison 
 * based on ObjectGUID
 * CSV upload does not need ObjectGUID (based on Username)
 * New SOLL Account is also based on Username because there is no IST association (New table withoud Object GUID)
* Logging
 * Logging goes to additional table (File and Syslog is optional)
* Events
 * User is not in Group in IST
 * User is not in Group in SOLL
 * Group is not in Group in IST
 * Group is not in Group in SOLL
 * Wrong Username
 * User not in SOLL
 * User not in IST
 * Group not in SOLL
 * Group not in IST

### ToDo
* Dario -> DB (SOLL, Events)
* Beat -> Logging (DB), SOLL-IST comparison
* Nicola -> GUI
* Philipp -> IST, SOLL


## 2018-10-12
### Attendees
* Beat Schärz (pidu2)
* Dario Furigo (VirtSyntaxError)
* Philipp Köfer (kofep1)
* Nicola Michaelis (michn2)
* Christof Jungo

### Agenda
* Database Design
* Mockups
* Timeplan

### Decisions
* Roles Auditor, DepartmentLead, SysAdmin and ApplOwner
* Syslog Server optional in settings - Log file prefered

### ToDo
* Dario -> DB 
* Beat -> Logging
* Nicola -> GUI, Roles
* Philipp -> IST


## 2018-10-05
### Attendees
* Beat Schärz (pidu2)
* Dario Furigo (VirtSyntaxError)
* Philipp Köfer (kofep1)
* Nicola Michaelis (michn2)
* Christof Jungo

### Agenda
* Projektmanagement Dokumente - wer macht was?
* Zeitplan Project 1

### Decisions
* UniversalDashboard als Framework

### ToDo
* Dario -> Kapitel 4
* Beat -> 5.1 und 5.2
* Nicola -> 5.3 und 5.4
* Philipp -> 5.5

## 2018-09-28
### Attendees
* Beat Schärz (pidu2)
* Dario Furigo (VirtSyntaxError)
* Philipp Köfer (kofep1)
* Nicola Michaelis (michn2)

### Agenda
* Projektmanagement Dokumente
* Stakeholder
* Zugriff auf Azure VM für alle

### Decisions

### ToDo
* siehe 2018-09-26

## 2018-09-26
### Attendees
* Beat Schärz (pidu2)
* Dario Furigo (VirtSyntaxError)
* Philipp Köfer (kofep1)
* Nicola Michaelis (michn2)
* Christof Jungo

### Agenda
* Nicola zeigte Mockups
* Dario zeigte PowerShell UniversalDashboard und PHP Laravel
* Philipp zeigt Power BI von Microsoft
* Philipp zeigt Testumgebung

### Decisions

### ToDo
* Power BI -> Philipp
* Python Framework -> Beat
* UniversalDashboard Prototype -> Dario
* UniversalDashboard Design -> Nicola

## 2018-09-21
### Attendees
* Beat Schärz (pidu2)
* Dario Furigo (VirtSyntaxError)
* Philipp Köfer (kofep1)
* Nicola Michaelis (michn2)
* Christof Jungo

### Agenda
* Brainstorming
* Module und Abhängigkeiten
* Funktionen und Eingrenzung
* Git Repo, Whatsapp Gruppe

### Decisions
* Interface Funktionen und Navigation

### ToDo
* Modulbeschreibung                -> alle
* Research Module                  -> alle
* Allgemeine Suche nach Frameworks -> alle
* Testdaten/Testsystem             -> Philipp
* Projektexcel -> Philipp - done
