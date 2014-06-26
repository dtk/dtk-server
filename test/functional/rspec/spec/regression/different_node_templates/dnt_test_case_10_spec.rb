#!/usr/bin/env ruby
# Test Case 10: Elasticsearch - Simple scenario

require 'rubygems'
require 'rest_client'
require 'elasticsearch'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

service_name = 'dnt_test_case_10_instance'
assembly_name = 'elasticsearch_test::elasticsearch_simple'
elasticsearch_http_port = 9200
elasticsearch_tcp_port = 9300

node_name = 'test1'
puppet_log_location = '/var/log/puppet/last.log'
puppet_grep_pattern = 'transaction'

dtk_common = DtkCommon.new(service_name, assembly_name)

def get_node_ec2_public_dns(service_name, node_name)
	puts "Get node ec2 public dns:", "------------------------"
	node_ec2_public_dns = ""
	dtk_common = DtkCommon.new('','')

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

def index_and_retrieve_document(elasticsearch_host, elasticsearch_http_port)
	puts "Index document and retrieve its content:", "----------------------------------------"
	document_retrieved = false

	es = Elasticsearch::Client.new hosts: ["#{elasticsearch_host}:#{elasticsearch_http_port}"]
	es.index index: 'my_index', type: 'blog', id: 1, body: { title: "My first blog", content: "This is some content..." }

	5.downto(1) do |i|
		sleep 1
		document = es.search index: 'my_index', type: 'blog', body: { query: { match: { title: 'My*' } } }
		puts "Retrieved document:"
		ap document
		if !document.nil?
			query_result = document['hits']['hits'].select { |x| x['_index'].include? 'my_index' and x['_type'].include? 'blog'}.first
			if !query_result.nil?
				puts "Relevant document is retrieved!"
				puts ""
				document_retrieved = true
				break
			end
		end
	end

	if document_retrieved == false
		puts "Relevant document is not retrieved!"
		puts ""
	end

	return document_retrieved	
end

describe "(Different Node Templates) Test Case 10: Elasticsearch - Simple scenario" do

	before(:all) do
		puts "************************************************************************"
		puts "(Different Node Templates) Test Case 10: Elasticsearch - Simple scenario"
		puts "************************************************************************"
		puts ""
  	end

	context "Stage service function on #{assembly_name} assembly" do
		include_context "Stage", dtk_common
	end

	context "List services after stage" do		
		include_context "List services after stage", dtk_common
	end

	context "Converge function" do
		include_context "Converge service", dtk_common, 30
	end

	context "Grep command on puppet log on redis master instance" do
		include_context "Grep log command", dtk_common, node_name, puppet_log_location, puppet_grep_pattern
	end

	context "Elasticsearch http port #{elasticsearch_http_port}" do
		include_context "Check if port avaliable on specific node", dtk_common, node_name, elasticsearch_http_port
	end

	context "Elasticsearch transport port #{elasticsearch_tcp_port}" do
		include_context "Check if port avaliable on specific node", dtk_common, node_name, elasticsearch_tcp_port
	end

	context "Connect to Elasticsearch instance, index new document and get that document by query" do
		it "connects to Elasticsearch instance and adds document and retrieves it by query" do
			puts "Connect to Elasticsearch, index and get document", "------------------------------------------------"
			elasticsearch_host = get_node_ec2_public_dns(service_name, node_name)
			document_retrieved = index_and_retrieve_document(elasticsearch_host, elasticsearch_http_port)
			puts ""
			document_retrieved.should eq(true)
		end
	end

	context "Delete and destroy service function" do
		include_context "Delete services", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end