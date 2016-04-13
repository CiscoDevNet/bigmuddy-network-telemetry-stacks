#!/bin/bash
#
# partly derived from /etc/init/logstash.conf
#

#
# We use mounted volume logging, config and plugins...
#
PATH=/bin:/usr/bin
LS_HOME=/data
LS_HEAP_SIZE="500m"
LS_JAVA_OPTS="-Djava.io.tmpdir=${LS_HOME}"
LS_LOG_FILE=/data/logstash.log
LS_USE_GC_LOGGING=""
LS_CONF_DIR=/data/conf.d
LS_OPEN_FILES=16384
LS_NICE=19
LS_OPTS=""

#
# Compile .proto source
#
test -z "/data/proto" || if [ -n "$(find /data/proto -maxdepth 1 -name '*.proto' -print -quit)" ]
then
    echo "Compiling .proto files"
    find /data/proto -maxdepth 1 -name '*.proto' -print
    GEM_HOME=/opt/logstash/vendor/bundle/jruby/1.9 GEM_PATH=/opt/logstash/vendor/bundle/jruby/1.9/gems PATH=$PATH:/opt/logstash/vendor/jruby/bin /opt/logstash/vendor/bundle/jruby/1.9/bin/ruby-protoc -I /data/proto /data/proto/*.proto
else
    echo "No .proto files to compile"
fi

#
# ... as well as for passing in overrides
#
# Override our defaults with user defaults, if logstash.overrides has
# been provided in host volume.
#
[ -f /data/logstash.overrides ] && . /data/logstash.overrides

HOME="${HOME:-$LS_HOME}"

# Reset filehandle limit
ulimit -n ${LS_OPEN_FILES}
cd "${LS_HOME}"

# Export variables
export PATH HOME LS_HEAP_SIZE LS_JAVA_OPTS LS_USE_GC_LOGGING
test -n "${JAVACMD}" && export JAVACMD

exec nice -n ${LS_NICE} /opt/logstash/bin/logstash agent -f "${LS_CONF_DIR}" -l "${LS_LOG_FILE}" ${LS_OPTS}
