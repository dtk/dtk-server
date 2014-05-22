require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require 'yaml'

class RepomanRestApi

	attr_reader :repoman_url

	def initialize
		config_yml = YAML::load(File.open("./config/config.yml"))
		@repoman_url = config_yml['r8server']['repoman']
	end

	def send_request(endpoint, rest_method, args={})
		raise "Incorrect REST method has been specified" unless ['GET','POST','DELETE'].include? rest_method

		if rest_method == 'GET'
			begin
				response = RestClient.get(self.repoman_url + endpoint)
				return JSON.parse(response)
			rescue => e
				return JSON.parse(e.response)
			end
		elsif rest_method == 'POST'
			begin
				resource = RestClient::Resource.new(self.repoman_url + endpoint)
				response = resource.post(args)
				return JSON.parse(response)
			rescue => e
				return JSON.parse(e.response)
			end
		elsif rest_method == 'DELETE'
			begin
				response = RestClient.delete(self.repoman_url + endpoint)
				return JSON.parse(response)
			rescue => e
				return JSON.parse(e.response)
			end
		end
	end

	def get_repos_by_user(user)
		return self.send_request("/users/#{user}/repos", "GET")
	end

	def check_if_user_exists(username, email)
		return self.send_request("/users/check_exists", "POST", {:username=>username, :email=>email}) unless (username==nil || email==nil)
		return self.send_request("/users/check_exists", "POST", {:username=>username}) if email==nil
		return self.send_request("/users/check_exists", "POST", {:email=>email}) if username==nil
	end

	def create_user(username, email, first_name, last_name)
		return self.send_request("/users", "POST", {:username=>username, :email=>email, :first_name=>first_name, :last_name=>last_name}) unless (username==nil || email==nil)
		return self.send_request("/users", "POST", {:username=>username, :first_name=>first_name, :last_name=>last_name}) if email==nil
		return self.send_request("/users", "POST", {:email=>email, :first_name=>first_name, :last_name=>last_name}) if username==nil
	end

	def get_users
		return self.send_request("/v1/users/list", "GET")
	end

	def delete_user(user_id)
		return self.send_request("/v1/users/#{user_id}", "DELETE")
	end

	def get_user_groups
		return self.send_request("/v1/user_groups/list", "GET")
	end

	def delete_user_group(user_group_id)
		return self.send_request("/v1/user_groups/#{user_group_id}", "DELETE")
	end

	def get_namespaces
		return self.send_request("/v1/namespaces/list", "GET")
	end

	def delete_namespace(namespace_id)
		return self.send_request("/v1/namespaces/#{namespace_id}", "DELETE")
	end

	def get_modules_by_namespace(namespace)
		return self.send_request("/namespaces/#{namespace}/modules", "GET")
	end

	def check_if_namespace_exists(namespace)
		return self.send_request("/namespaces/check_exists", "POST", {:name=>namespace})
	end
end