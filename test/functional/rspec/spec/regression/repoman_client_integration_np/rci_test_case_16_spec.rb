# Test Case 16: delete-from-catalog positive scenarios where it is possible to delete component module from remote based on permissions set on the module
require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'

user_data = {
  usergroup: 'bakir_test_group',
  user: '',
  module_name: 'dtk17/bakir_test_module',
  component_module: 'bakir_test_module',
  namespace: 'dtk17',
  component_module_filesystem_location: '~/dtk/component_modules/dtk17',
  another_usergroup: 'bakir_test',
  another_user: 'bakir_test'
}

permissions = {
  user_r: false,
  user_w: false,
  user_d: true,
  user_p: false,
  user_group_r: false,
  user_group_w: false,
  user_group_d: true,
  user_group_p: false,
  other_r: false,
  other_w: false,
  other_d: true,
  other_p: false
}

reverted_permissions = {
  user_r: true,
  user_w: true,
  user_d: true,
  user_p: true,
  user_group_r: true,
  user_group_w: true,
  user_group_d: true,
  user_group_p: true,
  other_r: true,
  other_w: true,
  other_d: true,
  other_p: true
}

dtk_common = Common.new('', '')

describe '(Repoman client integration) Test Case 16: delete-from-catalog positive scenarios where it is possible to delete component module from remote based on permissions set on the module' do
  let(:conf) { Configuration.instance }
  let(:header) { @homepage.get_header }
  let(:users) { @homepage.get_main.get_users }
  let(:modules) { @homepage.get_main.get_modules }

  context 'Import component module function' do
    include_context 'Import remote component module', user_data[:module_name]
  end

  context 'User is' do
    it 'logged in' do
      @homepage.get_loginpage.login_user(conf.username, conf.password)
      homepage_header = header.get_homepage_header
      expect(homepage_header).to have_content('DTK')
    end
  end

  context "Usergroup #{user_data[:usergroup]}" do
    it "is set for user" do
      header.click_on_users
      user_data[:user] = conf.repoman_user
      users.click_on_edit_user(user_data[:user])
      users.assign_user_group_for_user(user_data[:usergroup])
      users.save_edit_changes
    end
  end

  #User A is owner of module A and belongs to user group A which is set as user group on module (permissions: D/D/D)
  context "Usergroup #{user_data[:usergroup]}, user #{user_data[:user]} and D/D/D permissions" do
    it "are set on module #{user_data[:module_name]}" do
      header.click_on_modules
      modules.click_on_edit_module(user_data[:module_name])
      modules.set_module_owner_user(user_data[:user])
      modules.set_module_owner_group(user_data[:usergroup])
      modules.set_module_permissions(permissions)
      modules.save_edit_changes
      sleep 5 #To have enough time to save changes
    end
  end

  context 'Delete remote module' do
    include_context 'Delete component module from remote', dtk_common, user_data[:component_module], user_data[:namespace]
  end

  context 'Publish component module' do
    include_context 'Export component module', dtk_common, user_data[:namespace] + ':' + user_data[:component_module], user_data[:namespace]
  end

  #User A is not owner of module A but belongs to user group A which is set as user group on module (permissions: None/D/None)
  context "Usergroup #{user_data[:usergroup]}, user #{user_data[:another_user]} and None/D/None permissions" do
    it "are set on module #{user_data[:module_name]}" do
      permissions[:user_d] = false
      permissions[:other_d] = false

      header.click_on_modules
      modules.click_on_edit_module(user_data[:module_name])
      modules.set_module_owner_user(user_data[:another_user])
      modules.set_module_owner_group(user_data[:usergroup])
      modules.set_module_permissions(permissions)
      modules.save_edit_changes
      sleep 5 #To have enough time to save changes
    end
  end

  context 'Delete remote module' do
    include_context 'Delete component module from remote', dtk_common, user_data[:component_module], user_data[:namespace]
  end

  context 'Publish component module' do
    include_context 'Export component module', dtk_common, user_data[:namespace] + ':' + user_data[:component_module], user_data[:namespace]
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, user_data[:namespace] + ':' + user_data[:component_module]
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', user_data[:component_module_filesystem_location], user_data[:component_module]
  end

  context "Usergroup #{user_data[:usergroup]}, user #{user_data[:user]} and RWDP/RWDP/RWDP permissions" do
    it "are reverted back on module #{user_data[:module_name]}" do
      header.click_on_modules
      modules.click_on_edit_module(user_data[:module_name])
      modules.set_module_owner_user(user_data[:user])
      modules.set_module_owner_group(user_data[:usergroup])
      modules.set_module_permissions(reverted_permissions)
      modules.save_edit_changes
    end
  end

  context 'User is' do
    it 'logged out' do
      startpage = @homepage.get_loginpage.logout_user
      expect(startpage).to have_content('DTK Admin Panel')
    end
  end
end
