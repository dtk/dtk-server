require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'
require './lib/admin_panel_helper'

user='demo_user'
group='demo_group'
ns='demo_ns'

invalid_chars='!@#$%'
too_long='aaaaaaaaaa'
invalid_user='>.<'



describe "(Admin Panel UI) Test Script Clean up" do
	let(:conf) { Configuration.instance }
  	let(:header) { @homepage.get_header }
  	let(:group_panel) { @homepage.get_main.get_usergroups }
  	let(:user_panel) { @homepage.get_main.get_users}
  	let(:ns_panel) { @homepage.get_main.get_namespaces }
  	let(:groups) { [] }

  	context "User is" do
		it "logged in" do
      		@homepage.get_loginpage.login_user(conf.username, conf.password)
	    	homepage_header = header.get_homepage_header
	    	expect(homepage_header).to have_content('DTK')
    	end
  	end

  	context "Search for '#{group}', '#{invalid_chars}', '#{too_long}' groups" do
  		it "and delete matching results" do
			results=group_panel.get_all_results(group)
			results+=group_panel.get_all_results(invalid_chars)
			results+=group_panel.get_all_results(too_long)
  			results.each do |x|
  				group_panel.search_for_object(x)
  				group_panel.press_delete_link(x)
  			end 
  		end
  	end


  	context "Click Users panel link" do
  		it "opened user panel" do
  			header.click_on_users
  		end
  	end


  	context "Search for '#{user}', '#{invalid_chars}', '#{invalid_user}' '#{too_long}' users" do
  		it "and delete matching results" do
			results=user_panel.get_all_results(user)
			results+=user_panel.get_all_results(invalid_chars)
			results+=user_panel.get_all_results(invalid_user)
			results+=user_panel.get_all_results(too_long)
  			results.each do |x|
  				user_panel.search_for_object(x)
  				user_panel.press_delete_link(x)
  			end 
  		end
  	end

  	context "Click on Namespace panel link" do
  		it "opened namespace panel" do
  			header.click_on_namespaces
  		end
  	end

  	context "Search for '#{ns}', '#{invalid_chars}' '#{too_long}' namespaces" do
  		it "and delete matching results" do
			results=ns_panel.get_all_results(ns)
			results+=ns_panel.get_all_results(invalid_chars)
			results+=ns_panel.get_all_results(too_long)
  			results.each do |x|
  				ns_panel.search_for_object(x)
  				ns_panel.press_delete_link(x)
  			end 
  		end
  	end



  end