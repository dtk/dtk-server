# Test Case 01: Login with new user that has DTK and catalog credentials
require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'
require './spec/setup_browser'
require './lib/admin_panel_helper'

component_module = "temp"
namespace = "dtk17"
component_module_name = "dtk17:temp"
component_module_filesystem_location = '~/dtk/component_modules/dtk17'
dtk_common = Common.new("", "")
num = '01'
catalog_user = "dtk_login_"+num
catalog_password = 'password'
group = UserGroup.new('dtk_login_group_'+num, 'DTK login group')
user = User.new(catalog_user,catalog_password,'DTK','Login','dtk_login_'+num+'@mail.com','3','dtk_login_group_'+num)

describe "Test Case 01: Login with new user that has DTK and catalog credentials" do
  let(:conf) { Configuration.instance }
  let(:header) { @homepage.get_header }
  let(:group_panel) { @homepage.get_main.get_usergroups }
  let(:user_panel) { @homepage.get_main.get_users}

  context "User is" do
    it "logged in" do
      @homepage.get_loginpage.login_user(conf.username, conf.password)
      homepage_header = header.get_homepage_header
      expect(homepage_header).to have_content('DTK')
    end
  end

  context "Create usergroup #{group.name}" do
    it "created usergroup" do
      group.create_object(group_panel)
    end
  end

  context "Open User panel" do
    it "opened panel" do
      header.click_on_users
    end
  end

	context "Create user #{user.username}" do
    it "created user" do
    	user.create_object(user_panel)
      expect(user_panel.on_create_page?).to eql(false)
    end
  end

  context "Add ssh key" do
    include_context 'Add direct access', dtk_common, dtk_common.username + "-client"
	end
	
	context "Initial DTK login" do
		it "verifies successfull DTK login" do
      cookies = dtk_common.get_login_cookies
      expect(cookies["dtk-user-info"].length).to be > 10
      expect(cookies["innate.sid"].length).to be > 10
		end
	end

	context "Set catalog credentials" do
    include_context "Set catalog credentials", dtk_common, catalog_user, catalog_password
  end

	context "List remote to check connectivity with repoman" do
    include_context "List remote modules", dtk_common, "#{namespace}/#{component_module}"
	end

	context "Install component module" do
    include_context "Import remote component module", component_module_name
	end

	context 'Get component module components list' do
    include_context 'Get component module components list', dtk_common, component_module_name
  end

	context 'Delete component module' do
    include_context 'Delete component module', dtk_common, component_module_name
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', component_module_filesystem_location, component_module
  end

	context "Delete ssh key from tenant" do
    include_context 'Remove direct access', dtk_common, dtk_common.username + "-client"
	end

  context "Open User panel" do
    it "opened panel" do
    	header.click_on_users
    end
  end

  context "Delete user #{user.username}" do
    it "deleted user" do
      user.delete_object(user_panel)
    end
  end

  context "Open Usergroup panel" do
    it "opened panel" do
    	header.click_on_user_groups
    end
  end

  context "Delete usergroup #{group.name}" do
    it "deleted the usergroup" do
    	expect(group.delete_object(group_panel)).to eql(true)
    end
  end
end