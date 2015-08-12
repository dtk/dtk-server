#Usergroup Test Case 3: NEG - Edit group with invalid values

require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'
require './lib/admin_panel_helper'

num='3'
first_group = UserGroup.new('demo_group1'+num,'Usergroup description.')
second_group = UserGroup.new('demo_group2'+num,'Usergroup description.')
empty_group = UserGroup.new('','Usergroup description.')
invalid_char_group= UserGroup.new('!@#$%'+num,'Usergroup description.')


describe "(Admin Panel UI) Usergroup Test Case 3: NEG - Edit group with invalid values" do
    let(:conf) { Configuration.instance }
    let(:header) { @homepage.get_header }
    let(:group_panel) { @homepage.get_main.get_usergroups }

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
    context "Create usergroup #{second_group.name} for" do
        it "created usergroup" do
            second_group.create_object(group_panel)
        end
    end

    context "Open edit page for #{first_group.name} group" do
        it "opened the edit page" do
            group_panel.search_for_object(first_group.name)
            group_panel.open_edit_page(first_group.name)
        end
    end

  	context "Edit Usergroup with name field left empty" do
        it "will not update group" do
          group_panel.enter_data(empty_group.get_data)
          group_panel.press_edit_button
          expect(group_panel.on_edit_page?).to eql(true)
        end 
    end

    context "Edit Usergroup with invalid characters in usergroup name (invalid_char_group.name)" do
        it "will not update group" do
          group_panel.enter_data(invalid_char_group.get_data)
          group_panel.press_edit_button
          expect(group_panel.on_edit_page?).to eql(true)
        end 
    end

    context "Edit Usergroup with a too long name (101 chars)" do
        it "will not update group" do
          long_name=invalid_char_group.get_too_long_name+num
          long_name_group=UserGroup.new(long_name,"Usergroup description.")

          group_panel.enter_data(long_name_group.get_data)
          group_panel.press_edit_button
          expect(group_panel.on_edit_page?).to eql(true)
        end 
    end

    context "Edit Usergroup with existing name (second_group.name)" do 
        it "will not update group" do
          group_panel.enter_data(second_group.get_data)
          group_panel.press_edit_button
          expect(group_panel.on_edit_page?).to eql(true)
        end 
    end

    context "Open Usergroup panel" do
        it "opened the panel" do
            header.click_on_user_groups
        end
    end

    context "Delete the #{first_group.name} usergroup" do
        it "deleted the usergroup" do
            expect(first_group.delete_object(group_panel)).to eql(true)
        end
    end

     context "Delete the #{second_group.name} usergroup" do
        it "deleted the usergroup" do
            expect(second_group.delete_object(group_panel)).to eql(true)
        end
    end
end