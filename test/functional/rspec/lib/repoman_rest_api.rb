require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

class RepomanRestApi

	attr_reader :repoman_url

	def initialize(repoman_url)
		@repoman_url = repoman_url
	end

	def send_request(endpoint, rest_method, args={})
		raise "Incorrect REST method has been specified" unless ['GET','POST'].include? rest_method

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
		end
	end

	def get_repos_by_user_id(user_id)
		return self.send_request("/users/#{user_id}/repos", "GET")
	end

	def check_if_user_exists(username, email)
		return self.send_request("/users/check_exists", "POST", {:username=>username, :email=>email}) unless (username==nil || email==nil)
		return self.send_request("/users/check_exists", "POST", {:username=>username}) if email==nil
		return self.send_request("/users/check_exists", "POST", {:email=>email}) if username==nil
	end

	def create_user(username, email, first_name, last_name)
		return self.send_request("/users", "POST", {:username=>username, :email=>email, :first_name=>first_name, :last_name=>last_name})
	end

	def get_modules_by_namespace_id(namespace_id)
		return self.send_request("/namespaces/#{namespace_id}/modules", "GET")
	end

	def check_if_namespace_exists(namespace)
		return self.send_request("/namespaces/check_exists", "POST", {:name=>namespace})
	end
end