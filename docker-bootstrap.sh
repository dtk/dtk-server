#!/usr/bin/env bash

usage_config() {
  echo $1
  echo -e "\nUsage:\n$0 host_volume [pbuilderid]\n"
  echo    "host_volume          - location of dtk.config file"
  echo -e "pbuilderid           - optionally set pbuilderid for dtk-arbiter container\n"
}

if [[ $# -lt 1 ]]; then
  usage_config
  exit 1
fi

HOST_VOLUME=$1
PBUILDERID=$2

# set pbuilder argument if provided
if [[ -n $PBUILDERID ]]; then
  PBUILDER_ARG="-e PBUILDERID=${PBUILDERID}"
fi

# start the dtk-server container
docker run --name dtk -v $HOST_VOLUME:/host_volume -p 8080:80 -p 6163:6163 -p $GIT_PORT:22 -d getdtk/dtk-server

# start the dtk-arbiter container
docker run --name dtk-arbiter $PBUILDER_ARG -v $HOST_VOLUME:/host_volume -d getdtk/dtk-arbiter
