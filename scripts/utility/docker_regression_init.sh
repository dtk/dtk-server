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

IMAGE=getdtk/dtk-server
REPO_HOST=repoman1.internal.r8network.com
REPO_PORT=443
MCO_PORT=6163
SSH_PORT=2222
HTTP_PORT=8080
DOCKER_ID=$(date +%Y%m%d%H%M%S)

ADDRESS=${1}
CONTAINER=${2:-dtk}
USER=${4:-dtk-docker}
PASS=${5:-r8server}
NAME=${6:-dtk-docker}

docker ps | grep [d]tk
RUNNING=$?
if [[ $RUNNING -eq 0 ]]; then
    echo -e "Stoping Docker Container: ${CONTAINER}...\n"
    docker stop ${CONTAINER} > /dev/null
fi

docker ps -a | grep [d]tk > /dev/null
EXISTS=$?
if [[ $EXISTS -eq 0 ]]; then
    echo -e "Removing Docker Container: ${CONTAINER}...\n"
    docker rm ${CONTAINER} > /dev/null
fi

echo -e "Pulling the latest DTK - Server image. \n"
docker pull ${IMAGE}
PULLED=$?
if [[ $PULLED -eq 1 ]]; then
	echo -e "Error while pulling image. \n"
	exit 1
fi

echo -e "\nStarting a new Docker Container: ${CONTAINER}"
docker run -e REMOTE_REPO_HOST=${REPO_HOST} -e REMOTE_REPO_REST_PORT=${REPO_PORT} -e MCOLLECTIVE_PORT=${MCO_PORT} --name ${CONTAINER} -v /${CONTAINER}:/host_volume -p ${HTTP_PORT}:80 -p ${MCO_PORT}:6163 -p ${SSH_PORT}:22 -d ${IMAGE}
