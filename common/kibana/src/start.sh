#!/bin/bash
#
# Collect configuration file from host mounted volume
#
/opt/kibana/bin/kibana --config /data/conf.d/kibana.yml --log-file /data/kibana.log
