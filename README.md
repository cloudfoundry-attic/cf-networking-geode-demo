# Apache Geode demo with CF Container Networking

This is a work in progress.  We haven't yet found a good way to package and configure everything.

### To rebuild the docker images
```
docker build -t c2cnetworking/locator -f locator.Dockerfile .
docker build -t c2cnetworking/server -f server.Dockerfile .
```

### To test on CF
assuming you have [container networking](https://github.com/cloudfoundry-incubator/netman-release) set up...

```
cf push locator -o c2cnetworking/locator -m 1G --health-check-type none
cf push server -o c2cnetworking/server -m 1G  --no-start --no-route --health-check-type none
```

```
cf ssh locator
yum install iproute
ip addr | grep 10.255 # to get the local IP address
```
and edit two files:
- `gemfire.properties` should read:

  ```
  membership-port-range=1025-1027
  ```
- `/etc/hosts` should resemble

  ```
  127.0.0.1 localhost
  10.255.50.10 2c7e8f36-76c9-400b-4bd2-25918ed5c9a8
  10.255.50.14 1182e497-a9ba-464d-7bd5-86c5604d9941
  ```
  where there's an entry for the locator (2nd line) and one for the server (3rd line).  Use the real IP and real hostname of each.

Then do

```
cf set-env server LOCATOR_IP $(cf ssh locator -c "/sbin/ip addr | grep 10.255 | cut -d ' ' -f 6 | cut -d '/' -f1")
cf start server
```

and

```
cf ssh server
yum install iproute
ip addr | grep 10.255 # to get the local IP address
```
and edit two files:
- `gemfire.properties` should read:

  ```
  membership-port-range=1025-1027
  ```
- `/etc/hosts` should look like

  ```
  127.0.0.1 localhost
  10.255.50.14 1182e497-a9ba-464d-7bd5-86c5604d9941
  10.255.50.10 2c7e8f36-76c9-400b-4bd2-25918ed5c9a8
  ```
  where there's an entry for the server (2nd line) and one for the locator (3rd line).  Use the real IP and real hostname of each.


```
# allow ephermeral port access locator <--> server on tcp & udp
cf access-allow locator server --protocol tcp --port 1024
cf access-allow locator server --protocol tcp --port 1025
cf access-allow locator server --protocol tcp --port 1026
cf access-allow locator server --protocol tcp --port 1027

cf access-allow locator server --protocol udp --port 1024
cf access-allow locator server --protocol udp --port 1025
cf access-allow locator server --protocol udp --port 1026
cf access-allow locator server --protocol udp --port 1027

cf access-allow server locator --protocol tcp --port 1024
cf access-allow server locator --protocol tcp --port 1025
cf access-allow server locator --protocol tcp --port 1026
cf access-allow server locator --protocol tcp --port 1027

cf access-allow server locator --protocol udp --port 1024
cf access-allow server locator --protocol udp --port 1025
cf access-allow server locator --protocol udp --port 1026
cf access-allow server locator --protocol udp --port 1027

# allow JMX access locator <--> server <--> server
cf access-allow locator server --protocol tcp --port 1099
cf access-allow server locator --protocol tcp --port 1099
cf access-allow server server --protocol tcp --port 1099

# allow locator to reach back to the server on its port
cf access-allow locator server --protocol tcp --port 40404

# allow server to reach locator
cf access-allow server locator --protocol tcp --port 10334


cf start server
```

once you're done, your access-list should include these rules

```
cf access-list
Listing policies as admin...
OK

Source		Destination	Protocol	Port
locator		server		tcp		1024
locator		server		tcp		1025
locator		server		tcp		1026
locator		server		tcp		1027
locator		server		tcp		1099
locator		server		tcp		40404
locator		server		udp		1024
locator		server		udp		1025
locator		server		udp		1026
locator		server		udp		1027
server		locator		tcp		1024
server		locator		tcp		1025
server		locator		tcp		1026
server		locator		tcp		1027
server		locator		tcp		10334
server		locator		tcp		1099
server		locator		udp		1024
server		locator		udp		1025
server		locator		udp		1026
server		locator		udp		1027
server		server		tcp		1099
```


## Notes
- GemFire needs lots of ports.  [Info about firewalls](http://gemfire.docs.pivotal.io/docs-gemfire/latest/configuring/running/firewalls_ports.html)
- You can run `gfsh` at `/incubator-geode/geode-assembly/build/install/apache-geode/bin/gfsh`
- Inside there, run `connect --locator=10.255.50.6[10334]` to attempt connecting followed by `list members` to confirm, where the IP address is that of the locator.
- Logs go to the current working directory.  On locator, this boots in `/home/vcap`.  If you start `gfsh` from that nested dir, the logs will go below there.


## TODOs
- Figure out a nice way to package this, ideally using the Java buildpack, not Dockerfiles.  We shouldn't have to edit any files on the running container.
- Deal with the hostname issue: we can't tell yet if Geode can deal with just IPs, or if it really needs those entries in the `/etc/hosts` file.
- On servers, expose the REST endpoint on port 8080
- On locator, expose the web UI (PULSE) endpoint.  But we'd need to override to be `$PORT` so that Diego and the CF router can reach it.
