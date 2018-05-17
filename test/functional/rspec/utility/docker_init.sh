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

ADDRESS=${1}
UPGRADE=${2}
HOST_VOLUME=${3}
DTK_SERVER_BRANCH=${4:-master}
DTK_ARBITER_BRANCH=${5:-master}
CONTAINER=${6:-dtk}
ARBITER_CONTAINER=${7:-dtk-arbiter}
USER=${8:-docker-test}
PASS=${9:-r8server}

SSH_PORT=2222

docker ps -a | grep dtk
EXISTS=$?
if [[ $EXISTS -eq 0 ]]; then
  echo -e "Removing Docker Container: ${CONTAINER}...\n"
  docker rm -f ${CONTAINER}
fi

docker ps -a | grep dtk-arbiter
EXISTS=$?
if [[ $EXISTS -eq 0 ]]; then
  echo -e "Removing Docker Container: ${ARBITER_CONTAINER}...\n"
  docker rm -f ${ARBITER_CONTAINER}
fi

if [[ $UPGRADE -eq 0 ]]; then
  rm -rf ${HOST_VOLUME}
  mkdir -p ${HOST_VOLUME}
  echo -e "Container directory ${HOST_VOLUME} removed."
  echo -e "USERNAME=${USER}\nPASSWORD=${PASS}\nPUBLIC_ADDRESS=${ADDRESS}\nGIT_PORT=${SSH_PORT}\nLOG_LEVEL=debug\n" > "${HOST_VOLUME}/dtk.config"
fi

echo -e "\nStarting a new Docker Container: ${CONTAINER}"
echo -e "\nStarting a new Docker Container: ${ARBITER_CONTAINER}"

# start the dtk-server and dtk-arbiter container
if [[ $DTK_SERVER_BRANCH == 'master' ]]; then
  \curl -sSL https://getserver.dtk.io | bash -s -- -v latest ${HOST_VOLUME}
else
  \curl -sSL https://getserver.dtk.io | bash -s -- -v ${DTK_SERVER_BRANCH} ${HOST_VOLUME}
fi