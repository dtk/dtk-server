#Usergroup Test Case 1: Simple create, update and delete usergroup scenario"
require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'
require './lib/admin_panel_helper'
require './lib/mixins/admin_panel_mixins'

group = UserGroup.new('demo_group1','Demo Group.') 
edited_group = UserGroup.new('edited_user_group1','Edit.')



describe "(Admin Panel UI) Usergroup Test Case 1: Simple create, update and delete usergroup scenario" do
  let(:conf) { Configuration.instance }
  let(:header) { @homepage.get_header }
  let(:groups_panel) { @homepage.get_main.get_usergroups }
 

  context "User is" do
	  it "logged in" do
      @homepage.get_loginpage.login_user(conf.username, conf.password)
	    homepage_header = header.get_homepage_header
	    expect(homepage_header).to have_content('DTK')
    end
  end

  context "Open the creation page" do
  	it "creation page opened" do
  		groups_panel.open_create_page
  	end
  end

  context "Create Usergroup #{group.name} with description #{group.desc}" do
  	it "usergroup created" do
  		groups_panel.enter_data(group.get_data)
      groups_panel.press_create_button
  	end
  end

  context "Search for Usergroup #{group.name}" do
  	it "usergroup found" do
      groups_panel.search_for_object(group.name)
  		expect(groups_panel.object_exists?(group.name)).to eql(true)
  	end
  end

  context "Edit Usergroup #{group.name} to #{edited_group.name}" do
  	it "usergroup edited" do
      groups_panel.open_edit_page(group.name)
      groups_panel.enter_data(edited_group.get_data)
      groups_panel.press_edit_button
  	end
  end

  context "Search for Usergroup #{group.name}" do
  	it "usergroup not found" do
  		groups_panel.search_for_object(group.name)
  		expect(groups_panel.object_exists?(group.name)).to eql(false)
  	end
  end

  context "Search for Usergroup #{edited_group.name}" do
    it "usergroup found" do
      groups_panel.search_for_object(edited_group.name)
      expect(groups_panel.object_exists?(edited_group.name)).to eql(true)
    end
  end

  context "Delete Usergroup #{edited_group.name}" do
    it "group deleted"  do
      groups_panel.press_delete_link(edited_group.name)
    end
  end

  context "Search for Usergroup #{edited_group.name}" do
    it "usergroup not found" do
      groups_panel.search_for_object(edited_group.name)
      expect(groups_panel.object_exists?(edited_group.name)).to eql(false)
    end
  end
end