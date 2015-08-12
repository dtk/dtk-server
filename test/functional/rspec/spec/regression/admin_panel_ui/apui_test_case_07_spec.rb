#Namespace Test Case 7: Simple create, update and delete namespace scenario


require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'
require './lib/admin_panel_helper'

num='7'

first_group=UserGroup.new('demo_group1'+num, 'Demo Group 1.'+num)
second_group=UserGroup.new('demo_group2'+num, 'Demo Group 2.'+num)


first_user=User.new('demo_user1'+num,'password','Demo','User','demo_user1'+num+'@mail.com','3','demo_group1'+num)
second_user=User.new('demo_user2'+num,'password','Demo','User','demo_user2'+num+'@mail.com','3','demo_group2'+num)

namespace=Namespace.new('demo_ns7','demo_user1'+num,'demo_group1'+num,'RW','RW','RW')
edited_ns=Namespace.new('demo_ns7','demo_user2'+num,'demo_group2'+num,'','','')



describe "(Admin Panel UI) Namespace Test Case 7: Simple create, update and delete namespace scenario" do
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

    context "Create user #{first_user.username}" do
    	it "created user" do
    		first_user.create_object(user_panel)
    	end
    end

    context "Create user #{second_user.username}" do
    	it "created user" do
    		second_user.create_object(user_panel)
    	end
    end

    context "Open Namespace panel" do
    	it "opened panel" do
    		header.click_on_namespaces
    	end
    end
    context "Open Namespace create page" do
    	it "opened page" do
    		ns_panel.open_create_page
    	end
    end

    context "Enter Namespace data and create namespace" do
    	it "created namespaces" do
    		ns_panel.enter_data(namespace.get_data)
    		ns_panel.press_create_button
    		expect(ns_panel.on_create_page?).to eql(false)
    	end 
    end

    context "Search for Namespace #{namespace.name}" do
    	it "found namespace" do
    		ns_panel.search_for_object(namespace.name)
    	end
    end

    context "Open edit page for Namespace #{namespace.name}" do
    	it "opened namespace" do
    		ns_panel.open_edit_page(namespace.name)
    	end
    end

    context "Deselect user, group and permissions" do
    	it "deselected properties" do
    		ns_panel.deselect_properties(namespace.group)
    	end
    end

    context "Enter Edited namespaca data and edit namespace" do
		it "edited namespace" do
			ns_panel.enter_data(edited_ns.get_data, true)
			ns_panel.press_edit_button
			expect(ns_panel.on_edit_page?).to eql(false)
		end
    end

    context "Search for Namespace #{edited_ns.name}" do
    	it "found the user" do
    		ns_panel.search_for_object(edited_ns.name)
    		expect(ns_panel.object_exists?(edited_ns.name)).to eql(true)
    	end
    end

    context "Verify that Namespace #{edited_ns.name} was edited" do
    	it "verified namespace update" do
    		info=ns_panel.get_table_row_data(edited_ns.name)
    		expect(info[:rights]).to eql("None / None / None")
    	end
    end

    context "Delete Namespace #{edited_ns.name}" do
    	it "deleted namespace" do
    		ns_panel.press_delete_link(edited_ns.name)
    	end
    end

    context "Search for Namespace #{edited_ns.name}" do
    	it "will not find namespace" do
    		ns_panel.search_for_object(edited_ns.name)
    		expect(ns_panel.object_exists?(edited_ns.name)).to eql(false)
    	end
    end

    context "Open User panel" do
    	it "opened panel" do
    		header.click_on_users
    	end
    end

    context "Delete user #{first_user.username}" do
    	it "deleted user" do
    		first_user.delete_object(user_panel)
    	end
    end

    context "Delete user #{second_user.username}" do
    	it "deleted user" do
    		second_user.delete_object(user_panel)
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