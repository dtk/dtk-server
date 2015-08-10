#User Test Case 4: Simple create, update and delete user scenario"

require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'
require './lib/admin_panel_helper'


first_group=UserGroup.new('demo_group1', 'Demo Group 1.')
second_group=UserGroup.new('demo_group2', 'Demo Group 2.')

user=User.new('demo_user','password','Demo','User','demo_user@mail.com','3','demo_group1')
edited_user=User.new('demo_user','edit_password', 'Mode','Reus','edit_user@gmail.com','5','demo_group2')



describe "(Admin Panel UI) User Test Case 4: Simple create, update and delete user scenario" do
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

  	context "Create usergroup #{first_group.name}" do
        it "created usergroup" do
            first_group.create_object(group_panel)
        end
    end

    context "Create usergroup #{second_group.name}" do
        it "created usergroup" do
            second_group.create_object(group_panel)
        end
    end

    context "Open user_panel panel" do
    	it "opened user panel" do
    		header.click_on_users
    	end
    end

    context "Open creation page" do
    	it "opened creation page" do
    		user_panel.open_create_page
    	end
    end

    context "Enter User data to textfields and create user" do
    	it "created the data" do
    		user_panel.enter_data(user.get_data)
    		user_panel.press_create_button
    		expect(user_panel.on_create_page?).to eql(false)
    	end
    end

    context "Search for User #{user.username}" do
    	it "found the user" do
    		user_panel.search_for_object(user.username)
    		expect(user_panel.object_exists?(user.username)).to eql(true)
    	end
    end

    context "Open edit page for User #{user.username}" do
    	it "opened the edit page" do
    		user_panel.open_edit_page(user.username)
    	end
    end

    context "Enter Edited user data to textfields and edit user" do
    	it "edited the user" do
    		user_panel.uncheck_usergroup(user.group)
    		user_panel.enter_data(edited_user.get_data,true)
    		user_panel.press_edit_button
    		expect(user_panel.on_edit_page?).to eql(false)
    	end
    end


    context "Search for User #{edited_user.username}" do
    	it "found the user" do
    		user_panel.search_for_object(edited_user.username)
    		expect(user_panel.object_exists?(edited_user.username)).to eql(true)
    	end
    end

    context "Verify that User #{edited_user.username} was edited" do
    	it "verified user update" do
    		info=user_panel.get_user_table_info(edited_user.username)
    		expect(info[:ns]).to eql(edited_user.ns)
    	end
    end

    context "Delete User #{edited_user.username}" do
    	it "deleted the user" do
    		user_panel.press_delete_link(edited_user.username)
    	end
    end

    context "Search for User #{edited_user.username}" do
    	it "will not find the user" do
    		user_panel.search_for_object(user.username)
    		expect(user_panel.object_exists?(user.username)).to eql(false)
    	end
    end

    context "Open User group panel" do
    	it "opened user group panel" do
    		header.click_on_user_groups
    	end
    end

    context "Search for Usergroup #{first_group.name} and delete it" do
    	it "deleted the usergroup" do
      		expect(first_group.delete_object(group_panel)).to eql(true)
    	end
  	end

  	context "Search for Usergroup #{second_group.name} and delete it" do
    	it "deleted the usergroup" do
      		expect(second_group.delete_object(group_panel)).to eql(true)
   	 	end
   	end
end

