#!/usr/bin/env ruby
# Test Case 31: NEG - Import Module A and Module B from git where Module B has dependency on Module A that is satisfied by name but not with version

require 'rubygems'
require 'active_record'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/services_spec'
require './lib/modules_spec'

module_name_1 = 'firewall'
git_ssh_repo_url_1 = 'git@github.com:puppetlabs/puppetlabs-firewall.git'
module_name_2 = 'postgresql'
git_ssh_repo_url_2 = 'git@github.com:puppetlabs/puppetlabs-postgresql.git'
module_filesystem_location = '~/dtk/component_modules'
$assembly_id = 0
$metadata = ''
new_module_metadata = "{:name=>\"puppetlabs-firewall\", :version=>\"0.0.2\", :source=>\"git://github.com/puppetlabs/puppetlabs-firewall.git\", :author=>\"puppetlabs\", :license=>\"ASL 2.0\", :summary=>\"Firewall Module\", :description=>\"Manages Firewalls such as iptables\", :project_page=>\"http://forge.puppetlabs.com/puppetlabs/firewall\"}"
dtk_common = DtkCommon.new('', '')

def get_metadata(module_name)
  db_config = YAML::load(File.open('./config/config.yml'))
  ActiveRecord::Base.establish_connection(db_config['dtkserverdbconnection'])
  sql1 = "select id from module.component where ref = '#{module_name}'"
  module_id = ActiveRecord::Base.connection.execute(sql1)
  sql2 = "select external_ref from module.branch where component_id = #{module_id.first['id']}"
  module_metadata = ActiveRecord::Base.connection.execute(sql2)
  module_metadata.first['external_ref']
end

def change_module_metadata(module_name, new_module_metadata)
  db_config = YAML::load(File.open('./config/config.yml'))
  ActiveRecord::Base.establish_connection(db_config['dtkserverdbconnection'])
  sql1 = "select id from module.component where ref = '#{module_name}'"
  module_id = ActiveRecord::Base.connection.execute(sql1)
  sql2 = "update module.branch set external_ref = '#{new_module_metadata}' where component_id = #{module_id.first['id']}"
  module_metadata = ActiveRecord::Base.connection.execute(sql2)
  module_metadata
end

describe '(Modules, Services and Versioning) Test Case 31: NEG - Import Module A and Module B from git where Module B has dependency on Module A that is satisfied by name but not with version' do
  before(:all) do
    puts '*************************************************************************************************************************************************************************************'
    puts '(Modules, Services and Versioning) Test Case 31: NEG - Import Module A and Module B from git where Module B has dependency on Module A that is satisfied by name but not with version'
    puts '*************************************************************************************************************************************************************************************'
    puts ''
  end

  context 'Import module from git repo' do
    include_context 'Create module from provided git repo', module_name_1, git_ssh_repo_url_1
  end

  context 'Check if module imported on local filesystem' do
    include_context 'Check module imported on local filesystem', module_filesystem_location, module_name_1
  end

  context 'ModuleFile metadata - get content from database' do
    it 'gets metadata content from database' do
      $metadata = get_metadata(module_name_1)
      expect($metadata).not_to be_nil
    end
  end

  context 'Change ModuleFile metadata - version' do
    it 'changes version from 0.4.2 to 0.0.2' do
      changed_metadata = change_module_metadata(module_name_1, new_module_metadata)
      expect(changed_metadata).not_to be_nil
    end
  end

  context 'NEG - Import module with version dependency from provided git repo' do
    include_context 'NEG - Import module with version dependency from provided git repo', module_name_2, git_ssh_repo_url_2
  end

  context 'Check if module imported on local filesystem' do
    include_context 'Check module imported on local filesystem', module_filesystem_location, module_name_2
  end

  context 'Delete module' do
    include_context 'Delete module', dtk_common, module_name_1
  end

  context 'Delete module from local filesystem' do
    include_context 'Delete module from local filesystem', module_filesystem_location, module_name_1
  end

  context 'Delete module' do
    include_context 'Delete module', dtk_common, module_name_2
  end

  context 'Delete module from local filesystem' do
    include_context 'Delete module from local filesystem', module_filesystem_location, module_name_2
  end

  after(:all) do
    puts '', ''
  end
end
