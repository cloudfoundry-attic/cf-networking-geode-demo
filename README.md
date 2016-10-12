# Apache Geode demo with CF Container Networking

### To rebuild the docker images
```
docker build -t c2cnetworking/geode-locator -f locator.Dockerfile .
docker build -t c2cnetworking/geode-server -f server.Dockerfile .
```

### To test on CF
assuming you have [container networking](https://github.com/cloudfoundry-incubator/netman-release) set up...

```
cf push geode-locator -o c2cnetworking/geode-locator -m 512M

cf push geode-server -o c2cnetworking/geode-server -m 512M --no-start --no-route --health-check-type none

cf set-env geode-server LOCATOR_IP $(cf ssh geode-locator -c "/sbin/ip addr | grep 10.255 | cut -d ' ' -f 6 | cut -d '/' -f1")

cf access-allow geode-server geode-locator --protocol tcp --port 10334

cf start geode-server
```

### Todo
0. The locator seems to be tripped up by multiple interfaces and keeps attempting to connect to 10.254.0.X a garden bridge address, we've specified the jmx-manager hostname and hostname-for-clients as overlay and made progress but there is still more to do
0. There are some high numbered ports being used by gemfire, this is due to a variable that defaults to 1024-65k see: http://gemfire.docs.pivotal.io/docs-gemfire/latest/configuring/running/firewalls_ports.html
0. netstat shows a lot of the open connections as "tcp6", does iptables distinguish between tcp and tcp6 protocols? Do we need to allow tcp6 as a protocol action.

### Troubleshooting
0. manually run gfsh and try to connect. gfsh is located at: `/incubator-geode/geode-assembly/build/install/apache-geode/bin/gfsh`
 - then run `connect --locator=10.255.50.6[10334]` to attempt connecting followed by `list members` to confirm
0. `yum install net-tools` to use `netstat -apee` to discover what ports gemfire is trying to use
0. turn off all firewall rules: `iptables -I FORWARD -s 10.255.50.0/24 -d 10.255.50.0/24 -i cni-flannel0 -j ACCEPT && iptables -I FORWARD -i flannel.1 -j ACCEPT`
