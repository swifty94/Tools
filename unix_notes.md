# UNIX Staff Notes

## System Administration

### Checking .NET Version on Windows
To check the installed .NET Framework version:
```bash
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\full" /v version
```

### SELinux Management
#### Remove SELinux Attributes
If SELinux is disabled, you can remove attributes with:
```bash
find FTACS -exec setfattr -x security.selinux {} \;
```

#### Optimized for Specific File Systems
```bash
find /var/www/html/ \( -fstype ext2 -o -fstype ext3 -o -fstype ext4 -o -fstype btrfs \) -exec setfattr -x security.selinux {} \;
```

---

## Permissions Management

### Adjust File and Directory Permissions
#### Set Directory Permissions
```bash
find FTACS -type d -print0 | xargs -0 chmod 0755
```
#### Set File Permissions
```bash
find FTACS -type f -print0 | xargs -0 chmod 0644
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
find /FTTH/FTACS5/standalone/log/ -type f -name ".log.????-??-??" -print -exec gzip {} \;
```
#### Remove Files Older Than 7 Days
```bash
find ~/Desktop/Copy/Documents/ -type f -mtime +7 -exec rm {} \;
```

#### Crontab Automation
- Add this line to automate the process:
```bash
(crontab -l; echo "0 0 * * * exec find /usr/local/FTACS6/standalone/log/server.log* -type f -mtime +5 -delete") | crontab -
```

---

## Diagnostics and Network Tools

### WiFi Diagnostics
Generate a WiFi scan report:
```bash
sudo iwlist wlp1s0 scan | awk '{ print $1 }' | egrep "(ESSID|Channel|Frequency|Quality)" | \
sed 's/:/          /g' | sed 's/=         /g' | sed '/ESSID/{G;}' | column -t > ip_scan.csv
```

### Check Open ACS Ports
```bash
netstat -an | egrep "(8181|8080|8182|8443)" | grep -v TIME_WAIT | grep -v ESTABLISHED | grep -v unix
```

### STUN Checker
Check STUN server status:
```bash
stun -v demo.friendly-tech.com:3478
```

---

## Advanced Scripting Examples

### Process Logs for Specific IDs
#### Extract Unique CPE IDs
```bash
egrep 'Cpe [0-9]{0,7}' /usr/local/FTACS5/standalone/log/server.log | awk '{print $7}' | sort -u > cpe_id_list_$HOSTNAME.txt
```
#### Process Each CPE ID
```bash
for SN in $(cat cpe_id_list_$HOSTNAME.txt); do grep $SN /usr/local/FTACS5/standalone/log/server.log; done
```

### Large Oracle Traces Cleanup
Remove old trace files:
```bash
for i in /u01/app/oracle/diag/crs/acsdb01/crs/trace/*.trc; do find $i -type f -mtime +5 | xargs rm -f; done
```
Automate with `crontab`:
```bash
(crontab -l; echo "0 01 * * * exec find /u01/app/oracle/diag/crs/acsdb01/crs/trace/*.trm -type f -mtime +5 -delete") | crontab -
```

### Binary Logs Purging
```bash
PURGE BINARY LOGS TO 'mysql-bin.001463';
```

---

## Process Management

### Quick Kill Commands
#### Kill ACS
```bash
for acs in $(ps aux | grep -v grep | grep java | grep Standalone | grep jboss | awk '{print $2}'); do kill -9 $acs; done
```

#### Kill Hazelcast
```bash
for hz in $(ps aux | grep java | grep hazelcast | awk '{print $2}'); do kill -9 $hz; done
```

### Start Services
#### Start Hazelcast
```bash
service hazelcast start
```
#### Start ACS
```bash
service jbossv5 start
```

---

## Additional Tips and Tricks

### Sorting Directory Sizes
```bash
du $path -ah --max-depth=2 2>/dev/null | sort -rh | head -20
```

### Debugging Cron Jobs
Redirect logs for debugging:
```bash
(crontab -l; echo "0 01 * * * /bin/bash /usr/master_dump.sh > /dev/null 2>&1") | crontab -
```

### CPU Usage Report
```bash
top -bn 1 | head | grep "%Cpu(s)" | awk '{print $1 " " $2}'
```

---
