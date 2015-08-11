# Test Case 19: add/remove collaborators by users and useremails (User A is owner and belongs to User group A which is set on module, intial permissions are: P/None/None)

require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'

user_data = {
  usergroup: 'bakir_test_group',
  user: '',
  module_name: 'r8/java'
}

component_module = 'r8:java'
user_names = 'bakir_test'
user_emails = 'bakir@atlantbh.com'
collaborator_type = 'users'

permissions = {
  user_r: false,
  user_w: false,
  user_d: false,
  user_p: true,
  user_group_r: false,
  user_group_w: false,
  user_group_d: false,
  user_group_p: false,
  other_r: false,
  other_w: false,
  other_d: false,
  other_p: false
}

dtk_common = Common.new('', '')

describe '(Repoman client integration) Test Case 19: add/remove collaborators by users and useremails (User A is owner and belongs to User group A which is set on module, intial permissions are: P/None/None)' do
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
      users.click_on_edit_user(user_data[:user])
      users.assign_user_group_for_user(user_data[:usergroup])
      users.save_edit_changes
    end
  end

  context "Usergroup #{user_data[:usergroup]}, user #{user_data[:user]} and P/None/None permissions" do
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

  context 'Add collaborators (user names) on module' do
    include_context 'Add collaborators on module', dtk_common, component_module, user_names, collaborator_type
  end

  context 'Check collaborators (user names) on module' do
    include_context 'Check collaborators on module', dtk_common, component_module, user_names.split(','), 'User', :name
  end

  context 'Remove collaborators (user names) from module' do
    include_context 'Remove collaborators from module', dtk_common, component_module, user_names, collaborator_type
  end

  context 'NEG - Check collaborators (user names) on module' do
    include_context 'NEG - Check collaborators on module', dtk_common, component_module, user_names.split(','), 'User', :name
  end

  context 'Add collaborators (user emails) on module' do
    include_context 'Add collaborators on module', dtk_common, component_module, user_emails, collaborator_type
  end

  context 'Check collaborators (user emails) on module' do
    include_context 'Check collaborators on module', dtk_common, component_module, user_emails.split(','), 'User', :email
  end

  context 'Remove collaborators (user emails) from module' do
    include_context 'Remove collaborators from module', dtk_common, component_module, user_emails, collaborator_type
  end

  context 'NEG - Check collaborators (user emails) on module' do
    include_context 'NEG - Check collaborators on module', dtk_common, component_module, user_emails.split(','), 'User', :email
  end

  context 'User is' do
    it 'logged out' do
      startpage = @homepage.get_loginpage.logout_user
      expect(startpage).to have_content('DTK Admin Panel')
    end
  end
end
