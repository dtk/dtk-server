require './spec/setup_browser'
require './lib/component_modules_spec'
require './lib/dtk_common'


shared_context "Enter usergroup name and description and create usergroup" do |page, usergroup, desc|
	it "created usergroup #{usergroup}" do
		page.enter_usergroup_name(usergroup)
  		page.enter_usergroup_desc(desc)
  		page.create_usergroup
  		expect(page.on_creation_page?).to eql(false)
	end
end

shared_context "NEG - Enter usergroup name and description and create usegroup" do |page, usergroup, desc|
	it "will not create usergroup #{usergroup}" do
	  	page.enter_usergroup_name(usergroup)
	  	page.create_usergroup
	  	expect(page.on_creation_page?).to eql(true)
	end
end

shared_context "NEG - Change name of usergroup and edit the usergroup" do |page, usergroup|
	it "will not edit usergroup #{usergroup}" do
		page.enter_usergroup_name(usergroup)
        page.edit_usergroup
        expect(page.on_edit_page?).to eql(true) 
	end
end

