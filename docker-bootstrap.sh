#!/usr/bin/env bash

usage_config() {
  echo $1
  echo -e "\nUsage:\n$0 [-p pbuilderid] [-t tag] host_volume\n"
  echo    "host_volume          - location of dtk.config file"
  echo    "pbuilderid           - optionally set pbuilderid for dtk-arbiter container"
  echo -e "tag                  - optionally set docker image tag for dtk =-server container\n"
}

if [[ $# -lt 1 ]]; then
  usage_config
  exit 1
fi

while getopts ":p:t:" o; do
  case "${o}" in
    p)
      p=${OPTARG}
      ;;
    t)
      t=${OPTARG}
      ;;
    *)
      usage_config
      ;;
  esac
done
shift $((OPTIND-1))

DEFAULT_SOURCES=(github.com/dtk/dtk-server)

if [[ -z "${sources[@]}" ]];then
  sources=("${DEFAULT_SOURCES[@]}")
fi

# Searches the tags for the highest available version matching a given pattern.
fetch_version()
{
  typeset _account _domain _pattern _repo _sources _values _version
  _sources=(${!1})
  _pattern=$2
  for _source in "${_sources[@]}"
  do
    IFS='/' read -r _domain _account _repo <<< "${_source}"
    _version="$(
      fetch_versions ${_domain} ${_account} ${_repo} |
      GREP_OPTIONS="" \grep "^${_pattern:-}" | tail -n 1
    )"
    if
      [[ -n ${_version} ]]
    then
      echo "${_version}"
      return 0
    fi
  done
}

# Returns a sorted list of all version tags from a repository
fetch_versions()
{
  typeset _account _domain _repo _url
  _domain=$1
  _account=$2
  _repo=$3
  case ${_domain} in
    (bitbucket.org)
      _url=https://${_domain}/api/1.0/repositories/${_account}/${_repo}/branches-tags
      ;;
    (github.com)
      _url=https://api.${_domain}/repos/${_account}/${_repo}/tags
      ;;

    (*)
      _url=https://${_domain}/api/v3/repos/${_account}/${_repo}/tags
      ;;
  esac
  __dtk_curl -s ${_url} |
    \awk -v RS=',' -v FS='"' '$2=="name"{print $4}' |
    sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n -k 5,5n
}

## duplication marker 32fosjfjsznkjneuera48jae
# -S is automatically added to -s
__dtk_curl()
(
  __dtk_which curl >/dev/null ||
  {
    dtk_error "DTK bootstrap requires 'curl'. Install 'curl' first and try again."
    return 200
  }

  typeset -a __flags
  __flags=( --fail --location --max-redirs 10 )

  [[ "$*" == *"--max-time"* ]] ||
  [[ "$*" == *"--connect-timeout"* ]] ||
    __flags+=( --connect-timeout 30 --retry-delay 2 --retry 3 )

  unset curl
  \curl "${__flags[@]}" "$@" || return $?
)

dtk_error()  { printf "ERROR: %b\n" "$*"; }
__dtk_which(){   which "$@" || return $?; true; }

image_missing() {
  echo -e "\nCannot find docker image ${1}"
  echo "Exiting"
  exit 1
}

HOST_VOLUME=$1
PBUILDERID=$p
GIT_PORT=${GIT_PORT-2222}
WEB_PORT=${WEB_PORT-8080}
STOMP_PORT=${STOMP_PORT-6163}
if [[ -z "$t" ]]; then
  DTK_SERVER_TAG=$(fetch_version sources[@] "")
else
  DTK_SERVER_TAG=$t
fi

server_image="getdtk/dtk-server:${DTK_SERVER_TAG}"
arbiter_image="getdtk/dtk-arbiter"
server_container_name="dtk"
arbiter_container_name="dtk-arbiter"

# set pbuilder argument if provided
if [[ -n $PBUILDERID ]]; then
  PBUILDER_ARG="-e PBUILDERID=${PBUILDERID}"
fi

# pull latest docker images
docker pull $server_image || image_missing $server_image
docker pull $arbiter_image || image_missing $arbiter_image

# check if upgrades are necessary
server_image_latest=`docker inspect --format="{{ .Id }}" ${server_image}:latest 2>/dev/null`
arbiter_image_latest=`docker inspect --format="{{ .Id }}" ${arbiter_image}:latest 2>/dev/null`
server_image_running=`docker inspect --format="{{ .Image }}" ${server_container_name} 2>/dev/null`
arbiter_image_running=`docker inspect --format="{{ .Image }}" ${arbiter_container_name} 2>/dev/null`

# if newer images are available, stop and remove existing containers
# only upgrade the server if latest tag is specified
if [[ "$DTK_SERVER_TAG" == 'latest' ]]; then
  if [[ "$server_image_running" != "$server_image_latest" ]] && [[ -n "$server_image_running" ]]; then
    docker stop $server_container_name
    docker rm $server_container_name
  fi
fi
if [[ "$arbiter_image_running" != "$arbiter_image_latest" ]] && [[ -n "$arbiter_image_running" ]]; then
  docker stop $arbiter_container_name
  docker rm $arbiter_container_name
fi

# start the dtk-server container if it doesn't already exist
if ! docker inspect '--format={{ .Image }}' $server_container_name >/dev/null 2>&1; then
  docker run --name $server_container_name -v $HOST_VOLUME:/host_volume -p $WEB_PORT:80 -p $STOMP_PORT:6163 -p $GIT_PORT:22 --restart=on-failure -d $server_image
fi

# wait for dtk-arbiter ssh keypair to be generated
while [[ ! -f $HOST_VOLUME/arbiter/arbiter_remote ]]; do
  sleep 2
done

# check if docker daemon socket is available
# and mount it inside dtk-arbiter contianer if so
additional_args=''
if [[ -e /var/run/docker.sock ]]; then
  additional_args="-v /var/run/docker.sock:/var/run/docker.sock "
fi

# start the dtk-arbiter container if it doesn't already exist
if ! docker inspect '--format={{ .Image }}' $arbiter_container_name >/dev/null 2>&1; then
  docker run --name $arbiter_container_name $PBUILDER_ARG -v $HOST_VOLUME:/host_volume -e HOST_VOLUME=$HOST_VOLUME $additional_args --restart=on-failure -td $arbiter_image
fi
