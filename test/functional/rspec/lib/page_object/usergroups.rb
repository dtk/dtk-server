class Usergroups < Main

	def search_for_usergroup(usergroup)
		@session.fill_in('Search', :with => usergroup+"\n")
	end

	def open_usergroup_create_page
		@session.click_button('Create User Group')
	end

	def table_selector
		return 
	end

	def usergroup_name_selector(usergroup)
		return "//div[@class='container']/table//tr[td[text()='#{usergroup}']]"
	end

	def usergroup_desc_selector(desc)
		return "//div[@class='container']/table//tr[td[text()='#{desc}']]"
	end

	def usergroup_exists?(usergroup)
		@session.has_selector?(usergroup_name_selector(usergroup))
	end

	def open_usergroup_edit_page(usergroup)
		@session.within(usergroup_name_selector(usergroup)) do
			@session.click_link('Edit')
		end
	end

	def delete_usergroup(usergroup)
		@session.within(usergroup_name_selector(usergroup)) do
			@session.click_link('Delete')
		end
		sleep 1
		@session.driver.browser.switch_to.alert.accept
	end

	def table_usergroup_name(usergroup)
		@session.find("//tr//td[text()='#{usergroup}']").text
	end

	def table_usergroup_desc(desc)
		@session.find("//tr//td[text()='#{desc}']").text
	end


	def enter_usergroup_name(name)
		@session.fill_in('Name', :with => name)
	end

	def enter_usergroup_desc(desc) 
		@session.fill_in('Description', :with => desc)
	end

	def edit_usergroup
		@session.click_button('Edit User Group')
	end


	def create_usergroup
		@session.click_button('Create New Group')
	end

end


