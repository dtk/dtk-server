#User Test Case 6: NEG - User edit textfield validation


require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'
require './lib/admin_panel_helper'

num='6'

first_group=UserGroup.new('demo_group1'+num, 'Demo Group. 1'+num)
second_group=UserGroup.new('demo_group2'+num, 'Demo Group. 2'+num)

user=User.new('demo_user6'+num,'password','Demo','User','demo_user1'+num+'@mail.com','3','demo_group1'+num)
existing_user=User.new('existing_user6'+num,'password','Demo','User','existing'+num+'2@mail.com','3','demo_group2'+num)
invalid_user=User.new('>.<'+num,'>>>>>>','>.<','>.<','@'+num+'6mail.com','-1','demo_group1'+num)
empty_user=User.new('', '', '', '', '', '', 'demo_group1'+num)


describe "(Admin Panel UI) User Test Case 6: NEG - User edit textfield validation" do
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

    context "Create user #{existing_user.username}" do
    	it "created user" do
    		existing_user.create_object(user_panel)
            expect(user_panel.on_create_page?).to eql(false)
    	end
    end

    context "Open Edit page for #{user.username}" do
    	it "opened edit page" do
    		user_panel.search_for_object(user.username)
    		user_panel.open_edit_page(user.username)
    	end
    end

    context "Edit User with empty_user values in textfields" do
    	it "will not update user" do
    		user_panel.enter_data(empty_user.get_data,true)
    		user_panel.press_edit_button
    		expect(user_panel.on_edit_page?).to eql(true)
    	end
    end

    context "Edit User with invalid values in textfields" do
    	it "will not update user" do 
    		user_panel.enter_data(invalid_user.get_data, true)
    		user_panel.press_edit_button
    		expect(user_panel.on_edit_page?).to eql(true)
    	end
    end

    context "Edit User with taken username" do
    	it "will not udpate user" do
    		user_panel.enter_data(existing_user.get_data,true)
    		user_panel.press_edit_button
    		expect(user_panel.on_edit_page?).to eql(true)
    	end
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

    context "Delete user #{existing_user.username}" do
    	it "deleted user" do
    		existing_user.delete_object(user_panel)
    	end
    end

    context "Open Usergroup panel" do
    	it "opened panel" do
    		header.click_on_user_groups
    	end
    end

    context "Delete usergroup #{first_group.name}" do
    	it "deleted the usergroup" do
    		expect(first_group.delete_object(group_panel)).to eql(true)
    	end
    end

    context "Delete usergroup #{second_group.name}" do
    	it "deleted the usergroup" do
    		expect(second_group.delete_object(group_panel)).to eql(true)
    	end
    end
end