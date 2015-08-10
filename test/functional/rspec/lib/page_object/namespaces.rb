class Namespaces < Main

	def open_namespace_edit_page(ns)
		@session.within(:table) do
      		@session.find("//tr[td[.=\"#{ns}\"]]/td/a/span[.=\"Edit\"]").click
  		end
	end

	def perm_selector(type)
		return "//fieldset[Legend[text()='#{type}']]"
	end

	def check_user_perms(permissions)
		perms=permissions.split
		perms.each{ |perm| @session.within perm_selector("User") do check(perm) end}
	end


	def check_group_perms(permissions)
		perms=permissions.split
		perms.each{ |perm| @session.within perm_selector("Group") do check(perm) end}
	end


	def check_other_perms(permissions)
		perms=permissions.split
		perms.each{ |perm| @session.within perm_selector("Other") do check(perm) end}
	end


	def check_permissions(user, group, other)
		check_user_perms(user) if user
		check_group_perms(group) if group
		check_other_perms(other) if other
	end

	def check_usergroup(group, option=true)
   		@session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').click
    	@session.uncheck(group) unless option
    	@session.check(group) if option 
    	@session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').click
	end

	def select_user(user) 
		box="//select[@id='_user_id']"
		@session.select(user, :from => box)
	end

	def enter_ns_data(name, owner, group, user_perm, group_perm, other_perm)
		fill_in('Name', :with => name)
		select_user(owner)
		check_usergroup(group, true)
		check_permissions(user_perm, group_perm, other_perm)
	end

	def search_for_namespace(ns)
		@session.fill_in('Search', :with => ns)
	end

	def enter_data(data)
		enter_ns_data(data[:name], data[:owner], data[:user_perm], data[:group_perm], data[:other_perm])
	end
end