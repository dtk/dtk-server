#!/usr/bin/env bash
 
usage_config() { 
  echo $1 
  echo -e "\nUsage:\n$0 configuration_path [user] \n" 
  echo    "configuration_path   - location of dtk.config file"
  echo    "user                 - user on which to install and configure dtk-client"
  echo -e "                       defaults to new user named 'dtk-client\n"
} 

if [[ $# -lt 1 ]]; then 
  usage_config
  exit 1
fi 

# set default value for user
user=${2-dtk-user}
config_path=$1
confdir=/home/${user}/dtk

if [[ "${user}" != "$(whoami)" ]] && [[ "$(whoami)" != "root" ]]; then
  usage_config "This script requires super-user privileges."
  exit 1
fi

if [[ "${user}" != "$(whoami)" ]]; then
  su_c="su - ${user} -c"
  sudo=''
else
  su_c=''
  sudo='sudo'
fi

if [[ ! -f ${config_path}/dtk.config ]]; then
  usage_config "Cannot find the config file at ${config_path}/dtk.config"
  exit 1
fi

# load the config file
. ${config_path}/dtk.config

if ([[ -z ${USERNAME} ]] || [[ -z ${PASSWORD} ]] || [[ -z ${PUBLIC_ADDRESS} ]]); then
  usage_config "Plase make sure ${config_path}/dtk.config is correctly populated"
  exit 1
fi

echo -e "This script will do the following:\n"
echo    "* Install the dtk-client gem"
echo    "* Add the '${user}' user if it does not already exist"
echo -e "* Genereate an SSH keypair for the selected user (if it does not exist)\n"

read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'

if [[ "${user}" != "$(whoami)" ]]; then
  useradd -m $user
fi

echo "Installing dtk-client gem"
$sudo gem install dtk-client --no-rdoc --no-ri

$su_c "mkdir -p /home/${user}/dtk"
cat <<EOF | $su_c "tee /home/${user}/dtk/client.conf > /dev/null"
development_mode=false
meta_table_ttl=7200000            # time to live (ms)
meta_constants_ttl=7200000        # time to live (ms)
meta_pretty_print_ttl=7200000     # time to live (ms)
task_check_frequency=60           # check frequency for task status threads (seconds)
tail_log_frequency=2              # assembly - frequency between requests (seconds)
debug_task_frequency=5            # assembly - frequency between requests (seconds)
auto_commit_changes=false         # autocommit for modules
verbose_rest_calls=true     # logging of REST calls

# if relative path is used we will use HOME + relative path, apsoluth path will override this
module_location=component_modules
service_location=service_modules
test_module_location=test_modules
backups_location=backups

# server connection details
server_port=8080
secure_connection_server_port=443
secure_connection=false
server_host=${PUBLIC_ADDRESS}
EOF

cat <<EOF | $su_c "tee /home/${user}/dtk/.connection > /dev/null"
username=${USERNAME}
password=${PASSWORD}
EOF

# generate ssh keys
if [[ ! -f /home/${user}/.ssh/id_rsa ]]; then
  $su_c "ssh-keygen -t rsa -f /home/${user}/.ssh/id_rsa -P ''"
fi;

if [[ -n $GIT_USER ]] && [[ -n $GIT_EMAIL ]]; then
cat <<EOF | $su_c "tee /home/${user}/.gitconfig > /dev/null"
[user]
        email = ${GIT_EMAIL}
        name = ${GIT_USER}
EOF
fi


