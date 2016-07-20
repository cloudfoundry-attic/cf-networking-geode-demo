FROM apachegeode/geode:1.0.0-incubating.M2
RUN yum install -y iproute
EXPOSE 10334
ADD scripts /scripts
RUN mkdir -p /home/vcap
RUN mkdir -p /locator
WORKDIR /home/vcap
ENTRYPOINT /scripts/gfshWrapper.sh gfsh start locator --J="-Dgemfire.jmx-manager-hostname-for-clients=$(/sbin/ip addr | grep 10.255 | cut -d ' ' -f 6 | cut -d '/' -f1)" --hostname-for-clients=$(/sbin/ip addr | grep 10.255 | cut -d ' ' -f 6 | cut -d '/' -f1) --dir=/home/vcap --name=locator --mcast-port=0
