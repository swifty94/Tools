Here is the updated `.md` file containing the requested changes. All specific names, IPs, directories, and schemas have been replaced with generalized placeholders.

```markdown
# SYSADMIN NOTES

## System Administration

### Checking .NET Version on Windows
To check the installed .NET Framework version:
```
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\full" /v version
```

### SELinux Management
#### Remove SELinux Attributes
If SELinux is disabled, you can remove attributes with:
```bash
find folder_name -exec setfattr -x security.selinux {} \;
```

#### Optimized for Specific File Systems
```bash
find /path/to/files \( -fstype ext2 -o -fstype ext3 -o -fstype ext4 -o -fstype btrfs \) -exec setfattr -x security.selinux {} \;
```

---

## Permissions Management

### Adjust File and Directory Permissions
#### Set Directory Permissions
```bash
find folder_name -type d -print0 | xargs -0 chmod 0755
```
#### Set File Permissions
```bash
find folder_name -type f -print0 | xargs -0 chmod 0644
```

#### Verify Permissions
```bash
stat -c "%a %n" -- *
```

---

## Automation and Logs

### Gzip Logs Older than 4 Days
#### Using `find` and `gzip`
```bash
find /path/to/logs/ -type f -name "*.log.????-??-??" -print -exec gzip {} \;
```
#### Remove Files Older Than 7 Days
```bash
find ~/folder_name/ -type f -mtime +7 -exec rm {} \;
```

#### Crontab Automation
- Add this line to automate the process:
```bash
(crontab -l; echo "0 0 * * * exec find /path/to/logs/server.log* -type f -mtime +5 -delete") | crontab -
```

---

## Diagnostics and Network Tools

### WiFi Diagnostics
Generate a WiFi scan report:
```bash
sudo iwlist wlan0 scan | awk '{ print $1 }' | egrep "(ESSID|Channel|Frequency|Quality)" | \
sed 's/:/          /g' | sed 's/=         /g' | sed '/ESSID/{G;}' | column -t > wifi_scan.csv
```

### Check Open Application Ports
```bash
netstat -an | egrep "(port1|port2|port3|port4)" | grep -v TIME_WAIT | grep -v ESTABLISHED | grep -v unix
```

### STUN Checker
Check STUN server status:
```bash
stun -v stun.server.com:3478
```

---

## Advanced Scripting Examples

### Process Logs for Specific IDs
#### Extract Unique IDs
```bash
egrep 'Device [0-9]{0,7}' /path/to/logs/server.log | awk '{print $7}' | sort -u > device_id_list.txt
```
#### Process Each Device ID
```bash
for id in $(cat device_id_list.txt); do grep $id /path/to/logs/server.log; done
```

### Large Trace Files Cleanup
Remove old trace files:
```bash
for i in /path/to/trace/files/*.trc; do find $i -type f -mtime +5 | xargs rm -f; done
```
Automate with `crontab`:
```bash
(crontab -l; echo "0 01 * * * exec find /path/to/trace/files/*.trm -type f -mtime +5 -delete") | crontab -
```

### Binary Logs Purging
```bash
PURGE BINARY LOGS TO 'log-bin.000001';
```

---

## Process Management

### Quick Kill Commands
#### Kill Application Processes
```bash
for proc in $(ps aux | grep -v grep | grep process_name | awk '{print $2}'); do kill -9 $proc; done
```

#### Kill Specific Services
```bash
for service in $(ps aux | grep java | grep service_name | awk '{print $2}'); do kill -9 $service; done
```

### Start Services
#### Start Service1
```bash
service service_name start
```
#### Start Service2
```bash
service service_name2 start
```

---

## Additional Tips and Tricks

### Sorting Directory Sizes
```bash
du /path/to/directory -ah --max-depth=2 2>/dev/null | sort -rh | head -20
```

### Debugging Cron Jobs
Redirect logs for debugging:
```bash
(crontab -l; echo "0 01 * * * /bin/bash /path/to/script.sh > /dev/null 2>&1") | crontab -
```

### CPU Usage Report
```bash
top -bn 1 | head | grep "%Cpu(s)" | awk '{print $1 " " $2}'
```

---

# Database Operations Notes

## Database Operations

### Check Applied Changesets
Retrieve the IDs of the applied changesets:
```sql
SELECT id FROM schema_name.databasechangelog;
```

### Connection Strings
Examples of database connection strings:
```bash
sqlplus user/password@host:port/service
```

#### Examples:
```bash
sqlplus user/pass@127.0.0.1:1521/service_name
sqlplus user/pass@db_host:1521/DB_SERVICE
sqlplus user/password@hostname:1521/service
```

### Backup and Restore with SCN
#### Backup Using SCN
1. Create a backup directory:
   ```sql
   CREATE OR REPLACE DIRECTORY backup_dir AS '/path/to/backup';
   ```

2. Grant permissions:
   ```sql
   GRANT READ, WRITE ON DIRECTORY backup_dir TO user;
   ```

3. Retrieve the current SCN:
   ```sql
   SELECT CURRENT_SCN FROM v$database;
   ```

4. Perform the export:
   ```bash
   nohup expdp user/pass directory=backup_dir dumpfile=dump_file_%U.dmp \
   logfile=export.log schemas=SCHEMA1,SCHEMA2 exclude=statistics \
   parallel=4 FLASHBACK_SCN=$(SCN from step 2) &
   ```

#### Restore Backup
Import the backup file:
```bash
nohup impdp user/pass DUMPFILE=dump_file_%U.dmp schemas=SCHEMA1,SCHEMA2 parallel=4 &
```

---

## MySQL Database Operations

### Connection and Permissions
#### Grant All Privileges
Grant privileges to a user on a specific host:
```sql
GRANT ALL ON *.* TO 'user'@'127.0.0.1' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
```

### Backup and Restore
#### Create a Backup
```bash
mysqldump -u user -p'password' -h 127.0.0.1 --single-transaction --triggers --routines --events \
--databases schema1 schema2 schema3 > /path/to/backup.sql
```

#### Restore a Backup
```bash
mysql -u root -p < /path/to/backup.sql
```

---

## Common Queries

### Top Tables by Size
Retrieve the top 10 largest tables:
```sql
SELECT * FROM (
  SELECT owner, segment_name table_name, bytes/1024/1024/1024 "SIZE (GB)"
  FROM dba_segments
  WHERE segment_type = 'TABLE' AND segment_name NOT LIKE 'BIN%'
  ORDER BY 3 DESC
) WHERE ROWNUM <= 10;
```

### Database Size
Retrieve database size information:
```sql
SELECT table_schema "Database Name", 
       SUM(data_length + index_length) / 1024 / 1024 "Size (MB)" 
FROM information_schema.TABLES 
GROUP BY table_schema;
```

---

## Automation with Liquibase

### Update Database Schema
#### For Database1
```bash
java -jar liquibase.jar --logLevel=info \
  --changeLogFile=com/db/changelog/master_changelog.xml \
  --driver=oracle.jdbc.OracleDriver \
  --classpath=jdbc/ojdbc8.jar \
  --url=jdbc:oracle:thin:@<Host>:<Port>/<Service_Name> \
  --username=user \
  --password=password update
```

#### For Database2
```bash
java -jar liquibase.jar --logLevel=info \
  --changeLogFile=com/db/changelog/master_changelog.xml \
  --driver=com.mysql.cj.jdbc.Driver \
  --classpath=jdbc/mysql-connector-java-8.0.25.jar \
  --url=jdbc:mysql://127.0.0.1/schema \
  --username=user \
  --password=password update
```

---

## Notes

- Replace `<Host>`, `<Port>`, `<Service_Name>`, and placeholders like `<SCN_Value>` with the actual values before execution.
- Always test scripts in a non-production environment to avoid unintended consequences.
- Ensure necessary permissions are granted to execute backups and restores effectively.
```
