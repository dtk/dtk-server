# Common class with methods used for interaction with dtk server
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require 'yaml'
require File.expand_path('../client_access/dtk_client_accessor', __FILE__)
require File.expand_path('../mixins/assembly_and_service_operations_mixin.rb', __FILE__)
require File.expand_path('../mixins/node_operations_mixin.rb', __FILE__)
require File.expand_path('../mixins/workspace_mixin.rb', __FILE__)
require File.expand_path('../mixins/target_mixin.rb', __FILE__)
require File.expand_path('../mixins/component_modules_mixin.rb', __FILE__)
require File.expand_path('../mixins/component_modules_version_mixin.rb', __FILE__)
require File.expand_path('../mixins/service_modules_mixin.rb', __FILE__)
require File.expand_path('../mixins/service_modules_version_mixin.rb', __FILE__)
require File.expand_path('../mixins/test_modules_mixin.rb', __FILE__)

STDOUT.sync = true

class Common
	include AssemblyAndServiceOperationsMixin
	include NodeOperationsMixin
	include WorkspaceMixin
	include TargetMixin
	include ComponentModulesMixin
	include ServiceModulesMixin
	include TestModulesMixin
	include ComponentModulesVersionMixin
	include ServiceModulesVersionMixin

	attr_accessor :server, :port, :endpoint, :username, :password
	attr_accessor :service_name, :service_id, :assembly, :node_id, :success, :error_message, :server_log, :ssh_key
	attr_accessor :component_module_id_list, :component_module_name_list

	$opts = {
		:timeout => 100,
		:open_timeout => 50,
		:cookies => {}
	}

	def initialize(service_name, assembly_name)
		config_yml = YAML::load(File.open(File.join(File.dirname(__FILE__), '..', "config/config.yml")))		

		@service_name = service_name
		#Fixed current format of assembly name
		@assembly = assembly_name.gsub!("::","/")
		@server = config_yml['r8server']['server']
		@port = config_yml['r8server']['port']
		@endpoint = "#{@server}:#{@port}"
		@username = config_yml['r8server']['username']
	  @password = config_yml['r8server']['password']
	  @server_log = config_yml['r8server']['log']
	  @ssh_key = config_yml['r8server']['ssh_key']

		#used as placeholders for component ids/names for specific module that are accumulated
		@component_module_id_list = Array.new()
		@component_module_name_list = Array.new()
    login
	end

	def login
	  #Login to dtk application
	  response_login = RestClient.post(@endpoint + '/rest/user/process_login', 'username' => @username, 'password' => @password, 'server_host' => @server, 'server_port' => @port)
	  $cookies = response_login.cookies
	  $opts[:cookies] = response_login.cookies
	end

	def get_server_log_for_specific_search_pattern(search_start_pattern, number_of_lines_after)
		log_part_from_start_pattern = []
		log_part = []
		final_log = []

		#read server log to an array
		server_log = File.readlines(@server_log)
		
		#reverse server log and search for start pattern
		server_log.reverse!
		server_log.each do |line|
			log_part_from_start_pattern << line
			if line.include? search_start_pattern
				break
			end
		end

		# reverse server log again (back to normal) and print next N lines
		log_part_from_start_pattern.reverse!
		log_part_from_start_pattern.each_with_index do |line, index|
    	if index < number_of_lines_after
        log_part << log_part_from_start_pattern[index]
    	end
		end

    log_part
	end

	def server_log_print()
		search_string = "Exiting!"
		log_part_from_last_restart = []
		log_part = []
		final_log = []

		#read server log to an array
		server_log = File.readlines(@server_log)
		
		#reverse the array content and go through the log and break when first occurence of restarted server found!
		#write that part of the log to server_log array
		server_log.reverse!
		server_log.each do |line|
			log_part_from_last_restart << line
			if line.include? search_string
				break
			end
		end

		#search for the error that happened in log_part_from_last_restart array and print out next 20 lines in it
		log_part_from_last_restart.each_with_index do |line, index|
			if line.include? "error"
				for i in index-20..index
					log_part << log_part_from_last_restart[i]
				end
				break
			end
		end

		log_part.reverse!
    log_part.each do |line|
      if line.include? search_string
        break
      else
        final_log << line
      end
    end
		return final_log
	end

	def send_request(path, body)
		resource = RestClient::Resource.new(@endpoint + path, $opts)
		response = resource.post(body)
		response_JSON = JSON.parse(response)

		#If response contains errors, accumulate all errors to error_message
		unless response_JSON["errors"].nil? 
			@error_message = ""
			response_JSON["errors"].each { |e| @error_message += "#{e['code']}: #{e['message']} "}
		end

		#If response status notok, show error_message
		if (response_JSON["status"] == "notok")
			puts "", "Request failed!"
			puts @error_message
			unless response_JSON["errors"].first["backtrace"].nil? 
				puts "", "Backtrace:"
				pretty_print_JSON(response_JSON["errors"].first["backtrace"])				
			end
		else
			@error_message = ""
		end
		return response_JSON
	end

	def pretty_print_JSON(json_content)
		return ap json_content
	end

	def set_default_namespace(namespace)
		puts "Set default namespace:", "---------------------"
		default_namespace_set = false
		response = send_request('/rest/account/set_default_namespace', {:namespace=>namespace})
	  if response['status'] == 'ok'
	  	puts "Default namespace is set to #{namespace}"
	  	default_namespace_set = true
	  else
	  	puts "Default namespace has not been set correctly!"
	  end
	  return default_namespace_set
	end

	def set_catalog_credentials(catalog_username, catalog_password)
		puts "Set catalog credentials:", "------------------------"
		catalog_credentials_set = false
		response = send_request('/rest/account/set_catalog_credentials', {:username=>catalog_username, :password=>catalog_password})
	  if response['status'] == 'ok'
	  	puts "Catalog credentials have been set"
	  	catalog_credentials_set = true
	  else
	  	puts "Catalog credentials has not been set correctly!"
	  end
	  return catalog_credentials_set
	end
end