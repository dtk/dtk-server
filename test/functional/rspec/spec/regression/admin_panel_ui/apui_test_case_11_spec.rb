#Module Test Case 11: NEG - Edit deselect module owner, group and permissions and save edit changes

require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'
require './lib/admin_panel_helper'


mod=Modul.new('postgres_module','Component','abh','adnan','adnan','RWDP','RWDP','RWDP')


describe "(Admin Panel UI) Module Test Case 11: NEG - Edit deselect module owner, group and permissions and save edit changes" do
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

    context "Save edit changes" do
    	it "will not save changes for #{mod.name}" do
    		module_panel.press_edit_button
    		expect(module_panel.on_edit_page?).to eql(true)
    	end	
    end

   	context "Return module #{mod.name} old properties" do
    	it "returned old properties" do
    		module_panel.enter_data(mod.get_data)
    		module_panel.press_edit_button
    		expect(module_panel.on_edit_page?).to eql(false)
    	end
    end

    context "Search for module #{mod.name} and verify properties" do
    	it "verified #{mod.name} properties" do
    		module_panel.search_for_object(mod.search_value)
    		info=module_panel.get_table_row_data(mod.search_value)
    		expect(info[:rights]).to eql("RWDP / RWDP / RWDP")
    	end
    end
end