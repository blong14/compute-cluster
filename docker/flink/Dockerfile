FROM blong14/flink-arm AS flink
FROM blong14/cluster:arm

# Install dependencies
RUN set -ex \
  && apt-get update \
  && apt-get -y install gettext-base openjdk-11-jre-headless openjdk-11-jdk-headless \
  && rm -rf /var/lib/apt/lists/*

# add Flink from the official Flink image
ENV FLINK_HOME=/opt/flink
ENV PATH=$PATH:$FLINK_HOME/bin

COPY --from=flink $FLINK_HOME $FLINK_HOME

# Install the job server, this will be the Flink entry point
RUN mkdir -p /opt/flink/flink-web-upload
RUN apt-get update && apt-get -y install curl
RUN cd /opt/flink/flink-web-upload && \
	curl -f -O https://repository.apache.org/content/groups/public/org/apache/beam/beam-runners-flink-1.13-job-server/2.31.0/beam-runners-flink-1.13-job-server-2.31.0.jar && \
	ln -s beam-runners-flink-1.13-job-server*.jar beam-runner.jar
RUN echo 'jobmanager.web.upload.dir: /opt/flink' >> $FLINK_HOME/conf/flink-conf.yaml

# entry point for FlinkK8sOperator Flink config
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 6123 8081
CMD ["local"]

