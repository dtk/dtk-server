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
WEB_PORT=${WEB_PORT-8080}
STOMP_PORT=${STOMP_PORT-6163}

server_image="getdtk/dtk-server"
arbiter_image="getdtk/dtk-arbiter"
server_container_name="dtk"
arbiter_container_name="dtk-arbiter"

# set pbuilder argument if provided
if [[ -n $PBUILDERID ]]; then
  PBUILDER_ARG="-e PBUILDERID=${PBUILDERID}"
fi

# pull latest docker images
docker pull $server_image
docker pull $arbiter_image

# check if upgrades are necessary
server_image_latest=`docker inspect --format="{{ .Id }}" ${server_image}:latest 2>/dev/null`
arbiter_image_latest=`docker inspect --format="{{ .Id }}" ${arbiter_image}:latest 2>/dev/null`
server_image_running=`docker inspect --format="{{ .Image }}" ${server_container_name} 2>/dev/null`
arbiter_image_running=`docker inspect --format="{{ .Image }}" ${arbiter_container_name} 2>/dev/null`

# if newer images are available, stop and remove existing containers
if [[ "$server_image_running" != "$server_image_latest" ]] && [[ -n "$server_image_running" ]]; then
  docker stop $server_container_name
  docker rm $server_container_name
fi
if [[ "$arbiter_image_running" != "$arbiter_image_latest" ]] && [[ -n "$arbiter_image_running" ]]; then
  docker stop $arbiter_container_name
  docker rm $arbiter_container_name
fi

# start the dtk-server container if it doesn't already exist
if ! docker inspect '--format={{ .Image }}' $server_container_name >/dev/null 2>&1; then
  docker run --name $server_container_name -v $HOST_VOLUME:/host_volume -p $WEB_PORT:80 -p $STOMP_PORT:6163 -p $GIT_PORT:22 --restart=on-failure -d $server_image
fi

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

# start the dtk-arbiter container if it doesn't already exist
if ! docker inspect '--format={{ .Image }}' $arbiter_container_name >/dev/null 2>&1; then
  docker run --name $arbiter_container_name $PBUILDER_ARG -v $HOST_VOLUME:/host_volume -e HOST_VOLUME=$HOST_VOLUME $additional_args --restart=on-failure -td $arbiter_image
fi
