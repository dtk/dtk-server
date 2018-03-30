#!/bin/bash
#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if [[ -z $1 ]]; then
    echo "No public address provided."
    exit 1
fi

if [[ -z $2 ]]; then
	echo "Upgrade status not specified."
    exit 1
fi

DTK_IMAGE=DTK_IMAGE=${DTK_IMAGE-getdtk/dtk-server}
ARBITER_IMAGE=${ARBITER_IMAGE-getdtk/dtk-arbiter}
REPO_HOST=dtknet.servicecatalog.it
REPO_PORT=7001
MCO_PORT=6163
SSH_PORT=2222
HTTP_PORT=8080
GIT_USERNAME=dtk1
DOCKER_ID=$(date +%Y%m%d%H%M%S)

ADDRESS=${1}
UPGRADE=${2}
DTK_SERVER_BRANCH=${3-master}
DTK_ARBITER_BRANCH=${4:-master}
CONTAINER=${5:-dtk}
ARBITER_CONTAINER=${6:-dtk-arbiter}
NAME=${7:-dtk-docker-${DOCKER_ID}}
USER=${8:-docker-test}
PASS=${9:-r8server}

if [[ $UPGRADE -eq 0 ]]; then
	rm -rf /${CONTAINER}
	mkdir /${CONTAINER}
	echo -e "Root Container directory /${CONTAINER} removed."
fi

echo -e "USERNAME=${USER}\nPASSWORD=${PASS}\nPUBLIC_ADDRESS=${ADDRESS}\nGIT_PORT=${SSH_PORT}\nLOG_LEVEL=debug\n" > "/${CONTAINER}/dtk.config"

docker ps | grep dtk > /dev/null
RUNNING=$?
if [[ $RUNNING -eq 0 ]]; then
    echo -e "Stoping Docker Container: ${CONTAINER}...\n"
    docker stop ${CONTAINER} > /dev/null
fi

docker ps -a | grep dtk > /dev/null
EXISTS=$?
if [[ $EXISTS -eq 0 ]]; then
    echo -e "Removing Docker Container: ${CONTAINER}...\n"
    docker rm ${CONTAINER} > /dev/null
fi

docker ps | grep dtk-arbiter > /dev/null
RUNNING=$?
if [[ $RUNNING -eq 0 ]]; then
    echo -e "Stoping Docker Container: ${ARBITER_CONTAINER}...\n"
    docker stop ${ARBITER_CONTAINER} > /dev/null
fi

docker ps -a | grep dtk-arbiter > /dev/null
EXISTS=$?
if [[ $EXISTS -eq 0 ]]; then
    echo -e "Removing Docker Container: ${ARBITER_CONTAINER}...\n"
    docker rm ${ARBITER_CONTAINER} > /dev/null
fi

echo -e "Pulling the latest DTK - Server image. \n"
docker pull ${DTK_IMAGE} > /dev/null
PULLED=$?
if [[ $PULLED -eq 1 ]]; then
	echo -e "Error while pulling dtk server image. \n"
	exit 1
fi

echo -e "Pulling the latest DTK - Arbiter image. \n"
docker pull ${ARBITER_IMAGE} > /dev/null
PULLED=$?
if [[ $PULLED -eq 1 ]]; then
    echo -e "Error while pulling dtk arbiter image. \n"
    exit 1
fi

echo -e "\nStarting a new Docker Container: ${CONTAINER}"
echo -e "\nStarting a new Docker Container: ${ARBITER_CONTAINER}"

HOST_VOLUME="/${CONTAINER}"

# start the dtk-server container
if [[ $DTK_SERVER_BRANCH == 'master' ]]; then
  docker run -e REMOTE_REPO_HOST=${REPO_HOST} -e REMOTE_REPO_REST_PORT=${REPO_PORT} --name ${CONTAINER} -v ${HOST_VOLUME}:/host_volume -p ${HTTP_PORT}:80 -p ${MCO_PORT}:6163 -p ${SSH_PORT}:22 -d ${DTK_IMAGE}
else
  docker run -e REMOTE_REPO_HOST=${REPO_HOST} -e REMOTE_REPO_REST_PORT=${REPO_PORT} --name ${CONTAINER} -v ${HOST_VOLUME}:/host_volume -p ${HTTP_PORT}:80 -p ${MCO_PORT}:6163 -p ${SSH_PORT}:22 -d ${DTK_IMAGE}:${DTK_SERVER_BRANCH}
fi

# wait for dtk-arbiter ssh keypair to be generated
while [[ ! -f $HOST_VOLUME/arbiter/arbiter_remote ]]; do
  sleep 2
done

# check if docker daemon socket is available
# and mount it inside dtk-arbiter contianer if so
ADDITIONAL_ARGS=''
if [[ -e /var/run/docker.sock ]]; then
  ADDITIONAL_ARGS="-v /var/run/docker.sock:/var/run/docker.sock "
fi

# start the dtk-arbiter container
if [[ $DTK_ARBITER_BRANCH == 'master' ]]; then
  docker run -e GIT_USERNAME=${GIT_USERNAME} --name ${ARBITER_CONTAINER} -v ${HOST_VOLUME}:/host_volume -e HOST_VOLUME=${HOST_VOLUME} ${ADDITIONAL_ARGS} --restart=on-failure -td ${ARBITER_IMAGE}
else
  docker run -e GIT_USERNAME=${GIT_USERNAME} --name ${ARBITER_CONTAINER} -v ${HOST_VOLUME}:/host_volume -e HOST_VOLUME=${HOST_VOLUME} ${ADDITIONAL_ARGS} --restart=on-failure -td ${ARBITER_IMAGE}:${DTK_ARBITER_BRANCH}
fi
