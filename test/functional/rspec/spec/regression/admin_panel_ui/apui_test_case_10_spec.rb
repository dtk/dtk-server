#Module Test Case 10: Edit module owner, group and permissions

require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'
require './lib/admin_panel_helper'

num='10'
mod=Modul.new('ruby_module','Component','abh','adnan','adnan','RWDP','RWDP','RWDP')
ns=Namespace.new('abh','adnan','adnan','RW','RW','RW')
edited_mod=Modul.new('ruby_module','Component','abh','demo_user'+num,'demo_group'+num,'','','')
group=UserGroup.new('demo_group'+num, 'Demo Group.'+num)
user=User.new('demo_user'+num,'password','Demo','User','demo_user'+num+'@mail.com','3','demo_group'+num)


describe "(Admin Panel UI) Module Test Case 10: Edit module owner, group and permissions" do
	let(:conf) { Configuration.instance }
	let(:header) { @homepage.get_header }
	let(:group_panel) { @homepage.get_main.get_usergroups }
	let(:user_panel) { @homepage.get_main.get_users}
  	let(:module_panel) { @homepage.get_main.get_modules }

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

    context "Open Module Panel" do
    	it "opened module panel" do
    		header.click_on_modules
    	end
    end

    context "Search for Module #{mod.name}" do
    	it "found module #{mod.name}" do
    		module_panel.search_for_object(mod.search_value)
    		expect(module_panel.object_exists?(mod.search_value)).to eql(true)
    	end
    end

    context "Open edit page for Module #{mod.name}" do
    	it "opened #{mod.name} edit page" do
    		module_panel.open_edit_page(mod.search_value)
    		expect(module_panel.on_edit_page?).to eql(true)
    	end
    end

    context "Deselect #{mod.name} module owner, group and permissions" do
    	it "deselected #{mod.name} module properties" do
    		module_panel.deselect_properties(mod.group)
    	end
    end

    context "Select #{edited_mod.owner}, #{edited_mod.group} and all permissions for #{edited_mod.name} module properties and edit module" do
    	it "properties selected and module edited" do
    		module_panel.enter_data(edited_mod.get_data)
    		module_panel.press_edit_button
    		expect(module_panel.on_edit_page?).to eql(false)
    	end
    end

    context "Module #{mod.name} edit changes" do
    	it "saved successfully" do
    		module_panel.search_for_object(edited_mod.search_value)
    		info=module_panel.get_table_row_data(edited_mod.search_value)
    		expect(info[:rights]).to eql("None / None / None")
    	end
    end

    context "Select module #{mod.name} old properties" do
    	it "selected old properties" do
    		module_panel.search_for_object(edited_mod.search_value)
    		module_panel.open_edit_page(edited_mod.search_value)
    		module_panel.deselect_properties(edited_mod.group)
    		module_panel.enter_data(mod.get_data)
    		module_panel.press_edit_button
    		expect(module_panel.on_edit_page?).to eql(false)
    	end
    end

    context "Module #{mod.name} successfully" do
    	it "returned to former properties" do
    		module_panel.search_for_object(mod.search_value)
    		info=module_panel.get_table_row_data(mod.search_value)
    		expect(info[:rights]).to eql("RWDP / RWDP / RWDP")
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
end