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
GIT_PORT=${GIT_PORT-2222}

# set pbuilder argument if provided
if [[ -n $PBUILDERID ]]; then
  PBUILDER_ARG="-e PBUILDERID=${PBUILDERID}"
fi

# start the dtk-server container
docker run --name dtk -v $HOST_VOLUME:/host_volume -p 8080:80 -p 6163:6163 -p $GIT_PORT:22 -d getdtk/dtk-server

# wait for dtk-arbiter ssh keypair to be generated
while [[ ! -f $HOST_VOLUME/arbiter/arbiter_remote ]]; do
  sleep 2
done

# check if docker daemon socket is available
# and mount it inside dtk-arbiter contianer if so
additional_args=''
if [[ -e /var/run/docker.sock ]]; then
  additional_args="-v /var/run/docker.sock:/var/run/docker.sock "
fi

# start the dtk-arbiter container
docker run --name dtk-arbiter $PBUILDER_ARG -v $HOST_VOLUME:/host_volume $additional_args -td getdtk/dtk-arbiter
