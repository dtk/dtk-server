#Usergroup Test Case 1: Simple create, update and delete usergroup scenario"
require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'

data={
	usergroup: 'demo_group',
	desc: 'Demo Group.',
	edit_usergroup: 'edited_user_group',
	edit_desc: 'Edit.'
}

describe "(Admin Panel UI) Usergroup Test Case 1: Simple create, update and delete usergroup scenario" do
  let(:conf) { Configuration.instance }
  let(:header) { @homepage.get_header }
  let(:usergroups) { @homepage.get_main.get_usergroups }

  context "User is" do
	  it "logged in" do
      @homepage.get_loginpage.login_user(conf.username, conf.password)
	    homepage_header = header.get_homepage_header
	    expect(homepage_header).to have_content('DTK')
    end
  end

  context "Open the creation page" do
  	it "creation page opened" do
  		usergroups.open_usergroup_create_page
  	end
  end

  context "Create Usergroup #{data[:usergroup]} with description #{data[:desc]}" do
  	it "usergroup created" do
  		usergroups.enter_usergroup_name(data[:usergroup])
  		usergroups.enter_usergroup_desc(data[:desc])
  		usergroups.create_usergroup
  	end
  end

  context "Search for Usergroup #{data[:usergroup]}" do
  	it "usergroup found" do
  		usergroups.search_for_usergroup(data[:usergroup])
  		expect(usergroups.usergroup_exists?(data[:usergroup])).to eql(true)
  	end
  end

  context "Edit Usergroup #{data[:usergroup]} to #{data[:edit_usergroup]}" do
  	it "usergroup edited" do
  		usergroups.open_usergroup_edit_page(data[:usergroup])
  		usergroups.enter_usergroup_name(data[:edit_usergroup])
  		usergroups.enter_usergroup_desc(data[:edit_desc])
  		usergroups.edit_usergroup
  	end
  end

  context "Search for Usergroup #{data[:usergroup]}" do
  	it "usergroup not found" do
  		usergroups.search_for_usergroup(data[:usergroup])
  		expect(usergroups.usergroup_exists?(data[:usergroup])).to eql(false)
  	end
  end

  context "Search for Usergroup #{data[:edit_usergroup]}" do
    it "usergroup found" do
      usergroups.search_for_usergroup(data[:edit_usergroup])
      expect(usergroups.usergroup_exists?(data[:edit_usergroup])).to eql(true)
    end
  end

  context "Delete Usergroup #{data[:edit_usergroup]}" do
    it "group deleted"  do
      usergroups.delete_usergroup(data[:edit_usergroup])
    end
  end

  context "Search for Usergroup #{data[:edit_usergroup]}" do
    it "usergroup not found" do
      usergroups.search_for_usergroup(data[:edit_usergroup])
      expect(usergroups.usergroup_exists?(data[:edit_usergroup])).to eql(false)
    end
  end
end