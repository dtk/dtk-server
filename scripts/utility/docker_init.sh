#!/bin/bash

if [[ -z $1 ]]; then
        echo "No public address provided."
        exit 1
fi

IMAGE=getdtk/server-full
REPO_HOST=repoman1.internal.r8network.com
REPO_PORT=443
MCO_PORT=61663




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
        echo "Stoping Docker Container: ${CONTAINER}..."
        docker stop ${CONTAINER} > /dev/null
fi


docker ps -a | grep dtk > /dev/null
EXISTS=$?
if [[ $EXISTS -eq 0 ]]; then
        echo "Removing Docker Container: ${CONTAINER}..."
        docker rm ${CONTAINER} > /dev/null
fi

echo -e "Pulling the latest DTK - Server image \n"
docker pull ${IMAGE}
echo -e "\nStarting a new Docker Container: ${CONTAINER}"
docker run -e REMOTE_REPO_HOST=${REPO_HOST} -e REMOTE_REPO_REST_PORT=${REPO_PORT} -e MCOLLECTIVE_PORT=${MCO_PORT} --name dtk -v /${CONTAINER}:/host_volume -p 8080:80 -p ${MCO_PORT}:6163 -p 2222:22 -d getdtk/server-full



