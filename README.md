# Proxmox 4.X Load-Balanced Live-Migration 

Proxmox bietet die Live-Migration von virtuellen Maschinen an, jedoch muss immer händisch eine Node ausgewähl werden, auf die migriert werden soll.

Zur Automatisierung von Updates und Systemneustarten soll jede VM auf den Host mit der derzeitig geringsten CPU-Auslastung migriert werden, außerdem sollen die VM's nach dem Neustart des Systems wieder auf die entsprechende Node zurückgeholt werden.

Ratschläge und Hinweise zur Verbesserung sind ausdrücklich erwünscht!

## Features:
- Berücksichtigung der Node-CPU-Werte der letzten 10 Minuten
- Nodes nach CPU oder RAM gewichten
- Auslesen der Nodes aus "pvecm nodes"
- Node-Offline-Detection
- Angabe einer Quorum-Node möglich, die nicht zur Virtualisierung benutzt werden soll
- Auswerfen lokaler CD/DVD-Images
- Warten zwischen Migrationen um aktualisierte CPU/RAM-Daten zu erhalten
- automatisches Zurückholen der VM's

## Usage:
Kann als Cronjob, via Ansible, etc. gestartet werden.

#### Verschieben aller VM's:
- _bash migrate_all.sh (-q quorum-node)_

#### Zurückholen der VM's:
- _bash get_back.sh_

## Output:
**qm list**
```
      VMID NAME                 STATUS     MEM(MB)    BOOTDISK(GB) PID       
       102 test1                stopped    1024              32.00 0         
       103 noHAtest             stopped    2048              10.00 0         
       210 HAtest               running    2048              16.00 132336 
```

**migrate_all.sh**
  - kein Output wenn keine VM's vorhanden sind
  - bei Migration von VM's:
  ```
Niedrigste CPU-Auslastung der letzten 10 Minuten: host-geb06-2
Niedrigste RAM-Auslastung: host-geb06-2


################ CPU ###################
host-geb06-2:  0.34
host-geb01-1:  0.36
host-geb03-1:  0.38
host-geb01-2:  0.49
host-geb06-1:  0.51

################ RAM ###################
host-geb06-2:  188.80078125000000000000
host-geb06-1:  188.80078125000000000000
host-geb03-1:  188.80078125000000000000
host-geb01-2:  188.80078125000000000000
host-geb01-1:  188.80078125000000000000


Verschiebe VM 102 nach host-geb06-2


Warte 10 Minuten

Niedrigste CPU-Auslastung der letzten 10 Minuten: host-geb06-2
Niedrigste RAM-Auslastung: host-geb06-2


################ CPU ###################
host-geb06-2:  0.34
host-geb01-1:  0.36
host-geb03-1:  0.37
host-geb01-2:  0.48
host-geb06-1:  0.50

################ RAM ###################
host-geb06-2:  188.80078125000000000000
host-geb06-1:  188.80078125000000000000
host-geb03-1:  188.80078125000000000000
host-geb01-2:  188.80078125000000000000
host-geb01-1:  188.80078125000000000000

migration aborted
Fehler auf VM: 103
Lokales CD/DVD-Image gefunden:
ide2: local:iso/bl-Hydrogen-amd64_20160710.iso,media=cdrom,size=843M
Entferne CD/DVD-Image ide2...ok

VM nicht migriert, Wartezeit überspringen

Niedrigste CPU-Auslastung der letzten 10 Minuten: host-geb06-2
Niedrigste RAM-Auslastung: host-geb03-1


################ CPU ###################
host-geb06-2:  0.34
host-geb01-1:  0.36
host-geb03-1:  0.37
host-geb01-2:  0.48
host-geb06-1:  0.50

################ RAM ###################
host-geb03-1:  188.80175781250000000000
host-geb06-2:  188.80078125000000000000
host-geb06-1:  188.80078125000000000000
host-geb01-2:  188.80078125000000000000
host-geb01-1:  188.80078125000000000000


Verschiebe VM 210 nach host-geb06-2


Warte 10 Minuten

Niedrigste CPU-Auslastung der letzten 10 Minuten: host-geb01-1
Niedrigste RAM-Auslastung: host-geb06-2


################ CPU ###################
host-geb01-1:  0.35
host-geb03-1:  0.36
host-geb06-2:  0.39
host-geb01-2:  0.48
host-geb06-1:  0.49

################ RAM ###################
host-geb06-2:  188.80078125000000000000
host-geb06-1:  188.80078125000000000000
host-geb03-1:  188.80078125000000000000
host-geb01-2:  188.80078125000000000000
host-geb01-1:  188.80078125000000000000


Lokale Festplatte von VM  103  migriert.


Verschiebe VM 103 nach host-geb01-1

  ```
  
**get_back.sh**
  - kein Output wenn keine VM's zurückzuholen sind
  - Bei Zurückmigrieren von VM's:
  ```
VM 102 erfolgreich zurück migriert!

HA Migration für VM 210 angestoßen!

Lokale Festplatte von VM 103 migriert!

VM 103 erfolgreich zurück migriert!
  ```
