#!/bin/bash

if [[ -z $1 ]]; then
    echo "No public address provided."
    exit 1
fi

if [[ -z $2 ]]; then
	echo "Upgrade status not specified."
    exit 1
fi

IMAGE=getdtk/server-full
REPO_HOST=repoman1.internal.r8network.com
REPO_PORT=443
MCO_PORT=61663
SSH_PORT=2222
HTTP_PORT=8080

ADDRESS=${1}
UPGRADE=${2}
CONTAINER=${3:-dtk}
USER=${4:-dtk17-docker}
PASS=${5:-r8server}
NAME="dtk-docker-${RANDOM}"

if [[ $UPGRADE -eq 0 ]]; then
	rm -rf /${CONTAINER}
	mkdir /${CONTAINER}
	echo -e "Root Container directory /${CONTAINER} removed."
fi

echo -e "USERNAME=${USER}\nPASSWORD=${PASS}\nPUBLIC_ADDRESS=${ADDRESS}\nINSTANCE_NAME=${NAME}" > "/${CONTAINER}/dtk.config"
echo "Creating dtk-server: ${NAME}"

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

echo -e "Pulling the latest DTK - Server image. \n"
docker pull ${IMAGE} > /dev/null
PULLED=$?
if [[ $PULLED -eq 1 ]]; then
	echo -e "Error while pulling image. \n"
	exit 1
fi

echo -e "\nStarting a new Docker Container: ${CONTAINER}"
docker run -e REMOTE_REPO_HOST=${REPO_HOST} -e REMOTE_REPO_REST_PORT=${REPO_PORT} -e MCOLLECTIVE_PORT=${MCO_PORT} --name ${CONTAINER} -v /${CONTAINER}:/host_volume -p ${HTTP_PORT}:80 -p ${MCO_PORT}:6163 -p ${SSH_PORT}:22 -d ${IMAGE}