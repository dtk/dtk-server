#Usergroup Test Case 2: NEG - Create group with invalid values


require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'
require './lib/usergroup_panel_spec'
require './lib/admin_panel_helper'

num="2"
existing_group = UserGroup.new('demo_group'+num,'Usergroup description.') 
empty_group = UserGroup.new('','Usergroup description.')
invalid_group= UserGroup.new('!@#$%'+num,'Usergroup description.')

describe "(Admin Panel UI) Usergroup Test Case 2: NEG - Create group with invalid values" do
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

    context "Create usergroup #{existing_group.name}" do
        it "created usergroup" do
            existing_group.create_object(group_panel)
        end
    end

    context "Open usergroup creation page" do
        it "opened creation page" do
            group_panel.open_create_page
        end
    end

    context "Create Usergroup with name field left empty" do
        it "will not create usergroup" do
            group_panel.enter_data(empty_group.get_data)
            group_panel.press_create_button
            expect(group_panel.on_create_page?).to eql(true)
        end
    end

    context "Create Usergroup with invalid characters in usergroup name (#{invalid_group.name})" do
        it "will not create usergroup" do
            group_panel.enter_data(invalid_group.get_data)
            group_panel.press_create_button
            expect(group_panel.on_create_page?).to eql(true)
        end
    end


    context "Create Usergroup with a too long name (101 chars)" do
        it "will not create usergroup" do
            long_name=invalid_group.get_too_long_name+num
            long_name_group=UserGroup.new(long_name,"Usergroup description.")

            group_panel.enter_data(long_name_group.get_data)
            group_panel.press_create_button
            expect(group_panel.on_create_page?).to eql(true)
        end
    end


    context "Create Usergroup with existing name (#{existing_group.name})" do 
       it "will not create usergroup" do
            group_panel.enter_data(existing_group.get_data)
            group_panel.press_create_button
            expect(group_panel.on_create_page?).to eql(true)
        end
    end

    context "Open Usergroup panel" do
        it "opened the panel" do
            header.click_on_user_groups
        end
    end

    context "Delete the #{existing_group.name} usergroup" do
        it "deleted the usergroup" do
            expect(existing_group.delete_object(group_panel)).to eql(true)
        end
    end
end