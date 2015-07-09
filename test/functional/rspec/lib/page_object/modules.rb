class Modules < Main

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
    if Capybara.default_driver == :webkit
      @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").trigger('click')
    else
      @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").click
    end
  end

  def unset_module_owner_group(usergroup)
    @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").click
    @session.uncheck(usergroup)
    #overlapping elements issue in headless mode
    if Capybara.default_driver == :webkit
      @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").trigger('click')
    else
      @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").click
    end
  end

  def set_module_permissions(permissions={})
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
end
