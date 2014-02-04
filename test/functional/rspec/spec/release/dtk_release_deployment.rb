#!/usr/bin/env ruby
#This is DTK artifacts deployment script which is used to deploy all DTK artifacts through DTK Server

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require 'yaml'
require './lib/dtk_common'

assembly_name = 'dtk_release_deployment'
assembly_template = 'dtk::release'

dtk_common = DtkCommon.new(assembly_name, assembly_template)
config = YAML::load(File.open("./config/release.yml"))

assembly_id = dtk_common.stage_assembly

begin
	if dtk_common.check_if_assembly_exists(assembly_id)
		#Set attributes for assembly template
		set_attributes_array = []
		set_attributes_array << dtk_common.set_attribute(assembly_id, 'repo_manager/common_user/user', "git")
		set_attributes_array << dtk_common.set_attribute(assembly_id, 'repo_manager/gitolite/gitolite_user', "git")
		set_attributes_array << dtk_common.set_attribute(assembly_id, 'tenant/dtk_addons::jenkins_swarm_client/password', config['properties']['jenkins_password'])
		set_attributes_array << dtk_common.set_attribute(assembly_id, 'tenant/dtk_addons::remote/destination_password', config['properties']['server_password'])
		set_attributes_array << dtk_common.set_attribute(assembly_id, 'tenant/dtk_addons::test_scripts_setup/server_password', config['properties']['server_password'])
		set_attributes_array << dtk_common.set_attribute(assembly_id, 'tenant/dtk_client/dtk_client_password', config['properties']['server_password'])
	    set_attributes_array << dtk_common.set_attribute(assembly_id, 'tenant/dtk_server::tenant/aws_access_key_id', config['properties']['aws_access_key_id'])
		set_attributes_array << dtk_common.set_attribute(assembly_id, 'tenant/dtk_server::tenant/aws_secret_access_key', config['properties']['aws_secret_access_key'])

		#Set tags that will be used to checkout correct versions of DTK artifacts for this release
		set_attributes_array << dtk_common.set_attribute(assembly_id, 'repo_manager/dtk_repo_manager/release_tag', config['properties']['server_release'])
		set_attributes_array << dtk_common.set_attribute(assembly_id, 'tenant/dtk_server::tenant/server_git_branch', config['properties']['repo_manager_release'])

		#If all attribures have been set, proceed with dtk::release converge
		if !set_attributes_array.include? false
	  		assembly_converged = dtk_common.converge_assembly(assembly_id, 70)
	  		if assembly_converged == true
	    		puts "#{assembly_template} assembly deployed!"
	  		else
	    		raise "[ERROR] #{assembly_template} assembly was not deployed successfully!"
	  		end
		else
	  		raise "[ERROR] Some of the attributes are not set correctly. Will not proceed with converge process!"
		end
	else
		raise "[ERROR] #{assembly_template} assembly is not staged and therefore deployment of DTK artifacts will not continue!"
	end
end