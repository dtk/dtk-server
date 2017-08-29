#!/usr/bin/env bash
 
usage_config() {
  echo $1
  echo -e "\nUsage:\n$0 [-p port] configuration_path\n"
  echo    "configuration_path   - location of dtk.config file"
  echo    "port                 - port where DTK server is listening"
  echo -e "                       defaults to 8080\n"
} 

if [[ $# -lt 1 ]]; then 
  usage_config
  exit 1
fi 

while getopts ":u:p:s:" o; do
    case "${o}" in
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

# return specified user's home directory
function get_home {
  ostype=`uname -s`
  if [[ "$ostype" == 'Darwin' ]]; then
    homedir=$(dscl . -read /Users/$1 NFSHomeDirectory | cut -d' ' -f2)
    binpath_arg='-n/usr/local/bin'
  else
    homedir=$(getent passwd $1 | cut -f6 -d:)
    binpath_arg=''
  fi
}

user=`whoami`
get_home $user

config_path=$1
confdir=${homedir}/dtk
port=${p-8080}

if [[ "${user}" != "$(whoami)" ]] && [[ "$(whoami)" != "root" ]]; then
  usage_config "This script requires super-user privileges."
  exit 1
fi

# if gem executable is outside of home
# assume RVM etc is not used and sudo is required
if ! which gem | grep $homedir; then
  sudo='sudo'
else
  sudo=''
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
echo -e "* Genereate an SSH keypair for the selected user (if it does not exist)"
echo -e "* Genereate dtk-client configuration files\n"

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

# check if `gem` executable is found
if [[ -z "$gem_path" ]]; then
  echo 'Cannot find the `gem` executable. Please make sure Ruby is installed prior to running this script.'
  exit 1
fi

# install dtk-client gem
echo "Installing dtk-client gem"
$sudo $gem_path install dtk-client --no-rdoc --no-ri $binpath_arg

if [[ "$s" != true ]]; then
mkdir -p ${homedir}/dtk
cat <<EOF | tee ${homedir}/dtk/client.conf > /dev/null
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
instance_location=service
module_location=component_modules
service_location=service_modules
test_module_location=test_modules
backups_location=backups

# server connection details
server_port=${port}
secure_connection_server_port=443
secure_connection=false
server_host=${PUBLIC_ADDRESS}
EOF

cat <<EOF | tee ${homedir}/dtk/.connection > /dev/null
username=${USERNAME}
password=${PASSWORD}
EOF

# generate ssh keys
if [[ ! -f ${homedir}/.ssh/id_rsa ]]; then
ssh-keygen -t rsa -f ${homedir}/.ssh/id_rsa -N ''
fi
fi

if [[ -n $GIT_USER ]] && [[ -n $GIT_EMAIL ]]; then
cat <<EOF | tee ${homedir}/.gitconfig > /dev/null
[user]
        email = ${GIT_EMAIL}
        name = ${GIT_USER}
EOF
fi


