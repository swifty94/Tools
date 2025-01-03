# Linux Staff Notes

## Server Status Checks

### ACS Status Check Script
This script checks the ACS status of servers. Replace `<ACS_Server_IP>` with the actual server IPs.

#### Script
```bash
for i in 0 1 2 3; do 
    status=$(curl -v -utr069:tr069 http://<ACS_Server_IP>.$i:8080/ftacs-basic/ACS 2>&1 | grep "204 No Content" | wc -l);
    echo -e "Server <ACS_Server_IP>.$i ACS status";
    if [[ $status = '1' ]]; then 
        echo -e "Status: $status\n Running=True \n"; 
    else 
        echo -e "Status: $status\n Running=False \n";
    fi;
done;
```

#### Output Example
```
Server <ACS_Server_IP>.0 ACS status
Status: 1
Running=True

Server <ACS_Server_IP>.1 ACS status
Status: 0
Running=False
```

#### Notes
- Ensure the `curl` command is installed and configured properly.
- Replace `<ACS_Server_IP>` with the base IP of the server range.

### Hazelcast Health Check
This script monitors the health of Hazelcast servers in a cluster.

#### Script
```bash
for i in 0 1 2 3; do 
    status=$(curl -I http://<Hazelcast_Server_IP>.$i:8090/hazelcast/health 2>&1 | grep "HTTP/1.1 200 OK" | wc -l);
    size=$(curl -I http://<Hazelcast_Server_IP>.$i:8090/hazelcast/health 2>&1 | grep "Hazelcast-ClusterSize");
    echo -e "Server <Hazelcast_Server_IP>.$i Hazelcast status";
    if [[ $status = '1' ]]; then 
        echo -e "Status: $status\n Up=True\n ClusterSize=$size\n";
    else 
        echo -e "Status: $status\n Up=False \n";
    fi;
done;
```

#### Troubleshooting
- **Connection Errors**: Ensure the Hazelcast server is reachable and ports are open.
- **Invalid Outputs**: Verify the server IPs and health endpoints.

---

## Docker Commands

### CentOS Container on Windows
Easily manage CentOS containers with the following commands:

#### Create a Container
```bash
docker run --name $nameOfContainer -dit centos:latest /bin/bash
```

#### Start the Container
```bash
docker start $nameOfContainer
```

#### Connect to the Container
```bash
docker exec -it $nameOfContainer /bin/bash
```

#### Commit Changes
```bash
sudo docker commit $nameOfContainer [new_image_name]
```

#### Notes
- Replace `$nameOfContainer` with your container name.
- The `commit` command creates a new image based on the container's current state.

---

## .NET Development

### Starting a .NET App
Use the following command to start a .NET application with live updates:
```bash
dotnet watch run
```

### Adding a Component
```bash
dotnet new razorcomponent -n Todo -o Pages
```
Creates a Razor component named `Todo` in the `Pages` directory.

### Creating a Blazor App
```bash
dotnet new blazorserver -o $APP_NAME --no-https -f net5.0
```
Creates a new Blazor Server app targeting .NET 5.

---

## File Operations

### Uploading Files
Use `curl` to upload files to a web server:
```bash
curl -T '$test_file_name' http://<WebDAV_Server_IP>/webdav/ -v
```

### Downloading Files
Download files from a server:
```bash
curl -o '$local_file_name_to_download' http://<WebDAV_Server_IP>/webdav/$test_file_name -v
```

### Using `wget`
```bash
wget --http-user=TR_069 --http-pass=TR_069 http://<WebDAV_Server_IP>:8080/ftacs-basic/ACS
```

#### Notes
- Replace `<WebDAV_Server_IP>` with the appropriate server IP.
- Ensure proper permissions for file operations.

---

## Additional Tips

- **Placeholder Usage**: Replace `<ACS_Server_IP>`, `<Hazelcast_Server_IP>`, and `<WebDAV_Server_IP>` with actual values during deployment.
- **Testing**: Test scripts locally before running in production.
- **Custom Automation**: Modify these scripts to fit specific project requirements.
