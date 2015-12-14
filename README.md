## Streaming Telemetry Collector Stacks

This repository is made available to support users wishing to experiment with consumption of streaming telemetry using off-the-shelf stacks.

Three different stacks are prepackaged in this repository:

- The `stack_elk` stack deploys a fleet of docker containers with [elasticsearch](https://www.elastic.co/products/elasticsearch), [logstash](https://www.elastic.co/products/logstash) and [kibana](https://www.elastic.co/products/kibana).
- The `stack_prometheus` stack deploys a fleet of docker containers with [logstash](https://www.elastic.co/products/logstash), [prometheus](http://prometheus.io/), [pushgateway](http://prometheus.io/docs/instrumenting/pushing/) and [promdash](http://prometheus.io/docs/visualization/promdash/).
- The `stack_signalfx` stack deploys a `logstash` container configured to feed telemetry into the cloud based [signal fx](https://signalfx.com/solutions/monitoring-for-operations/) monitoring system. Note that, while a free trial is available, the signal fx monitoring service is not free.

A very thin stack (i.e. logstash set up with telemetry input codecs, and [kafka output plugin configuration](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-kafka.html)) is also provided in order to publish telemetry content on to a [kafka bus](http://kafka.apache.org/).

The systems are independent and can be deployed independently or together (UDP/TCP stream endpoint ports may need to be changed in `environment` files).

__Note: The streaming telemetry project is work in progress, and both the on and off box components of streaming telemetry are likely to evolve at a fast pace.__


## Installation

You will need a working [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [docker](https://docs.docker.com/installation/) setup; look for "Docker tips" below if you need help with this. If host is behind an HTTP proxy, refer to the pertinent section below.

Clone the repository, pick the stack you would like to run, and follow the steps below. I use `stack_elk` as an example, but the same applies for `stack_prometheus`, `stack_signalfx` or `stack_kafka`:

```
git clone https://github.com/cisco/bigmuddy-network-telemetry-stacks.git
#
# Change to the directory for the stack of your choice e.g.:
#
cd stack_elk
sudo COLLECTOR=a.b.c.d ./stack_build
```

where `a.b.c.d` is the local IP address you wish to use. `stack_build` is executed to set up the default configurations, build the docker images etc, and is only required once.

Start the fleet of containers using:

```
sudo ./stack_run
```


__This is it__.


At this point your stack should be running and telemetry streams can be pointed at it.

If you are using default configurations, port `2103` will be consumed by `stack_elk`, port `2104` will be consumed by `stack_prometheus`, and port `2105` by `stack_signalfx`. TCP supports compressed JSON, whereas UDP supports protobuf (ELK stack only). The output plugin `telemetry_metrics` used by `stack_prometheus` and `stack_elk` does not support content exported over protobuf.

If you are planning to use UDP/protobuf transport and encoding, then simply place the router generated `.proto` files in the location `\var\local\stack_elk\logstash_data\proto` between running `stack_build` and `stack_run`. If the files change at an point, restart the stack - this will cause the ruby bindings to be rebuilt.

Stopping the stack involves running `stack_stop`.

```
sudo ./stack_stop
```

The stack can be started and stopped over and over (no intervening `stack_build` required). Configuration and data is preserved across stop/run cycles in the [host mounted volumes](https://docs.docker.com/userguide/dockervolumes/). A host mounted volume is a  per-stack-component directory which is mapped into the container.

If the stack is (re)built, configuration files which are copied from the repository are regenerated and any changes to those files in the host mounted volume will be overwritten. Any other data is preserved unless the host mounted volumes are deleted explicitly. If you wish to purge all data and configuration to start from scratch, simply delete the host mounted volumes, and rerun `stack_build`.


## Visualisation

If you are using the default setup, and specified a collector address of `a.b.c.d`, then;

- for `stack_elk` then you can access [kibana](https://www.elastic.co/products/kibana) by pointing your browser at;
```
http://a.b.c.d:5601/
```
- for `stack_prometheus` then you can access [promdash](http://prometheus.io/docs/visualization/promdash/) by pointing your browser at:
```
http://a.b.c.d:3000/
```
- to access prometheus or the gateways directly you can also point at ports 9090, 9091 and 9092 by default.

Below are a couple of dashboard images; one from `stack_elk` and one from `stack_prometheus`:

![Kibana snapshot](/common/png/elk.png?raw=true "Screenshot of kibana")

![Promdash snapshot](/common/png/promdash.png?raw=true "Screenshot of promdash")

### Note about `signal fx` stack

In order to use `stack_signalfx`, registration is required at https://signalfx.com/. Once registered, an organisation API Token can be retrieved from the profile page. This token should be setup in the `stack_signalfx/src/environment` as shown here (note the token is not made up in the example):

```
export SIGNALFXTOKEN="DuMMyExaMPLeT0KEn"
```

Streams should be pointed at the `logstash` setup as for the other stacks. Go to `https://app.signalfx.com/` to visualise the data. The Usage Metric dashboard should show some number of datapoints received per second. Below is an example of dashboard setup to show IP SLA and interface counter data.

![Signalfx snapshot](/common/png/signalfxjitter.png?raw=true "Screenshot of Signal FX dashboard")

### Note about `kafka` stack

The minimum required configuration for the kafka stack is, as with all stacks, listed at the top of the `environment` file, and needs to be set prior to `stack_build`. Alternatively it can be set in the running configuration; by default `/var/local/stack_kafka/logstash_data/conf.d/ls_telemetry.conf`. Changes here would be overwritten if the stack is rebuilt.

## Building a production system?

We have made the logstash codecs and output plugins used in the stacks in this repository available independently of the stacks. Pertinent repositories are `logstash-codec-bigmuddy-network-telemetry`, `logstash-codec-bigmuddy-network-telemetry-gpb` and `logstash-output-bigmuddy-network-telemetry-metrics`. These plugins are expected to be published as [Ruby gems](http://rubygems.org) shortly.

The plugins should be useful if you are assembling your own stack and using logstash. For example, the codec plugin has been used in logstash to collect telemetry streams and publish content onto a [kafka](https://github.com/logstash-plugins/logstash-output-kafka) bus. The same logstash codec plugin was used to collect telemetry and feed it in to [Splunk](http://www.splunk.com/).

## Would you like to customise the fleet?

While NOT required, a large degree of customisation is possible.

For emphasis, the above should be all you need to do in order to feed telemetry streams to the collector stack.

There are two aspects of customisation possible:

- the build installation is customised by modifying the files in `src` directory for each stack. Primarily, the set of attributes in `src/environment` (e.g. ports `logstash` listens on, host volumes to use etc) dictate what is set up. These configuration files can be tweaked to influence the individual components in the `src` directory preserving the changes across `stack_build` iterations..

- on top of build time customisation, the configuration files for the various components are staged in host mounted volumes, and can be modified in situ in the host mounted volumes. As per above, note that those files are regenerated with every `stack_build` iteration, and any changes made to the files in the host mounted volume will be lost. Default host mounted volumes for each component per stack are here:

```
/var/local/stack_elk/elasticsearch_data
/var/local/stack_elk/kibana_data
/var/local/stack_elk/logstash_data
/var/local/stack_prometheus/logstash_data
/var/local/stack_prometheus/prometheus_data
/var/local/stack_prometheus/promdash_data
/var/local/stack_signalfx/logstash_data
```

The host mounted volume location can be changed by modifying `src/environment` should it be necessary. Volumes are set up at build time if they do not exist. Do note, that data will be preserved across `stack_run`/`stack_stop` cycles, This means that if the host volume is archived, it should be possible to snapshot the state of the stack.

An example of an interesting configuration file (re)generated at build time is the `logstash` pipeline configuration for each stack:

```
/var/local/stack_elk/logstash_data/conf.d/ls_telemetry.conf
/var/local/stack_prometheus/logstash_data/conf.d/ls_telemetry.conf
/var/local/stack_signalfx/logstash_data/conf.d/ls_telemetry.conf
```

## Troubleshooting the installation?

Is the host where you are installing the stack behind an HTTP proxy? There is section below with instructions if so.

Remember to check out the docker troubleshooting tips below too.

Logs are written to `<stack>/log/*.log`. These logs may shed some light and include the execution command to run `docker` containers - this can be useful if you wish to start and stop individual containers.

The section does not include per-component troubleshooting, but it is worth mentioning, that for `logstash`, creating the file `<host volume>/logstash.overrides` and including the line `LS_OPTS="--debug"` will generate per message logging in `<host volume>/logstash.log`. Remember to `./stack_stop` and `./stack_run` to pick up overrides.


## Is your collector behind an HTTP proxy?

For the stack you are using, simply edit the `src/environment` file and populate the proxy as per the example.

Alternatively set `http_proxy` and `https_proxy` as environment variables, but note that, by default, those environment variables will not be propagated across sudo. One way to workaround this restriction is to pass them in explicitly on the command line as follows. For example:

```
sudo COLLECTOR=a.b.c.d http_proxy=http://example.org:80 https_proxy=http://example.org:80 ./stack_build
```

## Caveats

The `stack_prometheus` subsystem is built on top of the un-versioned prometheus components in the docker registry. At some point, we will move to versioned instances.

## Docker tips

We start by making sure that `git` and `docker` are set up correctly. From a fresh installation (say an Ubuntu distribution), we might first install docker:

```
sudo apt-get install git
wget -qO- https://get.docker.com/ | sh
sudo service docker start
```

Ensure that `/etc/default/docker` is updated with the following, if you are using a desktop Ubuntu distribution:

```
DOCKER_OPTS="--dns <DNSSERVER> --dns 8.8.8.8 --dns 8.8.4.4"
export http_proxy=http://<HTTPPROXY>:80/
```
The http_proxy setup is required if behind a proxy.

Do remember to restart docker (e.g. `sudo service docker restart`).

Handy `docker` commands include `ps -a` showing container instances, `inspect <name from ps e.g. stack_elk_logstash>` displaying the runtime configurtion like volume bindings, state etc for a container, and `logs <name from ps e.g. stack_prometheus_prometheus>` which dumps the output from executed process.

With both `stack_elk` and `stack_prometheus` installed, the following set of images and containers should show up:

```
collector:~$ sudo docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
logstash            1.5.2               b36a820946e4        4 minutes ago       1.029 GB
kibana              4.1.1               53561efe97d6        9 minutes ago       262.7 MB
<none>              <none>              071dd8fc171a        10 minutes ago      1.029 GB
elasticsearch       1.6.0               8f2207fb95ca        28 hours ago        514.8 MB
java                8                   49ebfec495e1        31 hours ago        816.4 MB
prom/pushgateway    latest              47190258fc7c        2 days ago          24.61 MB
prom/promdash       latest              db9f914e1858        4 days ago          169.1 MB
ubuntu              14.04               d2a0ecffe6fa        5 days ago          188.4 MB
prom/prometheus     latest              8c05d89135bd        6 weeks ago         37.29 MB

collector:~$ sudo docker ps -a
CONTAINER ID        IMAGE                 COMMAND                CREATED             STATUS              PORTS                                            NAMES
dc15dc08bf54        logstash:1.5.2        "/bin/sh -c '/start.   4 minutes ago       Up 4 minutes                                                         stack_prometheus_logstash     
f1e9c3eaed11        prom/promdash         "./run ./bin/thin st   4 minutes ago       Up 4 minutes        0.0.0.0:3000->3000/tcp                           stack_prometheus_promdash     
78c9a3259a09        prom/prometheus       "/bin/prometheus -co   5 minutes ago       Up 5 minutes        0.0.0.0:9090->9090/tcp                           stack_prometheus_prometheus   
14bbcc3182db        prom/pushgateway      "/bin/go-run"          5 minutes ago       Up 5 minutes        0.0.0.0:9092->9091/tcp                           stack_prometheus_pushgw_lpr   
4a28535c2ea8        prom/pushgateway      "/bin/go-run"          5 minutes ago       Up 5 minutes        0.0.0.0:9091->9091/tcp                           stack_prometheus_pushgw       
76317c87a98c        logstash:1.5.2        "/bin/sh -c '/start.   7 minutes ago       Up 7 minutes                                                         stack_elk_logstash            
0916ea88edd8        kibana:4.1.1          "/bin/sh -c '/start.   7 minutes ago       Up 7 minutes        0.0.0.0:5601->5601/tcp                           stack_elk_kibana              
6e183e68de67        elasticsearch:1.6.0   "/docker-entrypoint.   7 minutes ago       Up 7 minutes        0.0.0.0:9200->9200/tcp, 0.0.0.0:9300->9300/tcp   stack_elk_elasticsearch       


```