# Test Case 7: Make public module A (User A is not owner but belongs to User group A which is set on module, permissions: RWD/RWDP/None)

require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'

component_module = 'r8:java'
user_data = {
  usergroup: 'bakir_test_group',
  user: '',
  another_user: 'bakir_test',
  module_name: 'r8/java'
}

permissions = {
  user_r: true,
  user_w: true,
  user_d: true,
  user_p: false,
  user_group_r: true,
  user_group_w: true,
  user_group_d: true,
  user_group_p: true,
  other_r: false,
  other_w: false,
  other_d: false,
  other_p: false
}

dtk_common = Common.new('', '')

describe '(Repoman client integration) Test Case 7: Make public module A (User A is not owner but belongs to User group A which is set on module, permissions: RWD/RWDP/None)' do
  let(:conf) { Configuration.instance }
  let(:header) { @homepage.get_header }
  let(:users) { @homepage.get_main.get_users }
  let(:modules) { @homepage.get_main.get_modules }

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
      users.search_for_object(user_data[:user])
      users.click_on_edit_user(user_data[:user])
      users.assign_user_group_for_user(user_data[:usergroup])
      users.save_edit_changes
    end
  end

  context "Usergroup #{user_data[:usergroup]}, user #{user_data[:another_user]} and RWD/RWDP/None permissions" do
    it "are set on module #{user_data[:module_name]}" do
      header.click_on_modules
      modules.click_on_edit_module(user_data[:module_name])
      modules.set_module_owner_user(user_data[:another_user])
      modules.set_module_owner_group(user_data[:usergroup])
      modules.set_module_permissions(permissions)
      modules.save_edit_changes
      sleep 5 #To have enough time to save changes
    end
  end

  context 'Make public component module' do
    include_context 'Make public component module', dtk_common, component_module
  end

  context "Usergroup #{user_data[:usergroup]}, user #{user_data[:user]} and RWD/RWDP/R permissions" do
    include_context 'Check module permissions', dtk_common, user_data[:module_name], 'RWD/RWDP/R'
  end

  context 'User is' do
    it 'logged out' do
      startpage = @homepage.get_loginpage.logout_user
      expect(startpage).to have_content('DTK Admin Panel')
    end
  end
end
