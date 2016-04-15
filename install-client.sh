#!/usr/bin/env bash
 
usage_config() {
  echo $1
  echo -e "\nUsage:\n$0 [-u user] [-p port] configuration_path\n"
  echo    "configuration_path   - location of dtk.config file"
  echo    "user                 - user on which to install and configure dtk-client"
  echo    "                       defaults to new user named 'dtk-client"
  echo    "port                 - port where DTK server is listening"
  echo -e "                       defaults to 8080\n"
} 

if [[ $# -lt 1 ]]; then 
  usage_config
  exit 1
fi 

while getopts ":u:p:s:" o; do
    case "${o}" in
        u)
            u=${OPTARG}
            ;;
        p)
            p=${OPTARG}
            ;;
        s)
            s=true
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# set default value for user
user=${u-dtk-client}
config_path=$1
confdir=/home/${user}/dtk
port=${p-8080}

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

if [[ ! -f ${config_path}/dtk.config ]] && [[ "$s" != true ]]; then
  usage_config "Cannot find the config file at ${config_path}/dtk.config"
  exit 1
fi

if [[ "$s" != true ]]; then
  # load the config file
  . ${config_path}/dtk.config

  if ([[ -z ${USERNAME} ]] || [[ -z ${PASSWORD} ]] || [[ -z ${PUBLIC_ADDRESS} ]]); then
    usage_config "Plase make sure ${config_path}/dtk.config is correctly populated"
    exit 1
  fi
fi

echo -e "This script will do the following:\n"
echo    "* Install the dtk-client gem"
echo    "* Add the '${user}' user if it does not already exist"
echo -e "* Genereate an SSH keypair for the selected user (if it does not exist)\n"

if [[ "$s" != true ]]; then
read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
fi

if [[ "${user}" != "$(whoami)" ]]; then
  useradd -m $user
fi

if [[ -f /usr/local/rvm/wrappers/default/gem ]]; then
  gem_path=/usr/local/rvm/wrappers/default/gem
else
  gem_path=$(which gem)
fi

# install dtk-client only if it's executable cannot be found
if ! command -v dtk-shell; then
  echo "Installing dtk-client gem"
  $sudo $gem_path install dtk-client --no-rdoc --no-ri
fi 

if [[ "$s" != true ]]; then
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
verbose_rest_calls=false          # logging of REST calls

# if relative path is used we will use HOME + relative path, apsoluth path will override this
module_location=component_modules
service_location=service_modules
test_module_location=test_modules
backups_location=backups

# server connection details
server_port=${port}
secure_connection_server_port=443
secure_connection=false
server_host=localhost
EOF

cat <<EOF | $su_c "tee /home/${user}/dtk/.connection > /dev/null"
username=${USERNAME}
password=${PASSWORD}
EOF

# generate ssh keys
if [[ ! -f /home/${user}/.ssh/id_rsa ]]; then
  $su_c "ssh-keygen -t rsa -f /home/${user}/.ssh/id_rsa -P ''"
fi
fi

if [[ -n $GIT_USER ]] && [[ -n $GIT_EMAIL ]]; then
cat <<EOF | $su_c "tee /home/${user}/.gitconfig > /dev/null"
[user]
        email = ${GIT_EMAIL}
        name = ${GIT_USER}
EOF
fi


