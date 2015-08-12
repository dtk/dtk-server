class Namespaces < Main

	EDIT_SELECT_BOX="repo_client_dtk_open_struct[user_id]"
	def open_namespace_edit_page(ns)
		@session.within(:table) do
      		@session.find("//tr[td[.=\"#{ns}\"]]/td/a/span[.=\"Edit\"]").click
  		end
	end
	def select_box_selector
		EDIT_SELECT_BOX
	end
	def perm_selector(type)
		return "//fieldset[Legend[text()='#{type}']]"
	end

	def check(perm, uncheck)
		@session.check(perm) unless uncheck
		@session.uncheck(perm) if uncheck
	end

	def check_user_perms(permissions, uncheck)
		permissions.split(//).each{ |perm| @session.within perm_selector("User") do check(perm, uncheck) end } 
	end


	def check_group_perms(permissions, uncheck)
		permissions.split(//).each{ |perm| @session.within perm_selector("Group") do check(perm, uncheck) end }
	end


	def check_other_perms(permissions, uncheck)
		permissions.split(//).each{ |perm| @session.within perm_selector("Other") do check(perm, uncheck) end }
	end


	def check_permissions(user, group, other, uncheck=false)
		check_user_perms(user, uncheck) if user
		check_group_perms(group, uncheck) if group
		check_other_perms(other, uncheck) if other
	end

	def check_usergroup(group, uncheck=false)

		if Capybara.current_driver == :webkit || Capybara.current_driver == :poltergeist
			@session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').trigger('click')
		else
   			@session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').click
   		end
   		sleep 2
    	@session.uncheck(group) if uncheck
    	@session.check(group) unless uncheck
    	sleep 2
    	if Capybara.current_driver == :webkit || Capybara.current_driver == :poltergeist
			@session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').trigger('click')
		else
   			@session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').click
   		end
	end

	def select_user(user, box="[user_id]")
		@session.select(user, :from => box)
	end

	def deselect_properties(group)
		check_permissions('RW','RW','RW',true)
		check_usergroup(group, true)
		select_user('User not selected',EDIT_SELECT_BOX)
	end

	def enter_ns_data(name, owner, group, user_perm, group_perm, other_perm, edited)
		if !edited 
			@session.fill_in('Name', :with => name)
			select_user(owner)
		else	
			select_user(owner,EDIT_SELECT_BOX)
		end
		
		check_usergroup(group)
		check_permissions(user_perm, group_perm, other_perm)
	end


	def enter_data(data, edited=false)
		enter_ns_data(data[:name], data[:owner], data[:group], data[:user_perm], data[:group_perm], data[:other_perm],edited)
	end

	def get_table_row_data(name)
		info={}
		@session.within row_selector(name) do
			info[:name]=@session.find("./td[1]").text
			info[:rights]=@session.find("./td[2]").text
			info[:created]=@session.find("./td[3]").text
		end
		info
	end
end