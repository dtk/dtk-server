#!/bin/bash
#set -x

## Properties
# Major release tag
dtk_major_tag=$1
# Output repo directory:
output_dir=$2

# DTK repos url
dtk_client="git@github.com:rich-reactor8/dtk-client.git"
dtk_common="git@github.com:rich-reactor8/dtk-common.git"
dtk_common_core="git@github.com:rich-reactor8/dtk-common-repo.git"
dtk_node_agent="git@github.com:rich-reactor8/dtk-node-agent.git"
dtk_repo_manager="git@github.com:rich-reactor8/dtk-repo-manager.git"
dtk_repo_manager_admin="git@github.com:rich-reactor8/dtk-repoman-admin.git"
dtk_server="git@github.com:rich-reactor8/server.git"

dtk_repos=()
dtk_repos+=($dtk_client)
dtk_repos+=($dtk_common)
dtk_repos+=($dtk_common_core)
dtk_repos+=($dtk_node_agent)
dtk_repos+=($dtk_repo_manager)
dtk_repos+=($dtk_repo_manager_admin)
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
		tag=`git tag | tail -1`
		cd ..
		if [[ $repo_name == "server" ]]; then
			if [[ $dtk_major_tag == "not_set" ]]; then
			  next_tag=`increase_version_number $tag`
			  sed -i -e "s#server:.*#server: ${next_tag}#g" ./server/test/functional/rspec/config/release.yml
			else
				sed -i -e "s#server:.*#server: ${dtk_major_tag}#g" ./server/test/functional/rspec/config/release.yml
			fi
		else
			sed -i -e "s#${repo_name}:.*#${repo_name}: ${tag}#g" ./server/test/functional/rspec/config/release.yml
		fi
	done
}

function tag_code() {
	dtk_major_tag=$1
	dtk_repo=$2
	repo_name=$3

	# get latest commit message
	commit_message=`git log --oneline -1`

	if [[ $commit_message != *"ump version"* && $dtk_major_tag == "not_set" ]]; then
		# get latest tag
		current_tag=`git tag | tail -1`
		next_tag=`increase_version_number $current_tag`
		tag=`echo $next_tag | sed 's/v//'`
		echo "Needed bump of version for ${dtk_repo} to version ${next_tag}..."

		if [[ $repo_name == "dtk-client" || $repo_name == "dtk-common" || $repo_name == "dtk-node-agent" ]]; then
			cd lib/$repo_name
			sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
			cd ../..
			git add .; git commit -m "bump version"; git push origin master
			git tag $next_tag
			git push --tags
		elif [[ $repo_name == "dtk-common-repo" ]]; then
			cd lib/dtk-common-core
			sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
			cd ../..
			git add .; git commit -m "bump version"; git push origin master
			git tag $next_tag
		  git push --tags
		elif [[ $repo_name == "server" ]]; then
			set_release_yaml_file "not_set"
			cd $repo_name
			git add .; git commit -m "bump versions for release.yml"; git push origin master
			git tag $next_tag
			git push --tags
			cd ..
		else 
			git tag $next_tag
			git push --tags
		fi
	elif [[ $dtk_major_tag != "not_set" ]]; then
		echo "Needed bump of version for ${dtk_repo} to version ${dtk_major_tag}..."
		tag=`echo $dtk_major_tag | sed 's/v//'`

		if [[ $repo_name == "dtk-client" || $repo_name == "dtk-common" || $repo_name == "dtk-node-agent" ]]; then
			cd lib/$repo_name
			sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
			cd ../..
			git add .; git commit -m "bump version"; git push origin master
			git tag $dtk_major_tag
			git push --tags
		elif [[ $repo_name == "dtk-common-repo" ]]; then
			cd lib/dtk-common-core
			sed -i -e 's/VERSION=".*"/VERSION="'${tag}'"/' version.rb
			cd ../..
			git add .; git commit -m "bump version"; git push origin master
			git tag $dtk_major_tag
			git push --tags
		elif [[ $repo_name == "server" ]]; then
			set_release_yaml_file $dtk_major_tag
			cd $repo_name
			git add .; git commit -m "bump versions for release.yml"; git push origin master
			git tag $dtk_major_tag
			git push --tags
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

	if [[ $content == *$repo_name* ]]; then
		echo "Tagging code for $repo_name repo..."
		cd $output_dir/$repo_name && git pull origin master
		tag_code $dtk_major_tag $dtk_repo $repo_name
		cd ../..
	else
		cd $output_dir && git clone $dtk_repo && cd $repo_name
		tag_code $dtk_major_tag $dtk_repo $repo_name
		cd ../..
	fi
done