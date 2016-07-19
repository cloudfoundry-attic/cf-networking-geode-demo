FROM apachegeode/geode:1.0.0-incubating.M2
EXPOSE 10334
ADD scripts /scripts
ENTRYPOINT /scripts/gfshWrapper.sh gfsh start locator --name=locator --mcast-port=0
