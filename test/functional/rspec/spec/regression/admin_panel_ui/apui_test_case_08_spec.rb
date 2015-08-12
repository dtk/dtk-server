#User Test Case 5: NEG - Create namespace with invalid values"


require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'
require './lib/admin_panel_helper'

num="8"
group=UserGroup.new('demo_group'+num, 'Demo Group. '+num)
user=User.new('demo_user1'+num,'password','Demo','User','demo_user1'+num+'@mail.com','3','demo_group'+num)
ns_max_user=User.new('demo_user2'+num,'password','Demo','User','demo_user2'+num+'@mail.com','1','demo_group'+num)

namespace=Namespace.new('demo_ns1'+num,'demo_user1'+num,'demo_group'+num,'RW','RW','RW')
invalid_owner_ns=Namespace.new('demo_ns1'+num,'demo_user2'+num,'demo_group'+num,'RW','RW','RW')

empty_ns=Namespace.new('','','','','','')
invalid_ns=Namespace.new('!@#$%'+num,'demo_user1'+num,'demo_group'+num,'','','')


describe "(Admin Panel UI) User Test Case 8: NEG - Create namespace with invalid values" do
	let(:conf) { Configuration.instance }
  	let(:header) { @homepage.get_header }
  	let(:group_panel) { @homepage.get_main.get_usergroups }
  	let(:user_panel) { @homepage.get_main.get_users}
  	let(:ns_panel) { @homepage.get_main.get_namespaces }

  	context "User is" do
		it "logged in" do
      		@homepage.get_loginpage.login_user(conf.username, conf.password)
	    	homepage_header = header.get_homepage_header
	    	expect(homepage_header).to have_content('DTK')
    	end
  	end

  	context "Create Usergroup #{group.name}" do
        it "created usergroup" do
            group.create_object(group_panel)
        end
    end

    context "Open Users panel" do
    	it "opened panel" do
    		header.click_on_users
    	end
    end

    context "Create User #{user.username}" do
    	it "created user" do
    		user.create_object(user_panel)
    	end
    end

    context "Create User #{ns_max_user.username}" do
    	it "created uesr" do
    		ns_max_user.create_object(user_panel)
    	end
    end

    context "Open Namespace panel" do
    	it "opened panel" do
    		header.click_on_namespaces
    	end
    end

    context "Create Namespace #{namespace.name}" do
    	it "created namespace" do
    		namespace.create_object(ns_panel)
    	end
    end

    context "Open Namespace create page" do
    	it "opened create page" do
    		ns_panel.open_create_page
    	end
    end
=begin
    context "Create namespace with empty fields" do
    	it "will not create namespace" do
    		#ns_panel.enter_data(empty_ns.get_data)
    		ns_panel.press_create_button
            #sleep 30 if Capybara.current_driver == :webkit || Capybara.current_driver == :poltergeist #slower empty field validaiton in headless mode 
    		expect(ns_panel.on_create_page?).to eql(true)
    	end
    end 
=end
    context "Create namespace with taken name" do
    	it "will not create namespace" do
    		ns_panel.enter_data(namespace.get_data)
    		ns_panel.press_create_button
    		expect(ns_panel.on_create_page?).to eql(true)
    	end
    end 

    context "Create namespace with invalid values" do
    	it "will not create namespace" do
    		ns_panel.enter_data(invalid_ns.get_data)
    		ns_panel.press_create_button
    		expect(ns_panel.on_create_page?).to eql(true)
    	end
    end

    context "Create namespace with too long name" do
    	it "will not create namespace" do
    		long_ns=Namespace.new(invalid_ns.get_too_long_name+num, 'demo_user1'+num, 'demo_group'+num,'','','')
    		ns_panel.enter_data(long_ns.get_data)
    		ns_panel.press_create_button
    		expect(ns_panel.on_create_page?).to eql(true)
    	end
    end

    context "Create namespace with owner that has reached namespace limit" do
    	it "will not create namespace" do
    		ns_panel.enter_data(invalid_owner_ns.get_data)
    		ns_panel.press_create_button
    		expect(ns_panel.on_create_page?).to eql(true)
    	end
    end

    context "Open Namespace panel" do
    	it "opened panel" do
    		header.click_on_namespaces
    	end
    end

    context "Delete Namespace #{namespace.name}" do
    	it "deleted namespace" do
    		namespace.delete_object(ns_panel)
    	end
    end

    context "Open Usergroups panel" do
    	it "opened panel" do
    		header.click_on_user_groups
    	end
    end

    context "Delete Usergroup #{group.name}" do
    	it "deleted group" do
    		group.delete_object(group_panel)
    	end
    end

    context "Open Users panel" do
    	it "opened panel" do
    		header.click_on_users
    	end
    end


    context "Delete User #{user.username}" do
    	it "deleted user" do
    		user.delete_object(user_panel)
    	end
    end

    context "Delete User #{ns_max_user.username}" do
    	it "deleted user" do
    		ns_max_user.delete_object(user_panel)
    	end
    end
end