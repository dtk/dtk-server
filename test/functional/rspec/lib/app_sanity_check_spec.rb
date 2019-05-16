require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

STDOUT.sync = true

node_port_prometheus = '30900'
prometheus_path = '/metrics'
node_port_grafana = '30901'
grafana_path = '/login'

shared_context 'Sanity check of prometheus instance' do |dtk_common, service_instance_name, node_name|
  it "checks that prometheus instance is running on kubernetes cluster" do
    response = false
    node = dtk_common.get_node_by_name(service_instance_name, node_name)
    if node
      response = dtk_common.check_if_instance_running(node['dns_address'], node_port_prometheus, prometheus_path);
    end
    expect(response).to eq(true)
  end
end

shared_context 'Sanity check of grafana instance' do |dtk_common, service_instance_name, node_name|
  it "checks that grafana instance is running on kubernetes cluster" do
    response = false
    node = dtk_common.get_node_by_name(service_instance_name, node_name)
    if node
      response = dtk_common.check_if_instance_running(node['dns_address'], node_port_grafana, grafana_path);
    end
    expect(response).to eq(true)
  end
end
