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

set -e

usage_config() {
  echo -e "Usage:\n$0 dtk_major_tag output_dir\n"
} 

if [[ $# -lt 2 ]]; then 
  usage_config
  exit 1
fi 

# make sure git v2.x is used
git_version=`git --version | awk '{print $3}' | cut -d'.' -f1`
if [[ $git_version -lt 2 ]]; then
  echo "git 2.x is required. please upgrade."
  exit 1
fi

## Properties
# Major release tag
dtk_major_tag=$1
dtk_dsl_major_tag=$2
# Output repo directory:
output_dir=$3

# DTK repos url
dtk_client="git@github.com:dtk/dtk-client.git"
dtk_shell="git@github.com:dtk/dtk-shell.git"
dtk_dsl="git@github.com:dtk/dtk-dsl.git"
dtk_common="git@github.com:dtk/dtk-common.git"
dtk_common_core="git@github.com:dtk/dtk-common-core.git"
dtk_node_agent="git@github.com:dtk/dtk-node-agent.git"
dtk_repo_manager="git@github.com:dtk/dtk-repo-manager.git"
dtk_repo_manager_admin="git@github.com:dtk/dtk-repo-manager-admin.git"
dtk_server="git@github.com:dtk/dtk-server.git"
dtk_provisioning="git@github.com:dtk/dtk-provisioning.git"
dtk_arbiter="git@github.com:dtk/dtk-arbiter.git"

dtk_repos=()
dtk_repos+=($dtk_dsl)
dtk_repos+=($dtk_common_core)
dtk_repos+=($dtk_common)
dtk_repos+=($dtk_client)
dtk_repos+=($dtk_shell)
dtk_repos+=($dtk_node_agent)
dtk_repos+=($dtk_repo_manager_admin)
dtk_repos+=($dtk_repo_manager)
dtk_repos+=($dtk_provisioning)
dtk_repos+=($dtk_arbiter)
dtk_repos+=($dtk_server)

function increase_version_number() {
  current_tag=$1
  # get last number in tag and increment it
  subtag=`echo $current_tag | cut -d. -f3`
  increment_subtag=$((subtag + 1))

  a=`echo $current_tag | cut -d. -f1`
  b=`echo $current_tag | cut -d. -f2`

  # concatenate first tag part with incremented tag number
  echo "$a.$b.$increment_subtag"
}

function set_release_yaml_file() {
  dtk_major_tag=$1
  cd ..
  for repo in ${dtk_repos[@]}; do
    repo_name=`echo ${repo} | cut -d/ -f2 | sed 's/.git//'`
    cd $repo_name
    tag=`git tag --sort=v:refname | tail -1`
    cd ..
    if [[ $repo_name == "dtk-server" ]]; then
      if [[ $dtk_major_tag == "not_set" ]]; then
        next_tag=`increase_version_number $tag`
        sed -i -e "s#server:.*#server: ${next_tag}#g" ./dtk-server/test/functional/rspec/config/release.yaml
      else
        sed -i -e "s#server:.*#server: ${dtk_major_tag}#g" ./dtk-server/test/functional/rspec/config/release.yaml
      fi
    else
      sed -i -e "s#${repo_name}:.*#${repo_name}: ${tag}#g" ./dtk-server/test/functional/rspec/config/release.yaml
    fi
  done
}

# Function that compares current dtk-dsl version in dtk-client with actual dtk-dsl version
# if dtk-dsl = 1.0.0 in dtk-client.gemspec but actual dtk-dsl version is 1.1.0, make change in dtk-client.gemspec
# if dtk-dsl = 1.0.0 in dtk-client.gemspec but actual dtk-dsl version is 1.0.1, don't make change
# Reason for this logic is dependency defined in dtk-client: 'dtk-dsl', '~> 1.0.0'
function check_dtk_dsl_version() {
  current_dtk_dsl_version_in_gemspec=$1
  dtk_dsl_tag=`git tag --sort=v:refname | tail -1`

  a=`echo v$current_dtk_dsl_version_in_gemspec | cut -d. -f 1,2`
  b=`echo $dtk_dsl_tag | cut -d. -f 1,2`

  if [[ $a == $b ]]; then
    tag=$current_dtk_dsl_version_in_gemspec
  else
    tag=$dtk_dsl_tag
  fi
  echo $tag
}

# special logic for dtk-dsl which is not versioned like other dtk repos
function tag_dtk_dsl() {
  dtk_dsl_major_tag=$1

  commit_message=`git log --oneline -1`

  if [[ $commit_message != *"ump version"* && $dtk_dsl_major_tag == "not_set" ]]; then
    current_tag=`git tag --sort=v:refname | tail -1`
    incremented_tag=`increase_version_number $current_tag`
    tag=`echo $incremented_tag | sed 's/v//'`
    echo "Needed bump of version for dtk-dsl to version ${incremented_tag}..."

    cd lib/dsl
    sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
    cd ../..
    git add .; git commit -m "bump version"; git push origin master
    git tag $incremented_tag
    git push --tags
  elif [[ $dtk_dsl_major_tag != "not_set" ]]; then
    echo "Needed bump of version for dtk-dsl to version ${dtk_dsl_major_tag}..."
    tag=`echo $dtk_dsl_major_tag | sed 's/v//'`

    cd lib/dsl
    sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
    cd ../..
    git add .; git commit -m "bump version"; git push origin master
    git tag $dtk_dsl_major_tag
    git push --tags
  fi
}

function tag_code() {
  dtk_major_tag=$1
  dtk_repo=$2
  repo_name=$3

  # get latest commit message
  commit_message=`git log --oneline -1`

  if [[ $commit_message != *"ump version"* && $dtk_major_tag == "not_set" ]]; then
    # get latest tag
    current_tag=`git tag --sort=v:refname | tail -1`
    next_tag=`increase_version_number $current_tag`
    tag=`echo $next_tag | sed 's/v//'`
    echo "Needed bump of version for ${dtk_repo} to version ${next_tag}..."

    if [[ $repo_name == "dtk-node-agent" ]]; then
      cd lib/$repo_name
      sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
      cd ../..
      git add .; git commit -m "bump version"; git push origin master
      # Merge master to stable branch
      git checkout stable
      git pull origin stable
      git merge master
      git push origin stable
      git tag $next_tag
      git push --tags
    elif [[ $repo_name == "dtk-arbiter" ]]; then
      current_commit_msg=`git log --oneline -1`
      git checkout $current_tag
      current_commit_msg_on_tag=`git log --oneline -1`
      git checkout master
      if [[ $current_commit_msg != $current_commit_msg_on_tag ]]; then
        # Merge master to stable branch
        git checkout stable
        git pull origin stable
        git merge master
        git push origin stable
        git tag $next_tag
        git push --tags
      fi
    elif [[ $repo_name == "dtk-common" || $repo_name == "dtk-shell" ]]; then
      cd lib/$repo_name
      sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
      cd ../..
      cd ../dtk-common-core && dtk_common_core_tag=`git tag --sort=v:refname | tail -1` && cd ../$repo_name
      gemspec_tag=`echo $dtk_common_core_tag | sed 's/v//'`
      sed -i -e "s/'dtk-common-core','.*'/'dtk-common-core','${gemspec_tag}'/" $repo_name.gemspec
      git add .; git commit -m "bump version"; git push origin master
      git tag $next_tag
      git push --tags
    elif [[ $repo_name == "dtk-client" ]]; then
      cd lib/cli
      sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
      cd ../..

      # check dtk-common-core version
      cd ../dtk-common-core && dtk_common_core_tag=`git tag --sort=v:refname | tail -1` && cd ../$repo_name
      gemspec_tag=`echo $dtk_common_core_tag | sed 's/v//'`
      sed -i -e "s/'dtk-common-core','.*'/'dtk-common-core','${gemspec_tag}'/" $repo_name.gemspec

      # check dtk-dsl version
      current_dtk_dsl_version_from_gemspec=`cat $repo_name.gemspec | grep dtk-dsl | cut -d\' -f4 | tr -d "~> "`
      cd ../dtk-dsl
      dtk_dsl_tag=`check_dtk_dsl_version $current_dtk_dsl_version_from_gemspec`
      cd ../$repo_name
      dtk_client_gemspec_tag=`echo $dtk_dsl_tag | sed 's/v//'`
      sed -i -e "s/'dtk-dsl', '.*'/'dtk-dsl', '~> ${dtk_client_gemspec_tag}'/" $repo_name.gemspec

      git add .; git commit -m "bump version"; git push origin master
      git tag $next_tag
      git push --tags
    elif [[ $repo_name == "dtk-common-core" ]]; then
      cd lib/$repo_name
      sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
      cd ../..
      git add .; git commit -m "bump version"; git push origin master
      git tag $next_tag
      git push --tags
    elif [[ $repo_name == "dtk-server" ]]; then
      set_release_yaml_file "not_set"
      cd $repo_name
      bundle update dtk-common # updates both dtk-common and dtk-common-core
      bundle update dtk-dsl
      git add .; git commit -m "bump versions for release.yaml"; git push origin master
      git tag $next_tag
      git push --tags
      export DTK_SERVER_TAG=$next_tag
      cd ..   
    else
      current_commit_msg=`git log --oneline -1`
      git checkout $current_tag
      current_commit_msg_on_tag=`git log --oneline -1`
      git checkout master
      if [[ $current_commit_msg != $current_commit_msg_on_tag ]]; then
        git tag $next_tag
        git push --tags
      fi
    fi
  elif [[ $dtk_major_tag != "not_set" ]]; then
    echo "Needed bump of version for ${dtk_repo} to version ${dtk_major_tag}..."
    tag=`echo $dtk_major_tag | sed 's/v//'`

    if [[ $repo_name == "dtk-node-agent" ]]; then
      cd lib/$repo_name
      sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
      cd ../..
      git add .; git commit -m "bump version"; git push origin master
      # Merge master to stable branch
      git checkout stable
      git pull origin stable
      git merge master
      git push origin stable
      git tag $dtk_major_tag
      git push --tags
    elif [[ $repo_name == "dtk-arbiter" ]]; then
      # Merge master to stable branch
      git checkout stable
      git pull origin stable
      git merge master
      git push origin stable
      git tag $dtk_major_tag
      git push --tags
    elif [[ $repo_name == "dtk-common" || $repo_name == "dtk-shell" ]]; then
      cd lib/$repo_name
      sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
      cd ../..
      cd ../dtk-common-core && dtk_common_core_tag=`git tag --sort=v:refname | tail -1` && cd ../$repo_name
      gemspec_tag=`echo $dtk_common_core_tag | sed 's/v//'`
      sed -i -e "s/'dtk-common-core','.*'/'dtk-common-core','${gemspec_tag}'/" $repo_name.gemspec
      git add .; git commit -m "bump version"; git push origin master
      git tag $dtk_major_tag
      git push --tags
    elif [[ $repo_name == "dtk-client" ]]; then
      cd lib/cli
      sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
      cd ../..

      # check dtk-common-core version
      cd ../dtk-common-core && dtk_common_core_tag=`git tag --sort=v:refname | tail -1` && cd ../$repo_name
      gemspec_tag=`echo $dtk_common_core_tag | sed 's/v//'`
      sed -i -e "s/'dtk-common-core','.*'/'dtk-common-core','${gemspec_tag}'/" $repo_name.gemspec

      # check dtk-dsl version
      current_dtk_dsl_version_from_gemspec=`cat $repo_name.gemspec | grep dtk-dsl | cut -d\' -f4 | tr -d "~> "`
      cd ../dtk-dsl
      dtk_dsl_tag=`check_dtk_dsl_version $current_dtk_dsl_version_from_gemspec`
      cd ../$repo_name
      dtk_client_gemspec_tag=`echo $dtk_dsl_tag | sed 's/v//'`
      sed -i -e "s/'dtk-dsl', '.*'/'dtk-dsl', '~> ${dtk_client_gemspec_tag}'/" $repo_name.gemspec

      git add .; git commit -m "bump version"; git push origin master
      git tag $dtk_major_tag
      git push --tags
    elif [[ $repo_name == "dtk-common-core" ]]; then
      cd lib/$repo_name
      sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
      cd ../..
      git add .; git commit -m "bump version"; git push origin master
      git tag $dtk_major_tag
      git push --tags
    elif [[ $repo_name == "dtk-server" ]]; then
      set_release_yaml_file $dtk_major_tag
      cd $repo_name
      bundle update dtk-common
      bundle update dtk-dsl
      git add .; git commit -m "bump versions for release.yaml"; git push origin master
      git tag $dtk_major_tag
      git push --tags
      export DTK_SERVER_TAG=$next_tag
      cd ..
    else
      git tag $dtk_major_tag
      git push --tags
    fi  
  else
    echo "No need for tagging ${dtk_repo}"
  fi
}

for dtk_repo in ${dtk_repos[@]}; do
  content=`ls $output_dir`
  # get repo name from git repo url (for example: dtk-client)
  repo_name=`echo ${dtk_repo} | cut -d/ -f2 | sed 's/.git//'`
  cd $output_dir && git clone $dtk_repo && cd $repo_name
  if [[ $repo_name == 'dtk-dsl' ]];then
    tag_dtk_dsl $dtk_dsl_major_tag
  else
    tag_code $dtk_major_tag $dtk_repo $repo_name
  fi
  cd ../..
done