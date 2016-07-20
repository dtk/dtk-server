require './lib/dtk_cli_spec'
require './lib/dtk_common'

dtk_cli_path = '/home/vagrant/r8/dtk-cli'
module_name = 'rich:simple'
assembly_name = 'simple'

dtk_common = Common.new('', '')

describe "(DTK CLI) Test Case 1: Install module with new dtk cli" do
  before(:all) do
    puts '******************************************************', ''
  end

  context "Install module" do
    include_context "Install module", module_name, dtk_cli_path
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", module_name, assembly_name, dtk_common
  end

  context "Push module" do
    include_context "Push module", module_name, dtk_cli_path
  end

  context "Delete module" do
    include_context "Delete module", module_name, dtk_cli_path
  end

  after(:all) do
    puts '', ''
  end
end
