#!/usr/bin/env bash
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

if [[ ${INIT_DEBUG} == true ]]; then
  set -x
fi

PG_VERSION=8.4
export HOST_VOLUME=/host_volume
export TENANT_USER=dtk1

function usage_config() {
  echo "Please make sure that dtk.config is populated and placed in the attached volume."
  echo "dtk.config example:"
  cat << EOF
USERNAME=dtk1user
PASSWORD=password
PUBLIC_ADDRESS=dtk1.dtk.io
EOF
}

# validate env variables
if [[ -f ${HOST_VOLUME}/dtk.config ]]; then
  # load the configuration
  . ${HOST_VOLUME}/dtk.config
  # validate all required variables
fi

if ([[ -z ${USERNAME} ]] || [[ -z ${PASSWORD} ]] || [[ -z ${PUBLIC_ADDRESS} ]]) && [[ ! -f ${HOST_VOLUME}/init_done ]]; then
  usage_config
  exit 1
fi

# set git port to default value of 2222, if not otherwise set
GIT_PORT=${GIT_PORT-2222}
# set repoman host and port to default values
REMOTE_REPO_HOST=${REMOTE_REPO_HOST-dtknet.servicecatalog.it}
REMOTE_REPO_REST_PORT=${REMOTE_REPO_REST_PORT-7001}
# set mco port to default
MCOLLECTIVE_PORT=${MCOLLECTIVE_PORT-6163}
# set instance name to default
INSTANCE_NAME=${INSTANCE_NAME-dtk1}
# install dtk-client
INSTALL_CLIENT=${INSTALL_CLIENT-true}

# set arbiter topic and queue
ARBITER_TOPIC="/topic/arbiter.${TENANT_USER}.broadcast"
ARBITER_QUEUE="/queue/arbiter.${TENANT_USER}.reply"

# set defaults for STOMP
if [[ -z ${STOMP_USERNAME} ]]; then
  STOMP_USERNAME=$TENANT_USER
fi
STOMP_PASSWORD=${STOMP_PASSWORD-marionette}

# export the variables
export USERNAME PASSWORD PUBLIC_ADDRESS GIT_PORT REMOTE_REPO_HOST \
       REMOTE_REPO_REST_PORT MCOLLECTIVE_PORT INSTANCE_NAME ARBITER_QUEUE ARBITER_TOPIC STOMP_USERNAME STOMP_PASSWORD

# start necessary services
/usr/sbin/sshd -D &

# set up log directories
mkdir -p ${HOST_VOLUME}/logs/nginx
rm -rf /var/log/nginx
ln -s ${HOST_VOLUME}/logs/nginx /var/log/nginx
mkdir -p ${HOST_VOLUME}/logs/app
rm -rf /var/log/dtk/${TENANT_USER}
chown -R ${TENANT_USER}:${TENANT_USER} ${HOST_VOLUME}/logs/app
ln -s ${HOST_VOLUME}/logs/app /var/log/dtk/${TENANT_USER}

# initialize the database and start postgres in background
if [[ ! -d ${HOST_VOLUME}/postgresql/${PG_VERSION}/main ]]; then
  mkdir -p ${HOST_VOLUME}/postgresql/${PG_VERSION}/main
  chown -R postgres:postgres ${HOST_VOLUME}/postgresql/${PG_VERSION}
  su postgres -c "/usr/lib/postgresql/${PG_VERSION}/bin/initdb -D ${HOST_VOLUME}/postgresql/${PG_VERSION}/main"
fi

su postgres -c "/usr/lib/postgresql/8.4/bin/postgres -D ${HOST_VOLUME}/postgresql/${PG_VERSION}/main &"
sleep 5
if [[ ! `psql -h /var/run/postgresql -U postgres -lqt | cut -d \| -f 1 | grep -w dtk1` ]]; then
  psql -h /var/run/postgresql -U postgres -c 'CREATE DATABASE dtk1;'
fi

# reconfigure ssh
if [[ ! -d ${HOST_VOLUME}/ssh ]]; then
  mkdir -p ${HOST_VOLUME}/ssh
  ssh-keygen -t rsa -f ${HOST_VOLUME}/ssh/id_rsa -P ''
  #echo "IdentityFile ${HOST_VOLUME}/ssh/id_rsa" >> /home/${TENANT_USER}/.ssh/config
  printf '%s\n    %s\n' 'Host *' "IdentityFile ${HOST_VOLUME}/ssh/id_rsa" >> /home/${TENANT_USER}/.ssh/config
  chown -R ${TENANT_USER}:${TENANT_USER} ${HOST_VOLUME}/ssh
fi
ln -sf ${HOST_VOLUME}/ssh/id_rsa* /home/${TENANT_USER}/.ssh/
SSH_HOST_KEY_DIR=${HOST_VOLUME}/ssh/host
mkdir -p ${SSH_HOST_KEY_DIR}
# generate SSH2 host keys, but only if they don't exist
for type in rsa dsa ecdsa ed25519; do
  fn="ssh_host_${type}_key"
  f="${SSH_HOST_KEY_DIR}/ssh_host_${type}_key"

  if [ -s "${f}" ]; then
    echo "SSH2 '$type' key ($f) already exists; not regenerating."
    continue
  fi

  echo "Generating SSH2 '$type' key ($f); this may take some time..."
  yes | ssh-keygen -q -f "$f" -N '' -t "$type"
  yes | ssh-keygen -l -f "${f}.pub"
  ln -sfT "${f}" "/etc/ssh/${fn}"
  ln -sfT "${f}".pub "/etc/ssh/${fn}".pub
done

# generate arbiter ssh keys
if [[ ! -d ${HOST_VOLUME}/arbiter ]]; then
  mkdir -p ${HOST_VOLUME}/arbiter
  ssh-keygen -t rsa -f ${HOST_VOLUME}/arbiter/arbiter_local -P ''
  ssh-keygen -t rsa -f ${HOST_VOLUME}/arbiter/arbiter_remote -P ''
  cat ${HOST_VOLUME}/arbiter/arbiter_remote.pub > ${HOST_VOLUME}/arbiter/authorized_keys
  chmod 600 ${HOST_VOLUME}/arbiter/authorized_keys
  chown -R ${TENANT_USER}:${TENANT_USER} ${HOST_VOLUME}/arbiter
  # ln -s ${HOST_VOLUME}/arbiter /home/${TENANT_USER}/rsa_identity_dir
fi

# gitolite
ln -s ${HOST_VOLUME}/gitolite/.gitolite /home/${TENANT_USER}/.gitolite
ln -s ${HOST_VOLUME}/gitolite/repositories /home/${TENANT_USER}/repositories
ln -s ${HOST_VOLUME}/gitolite/gitolite-admin /home/${TENANT_USER}/gitolite-admin
if [[ ! -d ${HOST_VOLUME}/gitolite/ ]]; then
  su - ${TENANT_USER} -c "git config --global user.email ${TENANT_USER}@localhost"
  su - ${TENANT_USER} -c "git config --global user.name ${TENANT_USER}"
  ln -s ${HOST_VOLUME}/ssh/id_rsa.pub ${HOST_VOLUME}/ssh/dtk-admin-${TENANT_USER}.pub
  mkdir -p ${HOST_VOLUME}/gitolite/bin
  mkdir -p ${HOST_VOLUME}/gitolite/.gitolite/logs
  mkdir ${HOST_VOLUME}/gitolite/repositories
  git clone git://github.com/sitaramc/gitolite ${HOST_VOLUME}/gitolite/src
  chown -R ${TENANT_USER}:${TENANT_USER} ${HOST_VOLUME}/gitolite
  su - ${TENANT_USER} -c "${HOST_VOLUME}/gitolite/src/install -ln ${HOST_VOLUME}/gitolite/bin/"
  su - ${TENANT_USER} -c "${HOST_VOLUME}/gitolite/bin/gitolite setup -pk ${HOST_VOLUME}/ssh/dtk-admin-${TENANT_USER}.pub"
  su - ${TENANT_USER} -c "git clone localhost:gitolite-admin ${HOST_VOLUME}/gitolite/gitolite-admin"
  cp -r /addons/gitolite/conf/* /home/${TENANT_USER}/gitolite-admin/conf/
  su - ${TENANT_USER} -c "cd /home/${TENANT_USER}/gitolite-admin; git add .; git commit -a -m 'Initial commit'; git push"
fi

# create r8server-repo
if [[ ! -d ${HOST_VOLUME}/r8server-repo/ ]]; then
  mkdir -p ${HOST_VOLUME}/r8server-repo
  chown -R ${TENANT_USER}:${TENANT_USER} ${HOST_VOLUME}/r8server-repo
fi;

# activemq
ln -s ${HOST_VOLUME}/activemq/data /opt/activemq/data
if [[ ! -d ${HOST_VOLUME}/activemq ]]; then
  mkdir -p ${HOST_VOLUME}/activemq/data
  rm -rf /opt/activemq/data
fi
/opt/activemq/bin/activemq start &

# generate salts
if [[ ! -f ${HOST_VOLUME}/.cookie_salt ]]; then
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 50 > ${HOST_VOLUME}/.cookie_salt
fi
if [[ ! -f ${HOST_VOLUME}/.password_salt ]]; then
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 50 > ${HOST_VOLUME}/.password_salt
fi

export COOKIE_SALT=`cat ${HOST_VOLUME}/.cookie_salt`
export PASSWORD_SALT=`cat ${HOST_VOLUME}/.password_salt`

# populate the configuration template
if [[ ! -f ${HOST_VOLUME}/server.conf ]]; then
  envsubst < /addons/server.conf.template > ${HOST_VOLUME}/server.conf
fi
ln -sf ${HOST_VOLUME}/server.conf /etc/dtk/${TENANT_USER}/server.conf

# if grep '^encryption.cookie_salt.*""' /etc/dtk/${TENANT_USER}/server.conf; then
#   salt=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 50`
#   sed -i "s|^encryption.cookie_salt.*\"\"|encryption.cookie_salt = \"${salt}\"|g" /etc/dtk/${TENANT_USER}/server.conf

# fi
# if grep '^encryption.password_salt.*""' /etc/dtk/${TENANT_USER}/server.conf; then
#   salt=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 50`
#   sed -i "s|^encryption.password_salt.*\"\"|encryption.password_salt = \"${salt}\"|g" /etc/dtk/${TENANT_USER}/server.conf
# fi

# set up the tenant database and use
su - ${TENANT_USER} -c "cd /home/${TENANT_USER}/server/current/application; bundle exec ./utility/dbrebuild.rb"
su - ${TENANT_USER} -c "cd /home/${TENANT_USER}/server/current/application; bundle exec ./utility/initialize.rb"
if [[ -f ${HOST_VOLUME}/dtk.config ]] && [[ ! -f ${HOST_VOLUME}/init_done ]]; then
  su - ${TENANT_USER} -c "cd /home/${TENANT_USER}/server/current/application; bundle exec ./utility/add_user.rb ${USERNAME} -p ${PASSWORD}"
  #touch ${HOST_VOLUME}/init_done
fi
# extract the tenant private rsa key
mkdir -p ${HOST_VOLUME}/ssh/tenant
chown ${TENANT_USER}:${TENANT_USER} ${HOST_VOLUME}/ssh/tenant
su - ${TENANT_USER} -c "cd /home/${TENANT_USER}/server/current/application; bundle exec ./utility/extract_key_to_file.rb ${HOST_VOLUME}/ssh/tenant/id_rsa"

# potential fix for auth keys
if [[ ! -f "/home/dtk1/local/triggers/link-akf" ]]; then
  su - ${TENANT_USER} -c "mkdir -p local/triggers"
  su - ${TENANT_USER} -c "echo -e '#!/bin/sh \n cp ~/.ssh/authorized_keys /host_volume/ssh' >> 'local/triggers/link-akf'"
  su - ${TENANT_USER} -c "chmod +x local/triggers/link-akf"
  su - ${TENANT_USER} -c "${HOST_VOLUME}/gitolite/bin/gitolite print-default-rc > ~/.gitolite.rc"
  su - ${TENANT_USER} -c 'sed -i "0,/# LOCAL_CODE/s//LOCAL_CODE/g" .gitolite.rc'
  su - ${TENANT_USER} -c "sed -i  \"76iNON_CORE => 'ssh-authkeys POST_COMPILE link-akf',\" .gitolite.rc"
fi

if [[ ! -L /home/${TENANT_USER}/.ssh/authorized_keys ]]; then
  # put authorized_keys on the host volume to preserve it
  su - ${TENANT_USER} -c "mv /home/${TENANT_USER}/.ssh/authorized_keys ${HOST_VOLUME}/ssh/"
  ln -s ${HOST_VOLUME}/ssh/authorized_keys /home/${TENANT_USER}/.ssh/authorized_keys
fi

if [[ "$INSTALL_CLIENT" == true ]] && [[ ! -L /home/dtk-client/dtk ]]; then
  # install dtk-client
  /home/${TENANT_USER}/server/current/install-client.sh -p 80 /host_volume
  mv /home/dtk-client/dtk ${HOST_VOLUME}/client
fi

# persist client data
if [[ -d /home/dtk-client ]]; then
  chown dtk-client:dtk-client ${HOST_VOLUME}/client
  ln -sfn ${HOST_VOLUME}/client /home/dtk-client/dtk
fi

# persist nginx confs
if [[ ! -d /host_volume/nginx ]]; then
  mv /etc/nginx /host_volume/
fi
ln -sfn /host_volume/nginx /etc/nginx

# start redis
/usr/bin/redis-server &

# start nginx
/usr/sbin/nginx -g 'daemon off;'

su - ${TENANT_USER} -c "touch server/current/application/tmp/restart.txt"
