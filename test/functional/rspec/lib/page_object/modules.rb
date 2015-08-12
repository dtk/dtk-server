class Modules < Main

EDIT_SELECT_BOX="repo_client_dtk_open_struct[user_id]"

  def click_on_edit_module(module_name)
    @session.fill_in 'search_term', with: module_name + "\n"
    @session.within(:table) do
      @session.find("//tr[td[.=\"#{module_name}\"]]/td/a/span[.=\"Edit\"]").click
    end
  end

  def get_access_rights(module_name)
    @session.within(:table) do
      @session.find("//tr[td[.=\"#{module_name}\"]]/td[3]")
    end
  end

  def set_module_owner_user(user)
    @session.select(user, from: 'repo_client_dtk_open_struct_user_id')
  end

  def set_module_owner_group(usergroup)
    @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").click
    @session.check(usergroup)
    #overlapping elements issue in headless mode
    if Capybara.current_driver == :webkit || Capybara.current_driver == :poltergeist
      @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").trigger("click")
    else
      @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").click
    end
  end

  def unset_module_owner_group(usergroup)
    @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").click
    @session.uncheck(usergroup)
    #overlapping elements issue in headless mode
    if Capybara.current_driver == :webkit || Capybara.current_driver == :poltergeist
      @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").trigger("click")
    else
      @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").click
    end
  end

  def set_module_permissions(permissions = {})
    permissions.each do |key, value|
      if value
        @session.check(key.to_s)
      else
        @session.uncheck(key.to_s)
      end
    end
  end

  def save_edit_changes
    @session.click_button('Edit Module')
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

      @session.uncheck(group) if uncheck
      @session.check(group) unless uncheck
      
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
    check_permissions('RWDP','RWDP','RWDP',true)
    check_usergroup(group, true)
    select_user('User not selected',EDIT_SELECT_BOX)
  end

  def enter_module_data(owner, group, user_perm, group_perm, other_perm)
      select_user(owner,EDIT_SELECT_BOX)
      check_usergroup(group)
      check_permissions(user_perm,group_perm,other_perm)
  end

  def enter_data(data)
      enter_module_data(data[:owner],data[:group],data[:user_perm],data[:group_perm],data[:other_perm])
  end

  def get_table_row_data(name)
    info={}
    @session.within row_selector(name) do
      info[:name]=@session.find("./td[1]").text
      info[:type]=@session.find("./td[2]").text
      info[:version]=@session.find("./td[3]").text
      info[:rights]=@session.find("./td[4]").text
    end
    info
  end

end
