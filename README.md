# Install BareOS

## Variables

### Server

| Name | Type | Default Value | Action |
|---|---|---|---|
| bareos_release | int/str | 21 | setzt das BareOS Release, welches installiert werden soll.|
| bareos_db_package | str | postgresql-13 | definiert welches Datenbank Packet installiert werden soll. |
| bareos_install_client | bool | false | Regelt ob das BareOS Client Packet auf der Instanze installiert werden soll. |
| bareos_install_server | bool | false | Regelt ob das BareOS Server Packet auf der Instanze installiert werden soll. |
| bareos_setup_db | bool | false | Regelt ob die Datenbank konfiguriert werden soll, setze das Value in den Host Vars des BareOS Server Instance auf `true`. |
| bareos_monitoring_postgres_user | str | "" | Nutzername des Monitoring Users in der Datenbank |
| bareos_monitoring_postgres_pass | str | password | Passwort des Monitoring Users in der Datenbank |
| bareos_setup_webui_admin_console | bool | false | Regelt ob die BareOS WebUI installiert werden soll. |
| bareos_webui_admin_name | str | admin | Admin Nutzername des Default WebUI Nutzers |
| bareos_webui_admin_password | str | secret | Admin Passwort des Default WebUI Nutzers |
| bareos_default_excludes | list | [] | Liste aller Verzeichnisse, die Standartmäßig Exkludiert werden sollen.|
| bareos_default_extra_fileset_opts| str | "" | Default Fileset Extra Optionen |
| bareos_apt_monitoring_packages| list | | Definiert, welche extra packete für das Monitoring installiert werden sollen. |
| bareos_schedules | dict | | Dict bestehend aus weiteren Dicts die, die einzelnen Schedules definieren um sie mit hilfe eines Templates anzulegen.|
| bareos_filesets | dict | | Dict bestehend aus weiteren Dicts die, die einzelnen Filesets definieren um sie mit hilfe eines Templates anzulegen.|
| bareos_jobdefs | dict | | Dict bestehend aus weiteren Dicts die, die einzelnen Jobdefs definieren um sie mit hilfe eines Templates anzulegen.|
| bareos_pools | dict | {} | Dict bestehend aus weiteren Dicts die, die einzelnen Pools definieren um sie mit hilfe eines Templates anzulegen.|
| bareos_director | dict | {} | Dictionary, welches die Keys `ip` und `name` der BareOS Server Instanze beinhaltet. Fügt einen Eintrag für den BareOS Director (Server Instanze) in der Datei `/etc/hosts` für die Namensauflösung hinzu |
| bareos_clients | list | [] | Liste der Clients/Server die von BareOS gebackuped werden sollen |

Beispiele:

Beispiel Konfiguration der `bareos_clients` variable.

```yaml
bareos_clients:
  - name: ubuntu-1604
    ansible_delegate_hostname: ubuntu-1604
    address: 192.168.33.10
    password: password
    jobdefs: DefaultJobLinux
  - name: example-server
    ansible_delegate_hostname: example-server
    address: 10.0.99.100
    password: password
    jobdefs: "DefaultJob-6h"
    enable_backup_job: true
    job:
      config:
        FileSet: "ExampleDatabases"
        Level: Full
        RunScript:
          - FailJobOnError: "Yes"
            RunsOnClient: "Yes"
            RunsWhen: "Before"
            Command: "\"sh -c '/opt/backup-scripts/backup_example_db.sh'\""
```

Beschreibgung der einzelnen `dict` Werte der `bareos_clients`
Variablen die einen Punkt im Namen haben sind geschachtelt. Siehe als Beispiel:
```
job:
  config:
```
wird in der unterigen Tabelle als `job.config` im Variablen Namen gelistet.


| Name | Type | Action |
|---|---|---|
| name | string | Wird genutzt für die Namens generation in den Verschiedenen BareOS Konfigurations Dateien. |
| ansible_delegate_hostname | string | muss einem Hostnamen im Ansible Inventory entsprechen, da dieser Wert verwendet wird um sich auf den Client zu verbinden. |
| password | str | Password was für den Client in den Konfigurations Dateien und bei der Erstellung verwendet werden soll. |
| jobdefs | str | BareOS Jobdefinition die für den Client verwendet werden soll. |
| enable_backup_job | bool | Regelt ob der Job Aktiviert werden soll. Default `true`.|
|job.config| dict | Hier können extra Variabellen für die Job Konfigurationsdatei gesetzt werden. Einfach die Werte als Key, Value Werte mit der Richtigen einrückung eintragen, das einzige zu beachtende ist, sollte ein Key mehrfach in der Generierten Konfiguraitons Datei aufzufinden sein, dann sollte eine Liste für diesen Wert definert werden. Es werden für die Liste sowohl Dicts und String listen unterstützt |

Der zweite Client mit dem Namen `example-server` aus dem obrige Beispiel würde Folgenden Konfigurationsdateien erzeugen.

Auf dem BareOS Server.
`/etc/bareos/bareos-dir.d/client/example-server.conf`
```
Client {
  Name = "example-server"
  Address = 10.0.99.100
  Password = "password"
}
```
`/etc/bareos/bareos-dir.d/job/example-server.conf`

```
# Ansible managed
Job {
  Name = "backup-example-server"
  JobDefs = "DefaultJob-6h"
  Client = "example-server"
  FileSet = ExampleDatabases
  Level = Full
  RunScript {
     FailJobOnError = Yes
     RunsOnClient = Yes
     RunsWhen = Before
     Command = "sh -c '/opt/backup-scripts/backup_example_db.sh'"
  }

}

```

Auf dem Client( Zu backupender Server):

`/etc/bareos/bareos-fd.d/client/myself.conf`
```
# Ansible managed
Client {
  Name = example-server
  Maximum Concurrent Jobs = 20
}
```

