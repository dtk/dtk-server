#!/usr/bin/env bash

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

# export the variables
export USERNAME PASSWORD PUBLIC_ADDRESS GIT_PORT REMOTE_REPO_HOST REMOTE_REPO_REST_PORT MCOLLECTIVE_PORT INSTANCE_NAME

# start necessary services
/usr/sbin/sshd -D &

# set up log directories
mkdir -p ${HOST_VOLUME}/logs/nginx
rm -rf /var/log/nginx
ln -s ${HOST_VOLUME}/logs/nginx /var/log/nginx
mkdir -p ${HOST_VOLUME}/logs/app
rm -rf /home/${TENANT_USER}/server/current/application/log
chown -R ${TENANT_USER}:${TENANT_USER} ${HOST_VOLUME}/logs/app
ln -s ${HOST_VOLUME}/logs/app /home/${TENANT_USER}/server/current/application/log

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
ln -sf ${HOST_VOLUME}/ssh/authorized_keys /home/${TENANT_USER}/.ssh/authorized_keys
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

# generate mcollective ssh keys
if [[ ! -d ${HOST_VOLUME}/mcollective ]]; then
  mkdir -p ${HOST_VOLUME}/mcollective
  ssh-keygen -t rsa -f ${HOST_VOLUME}/mcollective/mcollective_local -P ''
  ssh-keygen -t rsa -f ${HOST_VOLUME}/mcollective/mcollective_remote -P ''
  cat ${HOST_VOLUME}/mcollective/mcollective_remote.pub > ${HOST_VOLUME}/mcollective/authorized_keys
  chmod 600 ${HOST_VOLUME}/mcollective/authorized_keys
  chown -R ${TENANT_USER}:${TENANT_USER} ${HOST_VOLUME}/mcollective
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

# activemq
ln -s ${HOST_VOLUME}/activemq/data /opt/activemq/data
if [[ ! -d ${HOST_VOLUME}/activemq ]]; then
  mkdir -p ${HOST_VOLUME}/activemq/data
  rm -rf /opt/activemq/data
fi
/opt/activemq/bin/activemq start &

if [[ ! -f ${HOST_VOLUME}/init_done ]]; then
  envsubst < /addons/server.conf.template > /etc/dtk/${TENANT_USER}/server.conf
fi

# set up the tenant database and use
su - ${TENANT_USER} -c "cd /home/${TENANT_USER}/server/current/application; bundle exec ./utility/dbrebuild.rb"
su - ${TENANT_USER} -c "cd /home/${TENANT_USER}/server/current/application; bundle exec ./utility/initialize.rb"
if [[ -f ${HOST_VOLUME}/dtk.config ]] && [[ ! -f ${HOST_VOLUME}/init_done ]]; then
  su - ${TENANT_USER} -c "cd /home/${TENANT_USER}/server/current/application; bundle exec ./utility/add_user.rb ${USERNAME} -p ${PASSWORD}"
  #touch ${HOST_VOLUME}/init_done
fi

/usr/sbin/nginx -g 'daemon off;'




