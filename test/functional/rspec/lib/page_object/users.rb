class Users < Main

  def click_on_edit_user(user)
    @session.within(:table) do
        @session.find("//tr[td[.=\"#{user}\"]]/td/a/span[.=\"Edit\"]").click
    end
  end

  def assign_user_group_for_user(usergroup)
      @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").click
      @session.check(usergroup)
      #overlapping elements issue in headless mode
      if Capybara.current_driver == :webkit || Capybara.current_driver == :poltergeist
          @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").trigger("click")
      else
          @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").click
      end
  end

  def open_user_edit_page(user)
      @session.within(:table) do
        if Capybara.current_driver == :webkit || Capybara.current_driver == :poltergeist
            @session.find("//tr[td[.=\"#{user}\"]]/td/a/span[.=\"Edit\"]").trigger('click')
        else
            @session.find("//tr[td[.=\"#{user}\"]]/td/a/span[.=\"Edit\"]").click
        end
      end
  end

  def uncheck_usergroup(group)
      if Capybara.current_driver == :webkit || Capybara.current_driver == :poltergeist
          @session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').trigger('click')
          @session.uncheck(group)
          @session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').trigger('click')
      else
          @session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').click
          @session.uncheck(group)
          @session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').click
      end
  end

  def enter_user_data(name, password, first, last, email, ns, group, edited=false)
      if !edited
        @session.fill_in('username', :with => name) 
      end
      @session.fill_in('Password', :with => password) 
      @session.fill_in('Repeat password', :with => password)
      @session.fill_in('First Name', :with => first)
      @session.fill_in('Last Name', :with => last)
      @session.fill_in('Email', :with => email)
      @session.fill_in('Maximum namespaces', :with => ns)
      if Capybara.current_driver == :webkit || Capybara.current_driver == :poltergeist
          @session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').trigger('click')
          @session.check(group)
          @session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').trigger('click')
      else 
          @session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').click
          @session.check(group)
          @session.find('//button[@class="multiselect dropdown-toggle btn btn-default"]').click
      end
  end

  def enter_user(user,edited=false)
      enter_user_data(user.username, user.password, user.first, user.last, user.email, user.ns, user.group, edited)
  end

  def enter_data(data, edit=false)
      enter_user_data(data[:username],data[:password],data[:first],data[:last],data[:email],data[:ns],data[:group],edit)
  end

  def get_user_table_info(user)
      info={}
      name=@session.find(user_name_selector(user)+'/td[1]').text
      tenant=@session.find(user_name_selector(user)+'/td[2]').text
      namespaces=@session.find(user_name_selector(user)+'/td[3]').text
      max=@session.find(user_name_selector(user)+'/td[4]').text
      info={
          name: name,
          tenant: tenant,
          group: namespaces,
          ns: max
      }
      info
  end

  def save_edit_changes
    @session.click_button('Edit User')
  end

    def get_table_row_data(name)
      info={}
      @session.within row_selector(name) do
        info[:username]=@session.find('./td[1]').text
        info[:tenant]=@session.find('./td[2]').text
        info[:ns]=@session.find('./td[3]').text
        info[:max_ns]=@session.find('./td[4]').text
      end
      info
  end
end
