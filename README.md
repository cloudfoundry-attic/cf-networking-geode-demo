# Apache Geode demo with CF Container Networking

### To rebuild the docker images
```
docker build -t c2cnetworking/geode-locator -f locator.Dockerfile .
docker build -t c2cnetworking/geode-server -f server.Dockerfile .
```

### To test on CF
assuming you have [container networking](https://github.com/cloudfoundry-incubator/netman-release) set up...

```
cf push geode-locator -o c2cnetworking/geode-locator

cf push geode-server -o c2cnetworking/geode-server --no-start

cf set-env geode-server LOCATOR_IP $(cf ssh geode-locator -c "ip addr | grep 10.255 | cut -d ' ' -f 6 | cut -d '/' -f1")
cf start geode-server
```
