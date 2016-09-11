FROM openjdk:8-jre
MAINTAINER Christian Cassar <ccassar@cisco.com>

RUN http_proxy="" apt-get update -q && \
    http_proxy="" DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    unzip \
    wget \
    ruby \
    ruby-dev

ENV LOGSTASH_VERSION LOGSTASH_VERSION_PLACEHOLDER

# Install Protoc 3.0.0
RUN https_proxy="" wget https://github.com/google/protobuf/releases/download/v3.0.0/protoc-3.0.0-linux-x86_64.zip
RUN unzip protoc-3.0.0-linux-x86_64.zip
RUN cp bin/protoc /usr/bin/protoc

#
# Define where we mount logs on host
#
VOLUME ["/data"]

#
# Pull and install logstash
#
RUN https_proxy="" curl -s https://download.elasticsearch.org/logstash/logstash/logstash-$LOGSTASH_VERSION.tar.gz | tar xz -C /opt
RUN ln -s /opt/logstash-$LOGSTASH_VERSION /opt/logstash

#
# Setup our plugins
#
ADD .builder /.builder
RUN http_proxy="" /opt/logstash/bin/plugin install --no-verify logstash-mixin-http_client
RUN http_proxy="" find /.builder -name *.gem -exec /opt/logstash/bin/plugin install --no-verify {} +

#
# Start up script which reworks config based on env variables if
# necessary.
#
ADD start.sh /start.sh
RUN chmod +x /start.sh
CMD '/start.sh'
