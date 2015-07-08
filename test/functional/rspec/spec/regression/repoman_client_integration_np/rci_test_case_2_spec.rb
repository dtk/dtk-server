# Test Case 2: Make private module A (User A is not owner but belongs to User group A which is set on module, permissions: RWD/RWDP/RWD)

require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'

component_module = "r8:java"
user_data = {
  usergroup: "bakir_test_group",
  user: "dtk17-client",
  module_name: "r8/java",
  another_user: "bakir_test"
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
  other_r: true,
  other_w: true,
  other_d: true,
  other_p: false
}

dtk_common = DtkCommon.new('', '')

describe "(Repoman client integration) Test Case 2: Make private module A (User A is not owner but belongs to User group A which is set on module, permissions: RWD/RWDP/RWD)" do
  let(:conf) { Configuration.instance }
  let(:header) { @homepage.get_header }
  let(:users) { @homepage.get_main.get_users }
  let(:modules) { @homepage.get_main.get_modules}

  context "User is" do
    it "logged in" do
      @homepage.get_loginpage.login_user(conf.username, conf.password)
      homepage_header = header.get_homepage_header
      expect(homepage_header).to have_content('DTK')
    end
  end

  context "Usergroup #{user_data[:usergroup]}" do
    it "is set for user #{user_data[:user]}" do
      header.click_on_users
      users.click_on_edit_user(user_data[:user])
      users.assign_user_group_for_user(user_data[:usergroup])
      users.save_edit_changes
    end
  end

  context "Usergroup #{user_data[:usergroup]}, user #{user_data[:another_user]} and RWD/RWDP/RWD permissions" do
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

  context "Make private component module" do
    include_context "Make private component module", dtk_common, component_module
  end

  context "Usergroup #{user_data[:usergroup]}, user #{user_data[:user]} and RWD/RWDP/None permissions" do
    include_context "Check module permissions", dtk_common, user_data[:module_name], "RWD/RWDP/"
  end

  context "User is" do
    it "logged out" do
      startpage = @homepage.get_loginpage.logout_user
      expect(startpage).to have_content('DTK Admin Panel')
    end
  end
end
