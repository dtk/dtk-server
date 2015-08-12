#Namespace Test Case 9: NEG - Namespace edit textfield validation

require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'
require './lib/admin_panel_helper'

num='9'
group=UserGroup.new('demo_group'+num, 'Demo Group.'+num)

user=User.new('demo_user1'+num,'password','Demo','User','demo_user1'+num+   '@mail.com','3','demo_group'+num)
ns_max_user=User.new('demo_user2'+num,'password','Demo','User','demo_user2'+num+'@mail.com','1','demo_group'+num)

first_ns=Namespace.new('demo_ns1'+num,'demo_user1'+num,'demo_group'+num,'RW','RW','RW')
second_ns=Namespace.new('demo_ns2'+num,'demo_user1'+num,'demo_group'+num,'RW','RW','RW')

invalid_owner_ns=Namespace.new('demo_ns1'+num,'demo_user2'+num,'demo_group'+num,'RW','RW','RW')

empty_ns=Namespace.new('','','','','','')
invalid_ns=Namespace.new('~!#$%æ«'+num,'demo_user1'+num,'demo_group'+num,'','','')


describe "(Admin Panel UI) Test Case 9: NEG - Namespace edit textfield validation" do
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

    context "Create Namespace #{first_ns.name}" do
    	it "created namespace" do
    		first_ns.create_object(ns_panel)
    	end
    end

    context "Create Namespace #{second_ns.name}" do
    	it "created namespace" do
    		second_ns.create_object(ns_panel)
    	end
    end

    context "Open Edit page for Namespace #{first_ns.name}" do
    	it "opened edit page" do
    	 	ns_panel.search_for_object(first_ns.name)
    	 	ns_panel.open_edit_page(first_ns.name)
    	end
    end

    context "Deselect user, group and permissions" do
    	it "deselected properties" do
    		ns_panel.deselect_properties(first_ns.group)
    	end
    end

    context "Edit page with unselected user, group and permission" do
    	it "will not edit usergroup" do
    		ns_panel.press_edit_button
    		expect(ns_panel.on_edit_page?).to eql(true)
    	end
    end

    context "Edit namespace with owner that has reached namespace limit" do
    	it "will not edit namespace" do
    		ns_panel.select_user(ns_max_user.username, ns_panel.select_box_selector)
    		ns_panel.check_usergroup(ns_max_user.group)
    		ns_panel.press_edit_button
    		expect(ns_panel.on_edit_page?).to eql(true)
    	end
    end

    context "Open Namespace panel" do
    	it "opened panel" do
    		header.click_on_namespaces
    	end
    end

    context "Delete Namespace #{first_ns.name}" do
    	it "deleted namespace" do
    		first_ns.delete_object(ns_panel)
    	end
    end

     context "Delete Namespace #{second_ns.name}" do
    	it "deleted namespace" do
    		second_ns.delete_object(ns_panel)
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
