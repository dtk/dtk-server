#!/usr/bin/env ruby
# Test Case 7: MongoDB - Master/Slave scenario

require 'rubygems'
require 'mongo'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

service_name = 'dnt_test_case_7_instance'
assembly_name = 'mongodb_test::mongo_master_slave'
mongodb_instance_port = 27017
mongodb_webconsole_port = 28017
node_name_1 = 'master'
node_name_2 = 'slave'
puppet_log_location = '/usr/share/dtk/tasks/last-task/site-stage.log'
puppet_grep_pattern = 'transaction'
mongodb_log_location = '/var/log/mongodb/mongodb.log'
mongodb_grep_pattern = '27017'

# MongoDB specifics
database_name = 'test'
collection_name = 'test_collection'
document = { 'first_name' => 'Bakir', 'last_name' => 'Jusufbegovic' }

dtk_common = Common.new(service_name, assembly_name)

def get_node_ec2_public_dns(service_name, node_name)
	puts "Get node ec2 public dns:", "------------------------"
	node_ec2_public_dns = ""
	dtk_common = Common.new('','')

	info_response = dtk_common.send_request('/rest/assembly/info_about', {:assembly_id => service_name, :subtype => :instance, :about => "nodes"})
	ap info_response

	node_info = info_response['data'].select { |x| x['display_name'] == node_name}.first

	if !node_info.nil?
		node_ec2_public_dns = node_info['external_ref']['ec2_public_address']
		if !node_ec2_public_dns.nil?
			puts "Node ec2 public dns found!"
			puts ""
			return node_ec2_public_dns
		end
	else
		puts "Info about #{node_name} node is not found!"
		puts ""
		return node_ec2_public_dns
	end
end

def add_document_to_collection(mongodb_host, mongodb_port, database_name, collection_name, document)
  puts 'Add new document to MongoDB collection:', '---------------------------------------'
  document_added = false

  puts "MongoDB host: #{mongodb_host}"
    puts "MongoDB port: #{mongodb_port}"
    puts "Database name: #{database_name}"
    puts "Collection name: #{collection_name}"
    puts "Document: #{document}"

  client = Mongo::MongoClient.new(mongodb_host, mongodb_port)
  db = client.db(database_name)
  collection = db.collection(collection_name)
  id = collection.insert(document)
  puts "Document id: #{id}"
  puts "Collection added: #{collection.find.to_a}"
  document_added = true unless collection.find('_id' => id).to_a.empty?
  puts ''
  document_added
end

def get_collection(mongodb_host, mongodb_port, database_name, collection_name)
  puts 'Get collection from MongoDB slave instance:', '-------------------------------------------'
  collection_exists = false

  puts "MongoDB host: #{mongodb_host}"
  puts "MongoDB port: #{mongodb_port}"
  puts "Database name: #{database_name}"
  puts "Collection name: #{collection_name}"

  client = Mongo::MongoClient.new(mongodb_host, mongodb_port)
  db = client.db(database_name)
  collection = db.collection(collection_name)

  unless collection.find.to_a.empty?
    collection_exists = true
    puts "Collection content: #{collection.find.to_a}"
  end
  puts ''
  collection_exists
end

describe '(Different Node Templates) Test Case 7: MongoDB - Master/Slave scenario' do
  before(:all) do
    puts '***********************************************************************', ''
   end

  context "Stage service function on #{assembly_name} assembly" do
    include_context 'Stage', dtk_common
  end

  context 'List services after stage' do
    include_context 'List services after stage', dtk_common
  end

  context 'Converge function' do
    include_context 'Converge service', dtk_common, 25
  end

  context 'Grep command on puppet log on master instance' do
    include_context 'Grep log command', dtk_common, node_name_1, puppet_log_location, puppet_grep_pattern
  end

  context 'Grep command on mongodb log on master instance' do
    include_context 'Grep log command', dtk_common, node_name_1, mongodb_log_location, mongodb_grep_pattern
  end

  context 'Grep command on puppet log on slave instance' do
    include_context 'Grep log command', dtk_common, node_name_2, puppet_log_location, puppet_grep_pattern
  end

  context 'Grep command on mongodb log on slave instance' do
    include_context 'Grep log command', dtk_common, node_name_2, mongodb_log_location, mongodb_grep_pattern
  end

  context "MongoDB master instance port #{mongodb_instance_port}" do
    include_context 'Check if port avaliable on specific node', dtk_common, node_name_1, mongodb_instance_port
  end

  context "MongoDB master webconsole port #{mongodb_webconsole_port}" do
    include_context 'Check if port avaliable on specific node', dtk_common, node_name_1, mongodb_webconsole_port
  end

  context "MongoDB slave instance port #{mongodb_instance_port}" do
    include_context 'Check if port avaliable on specific node', dtk_common, node_name_2, mongodb_instance_port
  end

  context "MongoDB slave webconsole port #{mongodb_webconsole_port}" do
    include_context 'Check if port avaliable on specific node', dtk_common, node_name_2, mongodb_webconsole_port
  end

  context 'Connect to MongoDB master instance and add new document to collection' do
    it "connects to MongoDB master instance and adds document to #{collection_name} collection" do
      puts 'Connect to MongoDB master and add new document', '----------------------------------------------'
      mongodb_host = get_node_ec2_public_dns(service_name, node_name_1)
      document_added = add_document_to_collection(mongodb_host, mongodb_instance_port, database_name, collection_name, document)
      puts ''
      document_added.should eq(true)
    end
  end

  context 'Connect to MongoDB slave instance and check if collection is replicated' do
    it "connects to MongoDB slave instance and verifies that #{collection_name} collection is replicated" do
      puts 'Connect to MongoDB slave and check replication', '----------------------------------------------'
      mongodb_host = get_node_ec2_public_dns(service_name, node_name_2)
      collection_replicated = get_collection(mongodb_host, mongodb_instance_port, database_name, collection_name)
      puts ''
      collection_replicated.should eq(true)
    end
  end

  context 'Delete and destroy service function' do
    include_context 'Delete services', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end