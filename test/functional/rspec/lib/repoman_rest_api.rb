require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require 'yaml'

class RepomanRestApi
  attr_reader :repoman_url
  attr_accessor :authorization_token

  def initialize
    config_yml = YAML.load(File.open('./config/config.yml'))
    @repoman_url = config_yml['r8server']['repoman']
  end

  def send_request(endpoint, rest_method, args = {}, headers = {})
    fail 'Incorrect REST method has been specified' unless ['GET', 'POST', 'DELETE'].include? rest_method

    if rest_method == 'GET'
      begin
        response = RestClient.get(self.repoman_url + endpoint, headers)
        return JSON.parse(response)
      rescue => e
        return JSON.parse(e.response)
      end
    elsif rest_method == 'POST'
      begin
        response = RestClient.post(self.repoman_url + endpoint, args, headers)
        return JSON.parse(response)
      rescue => e
        return JSON.parse(e.response)
      end
    elsif rest_method == 'DELETE'
      begin
        response = RestClient.delete(self.repoman_url + endpoint, headers)
        return JSON.parse(response)
      rescue => e
        return JSON.parse(e.response)
      end
    end
  end

  def login(username, password)
    response = self.send_request('/v1/auth/login', 'POST', username: username, password: password)
    self.authorization_token = response['data']['token']
  end

  def logout
    self.send_request('/v1/auth/logout', 'POST', {}, Authorization: "Token token=\"#{self.authorization_token}\"")
  end

  def get_repos_by_user(user)
    self.send_request("/users/#{user}/repos", 'GET', {}, Authorization: "Token token=\"#{self.authorization_token}\"")
  end

  def check_if_user_exists(username, email)
    return self.send_request('/users/check_exists', 'POST', { username: username, email: email }, Authorization: "Token token=\"#{self.authorization_token}\"") unless (username.nil? || email.nil?)
    return self.send_request('/users/check_exists', 'POST', { username: username }, Authorization: "Token token=\"#{self.authorization_token}\"") if email.nil?
    return self.send_request('/users/check_exists', 'POST', { email: email }, Authorization: "Token token=\"#{self.authorization_token}\"") if username.nil?
  end

  def create_user(username, email, first_name, last_name)
    return self.send_request('/users', 'POST', { username: username, email: email, first_name: first_name, last_name: last_name }, Authorization: "Token token=\"#{self.authorization_token}\"") unless (username.nil? || email.nil?)
    return self.send_request('/users', 'POST', { username: username, first_name: first_name, last_name: last_name }, Authorization: "Token token=\"#{self.authorization_token}\"") if email.nil?
    return self.send_request('/users', 'POST', { email: email, first_name: first_name, last_name: last_name }, Authorization: "Token token=\"#{self.authorization_token}\"") if username.nil?
  end

  def get_users
    self.send_request('/v1/users/list', 'GET', {}, Authorization: "Token token=\"#{self.authorization_token}\"")
  end

  def delete_user(user_id)
    self.send_request("/v1/users/#{user_id}", 'DELETE', {}, Authorization: "Token token=\"#{self.authorization_token}\"")
  end

  def get_user_groups
    self.send_request('/v1/user_groups/list', 'GET', {}, Authorization: "Token token=\"#{self.authorization_token}\"")
  end

  def delete_user_group(user_group_id)
    self.send_request("/v1/user_groups/#{user_group_id}", 'DELETE', {}, Authorization: "Token token=\"#{self.authorization_token}\"")
  end

  def get_namespaces
    self.send_request('/v1/namespaces/list', 'GET', {}, Authorization: "Token token=\"#{self.authorization_token}\"")
  end

  def delete_namespace(namespace_id)
    self.send_request("/v1/namespaces/#{namespace_id}", 'DELETE', {}, Authorization: "Token token=\"#{self.authorization_token}\"")
  end

  def get_modules_by_namespace(namespace)
    self.send_request("/namespaces/#{namespace}/modules", 'GET', {}, Authorization: "Token token=\"#{self.authorization_token}\"")
  end

  def check_if_namespace_exists(namespace)
    self.send_request('/namespaces/check_exists', 'POST', { name: namespace }, Authorization: "Token token=\"#{self.authorization_token}\"")
  end
end
