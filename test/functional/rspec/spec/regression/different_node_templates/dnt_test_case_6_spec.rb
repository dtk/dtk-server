#!/usr/bin/env ruby
# Test Case 6: MongoDB - Single node scenario

require 'rubygems'
require 'mongo'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

service_name = 'dnt_test_case_6_instance'
assembly_name = 'mongodb_test::mongo_single_node'
mongodb_instance_port = 27017
mongodb_webconsole_port = 28017

node_name = 'node1'
puppet_log_location = '/var/log/puppet/last.log'
puppet_grep_pattern = 'transaction'
mongodb_log_location = '/var/log/mongodb/mongodb.log'
mongodb_grep_pattern = '27017'

# MongoDB specifics
database_name = 'test'
collection_name = 'test_collection'
document = {"first_name" => "Bakir", "last_name" => "Jusufbegovic"}

dtk_common = DtkCommon.new(service_name, assembly_name)

def get_node_ec2_public_dns(service_name, node_name)
  puts "Get node ec2 public dns:", "------------------------"
  node_ec2_public_dns = ""
  dtk_common = DtkCommon.new('','')

  info_response = dtk_common.send_request('/rest/assembly/info_about', assembly_id: service_name, subtype: :instance, about: "nodes")
  ap info_response
  node_info = info_response['data'].find { |x| x['display_name'] == node_name}

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
  puts "Add new document to MongoDB collection:", "---------------------------------------"
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
  document_added = true if !collection.find("_id" => id).to_a.empty?
  puts ""
  return document_added
end

describe "(Different Node Templates) Test Case 6: MongoDB - Single node scenario" do
  before(:all) do
    puts "**********************************************************************",""
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context "Stage", dtk_common
  end

  context "List services after stage" do
    include_context "List services after stage", dtk_common
  end

  context "Converge function" do
    include_context "Converge service", dtk_common, 15
  end

  context "Grep command on puppet log" do
    include_context "Grep log command", dtk_common, node_name, puppet_log_location, puppet_grep_pattern
  end

  context "Grep command on mongodb log" do
    include_context "Grep log command", dtk_common, node_name, mongodb_log_location, mongodb_grep_pattern
  end

  context "MongoDB instance port #{mongodb_instance_port}" do
    include_context "Check if port avaliable", dtk_common, mongodb_instance_port
  end

  context "MongoDB webconsole port #{mongodb_webconsole_port}" do
    include_context "Check if port avaliable", dtk_common, mongodb_webconsole_port
  end

  context "Connect to MongoDB instance and add new document to collection" do
    it "connects to MongoDB instance and adds document to #{collection_name} collection" do
      puts "Connect to MongoDB and add new document", "---------------------------------------"
      mongodb_host = get_node_ec2_public_dns(service_name, node_name)
      document_added = add_document_to_collection(mongodb_host, mongodb_instance_port, database_name, collection_name, document)
      puts ""
      document_added.should eq(true)
    end
  end

  context "Delete and destroy service function" do
    include_context "Delete services", dtk_common
  end

  after(:all) do
    puts "", ""
  end
end
