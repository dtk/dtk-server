require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context 'Stage' do |dtk_common|
  it "stages #{dtk_common.service_name} service from assembly" do
    dtk_common.stage_service()
    expect(dtk_common.service_id).not_to eq(nil)
  end
end

shared_context 'List components versions' do |dtk_common, components_versions_list|
  it "gives list of all components on the service and matches them with given #{components_versions_list} input" do
    components_versions_exist = true
    components_versions_retrieved = dtk_common.get_components_versions(dtk_common.service_id)
    puts components_versions_retrieved
    components_versions_list.each do |c|
      unless components_versions_retrieved.include? c
        components_versions_exist = false
        break
      end
    end
    expect(components_versions_exist).to eq(true)
  end
end

shared_context 'Stage with namespace' do |dtk_common, namespace|
  it "stages #{dtk_common.service_name} service from assembly in namespace #{namespace}" do
    dtk_common.stage_service_with_namespace(namespace)
    expect(dtk_common.service_id).not_to eq(nil)
  end
end

shared_context 'Rename service' do |dtk_common, new_service_name|
  it "renames #{dtk_common.service_name} service to #{new_service_name}" do
    service_renamed = dtk_common.rename_service(dtk_common.service_id, new_service_name)
    expect(service_renamed).to eq(true)
  end
end

shared_context 'NEG - Rename service to existing name' do |service_name, new_service_name|
  it "does not rename #{service_name} service to #{new_service_name} since #{new_service_name} already exists" do
    puts 'NEG - Rename service to existing name:', '---------------------------------------'
    pass = false
    value = `dtk-run service rename #{service_name} #{new_service_name}`
    puts value
    pass = true if value.include? "[ERROR] Service with name '#{new_service_name}' exists already."
    puts 'Rename did not passed successfully which is expected!' if pass == true
    puts 'Rename passed successfully!' if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'NEG - Rename service to workspace name' do |service_name|
  it "does not rename #{service_name} service to workspace since workspace is special type of service" do
    puts 'NEG - Rename service to workspace name:', '----------------------------------------'
    pass = false
    value = `dtk-run service rename #{service_name} workspace`
    puts value
    pass = true if value.include? "[ERROR] You are not allowed to use keyword 'workspace' as service name."
    puts 'Rename did not passed successfully which is expected!' if pass == true
    puts 'Rename passed successfully!' if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'List services after stage' do |dtk_common|
  it "has staged #{dtk_common.service_name} service in service list" do
    service_exists = dtk_common.check_if_service_exists(dtk_common.service_id)
    expect(service_exists).to eq(true)
  end
end

shared_context 'NEG - List services' do |dtk_common|
  it "does not have #{dtk_common.service_name} service in service list" do
    service_exists = dtk_common.check_if_service_exists(dtk_common.service_id)
    expect(service_exists).to eq(false)
  end
end

shared_context 'Converge' do |dtk_common|
  it "converges #{dtk_common.service_name} service" do
    converge = dtk_common.converge_service(dtk_common.service_id)
    expect(converge).to eq(true)
  end
end

shared_context 'NEG - Converge' do |dtk_common|
  it "does not converge #{dtk_common.service_name} service" do
    converge = dtk_common.converge_service(dtk_common.service_id)
    expect(converge).to eq(false)
  end
end

# converge with parametrized max retries
shared_context 'Converge service' do |dtk_common, max_retries|
  it "converges #{dtk_common.service_name} service" do
    converge = dtk_common.converge_service(dtk_common.service_id, max_retries)
    expect(converge).to eq(true)
  end
end

shared_context 'Check if port avaliable' do |dtk_common, port|
  it 'is avaliable' do
    netstat_response = dtk_common.netstats_check(dtk_common.service_id, port)
    expect(netstat_response).to eq(true)
  end
end

shared_context 'Check if port avaliable on specific node' do |dtk_common, node_name, port|
  it "is avaliable on #{node_name} node" do
    netstat_response = dtk_common.netstats_check_for_specific_node(dtk_common.service_id, node_name, port)
    expect(netstat_response).to eq(true)
  end
end

shared_context 'Stop service' do |dtk_common|
  it "stops #{dtk_common.service_name} service " do
    stop_status = dtk_common.stop_running_service(dtk_common.service_id)
    expect(stop_status).to eq(true)
  end
end

shared_context 'Delete services' do |dtk_common|
  it "deletes #{dtk_common.service_name} service" do
    service_deleted = dtk_common.delete_and_destroy_service(dtk_common.service_id)
    expect(service_deleted).to eq(true)
  end
end

shared_context 'List services after delete' do |dtk_common|
  it "doesn't have #{dtk_common.service_name} service in service list" do
    service_exists = dtk_common.check_if_service_exists(dtk_common.service_id)
    expect(service_exists).to eq(false)
  end
end

shared_context 'Delete assembly' do |dtk_common, assembly_name, namespace|
  it "deletes #{assembly_name} assembly" do
    assembly_deleted = dtk_common.delete_assembly(assembly_name, namespace)
    expect(assembly_deleted).to eq(true)
  end
end

shared_context 'Create assembly from service' do |dtk_common, service_name, assembly_name, namespace|
  it "creates #{assembly_name} assembly in #{service_name} service module from existing service" do
    assembly_created = dtk_common.create_assembly_from_service(dtk_common.service_id, service_name, assembly_name, namespace)
    expect(assembly_created).to eq(true)
  end
end

shared_context 'Grep log command' do |dtk_common, node_name, log_location, grep_pattern|
  it "finds #{grep_pattern} pattern in #{log_location} log on converged node" do
    grep_pattern_found = dtk_common.grep_node(dtk_common.service_id, node_name, log_location, grep_pattern)
    expect(grep_pattern_found).to eq(true)
  end
end

shared_context 'List component dependencies' do |dtk_common, service_instance, source_component, dependency_component, type|
  it "checks that #{source_component} has dependency on #{dependency_component} and with type #{type}" do
    dependency_found = dtk_common.check_component_depedency(service_instance, source_component, dependency_component, type)
    expect(dependency_found).to eq(true)
  end
end

shared_context 'Check component dependencies' do |dtk_common, service_instance, dependency_list|
  it "checks #{dependency_list}" do
    dependencies_found = []
    expected_array = []
    # populate expected values
    dependency_list.each do |dep|
      expected_array << true
    end

    dependency_list.each do |dependency|
      dependencies_found << dtk_common.check_component_depedency(service_instance, dependency[:component_name], dependency[:dependency_component], dependency[:type])
    end
    expect(dependencies_found).to match_array(expected_array)
  end
end

shared_context 'Push assembly updates' do |dtk_common, service_module|
  it 'pushes changes from service back to origin service' do
    assembly_updated = dtk_common.push_assembly_updates(dtk_common.service_id, service_module)
    expect(assembly_updated).to eq(true)
  end
end

shared_context 'Push component module updates without changes' do |dtk_common, component_module, assembly_name|
  it 'retrieves message that no changes have been made' do
    response = dtk_common.push_component_module_updates_without_changes(dtk_common.service_id, component_module)
    expect(response['errors'].first['message']).to eq("Changes to component module (#{component_module.split(':').last}) have not been made in service instance '#{assembly_name}'")
  end
end

shared_context 'List nodes' do |dtk_common, nodes_list|
  it "gives list of all nodes on the service and matches them with given #{nodes_list} input" do
    nodes_exist = true
    nodes_retrieved = dtk_common.get_nodes(dtk_common.service_id)
    nodes_list.each do |n|
      unless nodes_retrieved.include? n
        nodes_exist = false
        break
      end
    end
    expect(nodes_exist).to eq(true)
  end
end

shared_context 'List components' do |dtk_common, components_list|
  it "gives list of all components on the service and matches them with given #{components_list} input" do
    components_exist = true
    components_retrieved = dtk_common.get_components(dtk_common.service_id)
    components_list.each do |c|
      unless components_retrieved.include? c
        components_exist = false
        break
      end
    end
    expect(components_exist).to eq(true)
  end
end

shared_context 'Delete node' do |dtk_common, node_name|
  it "deletes #{node_name} node" do
    node_deleted = dtk_common.delete_node(dtk_common.service_id, node_name)
    expect(node_deleted).to eq(true)
  end
end

shared_context 'Get cardinality' do |dtk_common, node_name, cardinality_expected|
  it "gets cardinality and verifies it is equal to provided cardinality: #{cardinality_expected}" do
    cardinality = dtk_common.get_cardinality(dtk_common.service_id, node_name)
    expect(cardinality).to eq(cardinality_expected)
  end
end

shared_context 'Grant access after converge' do |dtk_common, system_user, rsa_pub_name|
  it 'grants access to nodes' do
    access_granted = false
    response = dtk_common.grant_access(dtk_common.service_id, system_user, rsa_pub_name, dtk_common.ssh_key)
    if response['status'] == 'ok'
      access_granted = true
    end
    expect(access_granted).to eq(true)
  end
end

shared_context 'NEG - Grant access before converge' do |dtk_common, system_user, rsa_pub_name|
  it 'does not grant access because nodes are staged' do
    access_granted = true
    response = dtk_common.grant_access(dtk_common.service_id, system_user, rsa_pub_name, dtk_common.ssh_key)
    if response['status'] == 'notok'
      access_granted = false
    end
    expect(access_granted).to eq(false)
  end
end

shared_context 'Revoke access after converge' do |dtk_common, system_user, rsa_pub_name|
  it 'revokes access to nodes' do
    access_revoked = false
    response = dtk_common.revoke_access(dtk_common.service_id, system_user, rsa_pub_name, dtk_common.ssh_key)
    if response['status'] == 'ok'
      access_revoked = true
    end
    expect(access_revoked).to eq(true)
  end
end

shared_context 'NEG - Revoke access before converge' do |dtk_common, system_user, rsa_pub_name|
  it 'does not revoke access because nodes are staged' do
    access_revoked = true
    response = dtk_common.revoke_access(dtk_common.service_id, system_user, rsa_pub_name, dtk_common.ssh_key)
    if response['status'] == 'notok'
      access_revoked = false
    end
    expect(access_revoked).to eq(false)
  end
end

shared_context 'List ssh access and confirm is empty' do |dtk_common, system_user, rsa_pub_name, nodes|
  it 'returns empty list for ssh access' do
    ssh_list = dtk_common.list_ssh_access(dtk_common.service_id, system_user, rsa_pub_name, nodes)
    expect(ssh_list).to be_empty
  end
end

shared_context 'List ssh access' do |dtk_common, system_user, rsa_pub_name, nodes|
  it 'returns list for ssh access' do
    ssh_list = dtk_common.list_ssh_access(dtk_common.service_id, system_user, rsa_pub_name, nodes)
    expect(ssh_list).to include(rsa_pub_name)
  end
end

shared_context 'Get task action details' do |dtk_common, action_id, expected_output|
  it 'returns task action output and verifies it' do
    correct_task_action_outputs = false
    task_action_outputs = dtk_common.get_task_action_output(dtk_common.service_id, action_id)
    expected_output.each_with_index do |output, idx|
      if (((task_action_outputs[idx].include? "RUN: #{output[:command]}") || (task_action_outputs[idx].include? "ADD: #{output[:command]}")) && ((task_action_outputs[idx].include? "STATUS: #{output[:status]}") || (output[:status].nil?)))
        puts 'Returned expected task action details!'
        if ((output[:stderr].nil?) && (!task_action_outputs[idx].include? 'STDERR'))
          correct_task_action_outputs = true
        elsif task_action_outputs[idx].include? "STDERR: #{output[:stderr]}"
          correct_task_action_outputs = true
        else
          puts 'Returned stderr was not matched with expected one!'
          correct_task_action_outputs = false
        end
        break
      else
        puts 'Returned task action details is not the expected one!'
        correct_task_action_outputs = false
        break
      end
    end
    expect(correct_task_action_outputs).to eq(true)
  end
end

shared_context 'Delete service with workflow' do |dtk_common, components_to_delete, check_component_in_task_status|
  it "deletes service and checks that task status output is valid" do
    delete_successful = dtk_common.delete_service_with_workflow(dtk_common.service_id, components_to_delete, check_component_in_task_status)
    expect(delete_successful).to eq(true)
  end
end

shared_context 'Delete node with workflow' do |dtk_common, node_name, components_to_delete, check_component_in_task_status|
  it "deletes node and checks that task status output is valid" do
    delete_successful = dtk_common.delete_node_with_workflow(dtk_common.service_id, node_name, components_to_delete, check_component_in_task_status)
    expect(delete_successful).to eq(true)
  end
end

shared_context 'Delete component with workflow' do |dtk_common, node_name, components_to_delete, check_component_in_task_status|
  it "deletes component and checks that task status output is valid" do
    delete_successful = dtk_common.delete_component_with_workflow(dtk_common.service_id, node_name, components_to_delete, check_component_in_task_status)
    expect(delete_successful).to eq(true)
  end
end

shared_context 'Check that service instance nodes have been terminated on aws' do |dtk_common, service_instance_name|
  it "verifies that service instances nodes have been terminated already" do
    nodes_terminated = dtk_common.verify_service_instance_nodes_terminated(service_instance_name)
    expect(nodes_terminated).to eq(true)
  end
end
