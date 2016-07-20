FROM apachegeode/geode:1.0.0-incubating.M2
EXPOSE 40404
ADD scripts /scripts
RUN mkdir -p /data
RUN mkdir -p /home/vcap
WORKDIR /home/vcap
ENTRYPOINT /scripts/gfshWrapper.sh gfsh start server --name=$HOSTNAME --locators=$LOCATOR_IP[10334] --server-port=40404 --max-heap=1G
