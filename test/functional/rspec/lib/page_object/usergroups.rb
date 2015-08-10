class Usergroups < Main

	def table_usergroup_name(usergroup)
		@session.find("//tr//td[text()='#{usergroup}']").text
	end

	def table_usergroup_desc(desc)
		@session.find("//tr//td[text()='#{desc}']").text
	end

	def enter_data(data, edit=false)
		@session.fill_in('Name', :with => data[:name])
		@session.fill_in('Description', :with => data[:desc])
	end
end


