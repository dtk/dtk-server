#User Test Case 5: NEG - Create user with invalid values"
require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'
require './lib/admin_panel_helper'


num="5"
group=UserGroup.new('demo_group1'+num, 'Demo Group. ')

user=User.new('demo_user1'+num,'password','Demo','User','demo_user'+num+'@mail.com','3','demo_group1'+num)
invalid_user=User.new('>.<'+num,'>>>>>>','>.<','>.<','@mail.com','-1','demo_group1'+num)
empty_user=User.new('', '', '', '', '', '', 'demo_group1'+num)



describe "(Admin Panel UI) User Test Case 5: NEG - Create user with invalid values" do
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

    context "Create user #{user.username}" do
    	it "created user" do
    		header.click_on_users
    		user.create_object(user_panel)
    	end
    end

    context "Open User create page" do
    	it "opened page" do
    		user_panel.open_create_page
    	end
    end

    context "Create User with name field left empty" do
        it "will not create usergroup" do
        	user_panel.enter_data(empty_user.get_data)
            user_panel.press_create_button
            expect(user_panel.on_create_page?).to eql(true)
        end
    end

    context "Create User with invalid_user values" do
    	it "will not create the user" do
    		user_panel.enter_data(invalid_user.get_data)
    		user_panel.press_create_button
    		expect(user_panel.on_create_page?).to eql(true)
    	end
    end

    context "Create User with too long value in fields" do
    	it "will not create the user" do
    		long_value=invalid_user.get_too_long_name+num
    		user_panel.enter_user_data(long_value, long_value, long_value, long_value, long_value, long_value, 'demo_group1'+num)
    		user_panel.press_create_button
    		expect(user_panel.on_create_page?).to eql(true)
    	end
    end

    context "Create User with taken username #{user.username}" do
    	it "will not create the user" do
    		user_panel.enter_data(user.get_data)
    		user_panel.press_create_button
    		expect(user_panel.on_create_page?).to eql(true)
    	end
    end

    context "Delete user #{user.username}" do
    	it "deleted the user" do
    		header.click_on_users
    		expect(user.delete_object(user_panel)).to eql(true)
    	end
    end 

    context "Delete usergroup #{group.name}" do
    	it "deleted the usergroup" do
    		header.click_on_user_groups
    		expect(group.delete_object(group_panel)).to eql(true)
    	end
    end
end