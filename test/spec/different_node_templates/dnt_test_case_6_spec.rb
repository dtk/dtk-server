#!/usr/bin/env ruby
#Test Case 6: MongoDB - Single node scenario

require 'rubygems'
require 'mongo'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'

STDOUT.sync = true

$assembly_id = 0
assembly_name = 'dnt_test_case_6_instance'
assembly_template = 'mongodb_test::mongo_single_node'
mongodb_instance_port = 27017
mongodb_webconsole_port = 28017

node_name = 'node1'
puppet_log_location = '/var/log/puppet/last.log'
puppet_grep_pattern = 'transaction'
mongodb_log_location = '/var/log/mongodb/mongodb.log'
mongodb_grep_pattern = '27017'

#MongoDB specifics
database_name = 'test'
collection_name = 'test_collection'
document = {"first_name" => "Bakir", "last_name" => "Jusufbegovic"}

dtk_common = DtkCommon.new(assembly_name, assembly_template)


def get_node_ec2_public_dns(assembly_name, node_name)
	puts "Get node ec2 public dns:", "------------------------"
	node_ec2_public_dns = ""
	dtk_common = DtkCommon.new('','')

	info_response = dtk_common.send_request('/rest/assembly/info_about', {:assembly_id => assembly_name, :subtype => :instance, :about => "nodes"})
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
	puts "Add new document to MongoDB collection:", "---------------------------------------"
	document_added = false

	client = Mongo::MongoClient.new(mongodb_host, mongodb_port)
	db = client.db(database_name)
	collection = db.collection(collection_name)
	id = collection.insert(document)
	puts collection.find.to_a
	document_added = true if !collection.find({"_id" => id}).to_a.empty?
	puts ""
	return document_added
end

describe "(Different Node Templates) Test Case 6: MongoDB - Single node scenario" do

	before(:all) do
		puts "**********************************************************************"
		puts "(Different Node Templates) Test Case 6: MongoDB - Single node scenario"
		puts "**********************************************************************"
		puts ""
  	end

	context "Stage assembly function on #{assembly_template} assembly template" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do		
		include_context "List assemblies after stage", dtk_common
	end

	context "Converge function" do
		include_context "Converge", dtk_common
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

	context "MongoDB shard port #{mongodb_webconsole_port}" do
		include_context "Check if port avaliable", dtk_common, mongodb_webconsole_port
	end

	context "Connect to MongoDB instance and add new document to collection" do
		it "connects to MongoDB instance and adds document to #{collection_name} collection" do
			mongodb_host = get_node_ec2_public_dns(assembly_name, node_name)
			document_added = add_document_to_collection(mongodb_host, mongodb_instance_port, database_name, collection_name, document)
			document_added.should eq(true)
		end
	end

	context "Delete and destroy assembly function" do
		include_context "Delete assemblies", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end