class Header < PageContainer
  def get_homepage_header
    @session.within(:header) do
      @session.find_link('DTK')
    end
  end

  def click_on_user_groups
    @session.within(:header) do
      @session.click_link('User Groups')
    end
  end

  def click_on_users
    @session.within(:header) do
      @session.click_link('Users')
    end
  end

  def click_on_namespaces
    @session.within(:header) do
      @session.click_link('Namespaces')
    end
  end

  def click_on_modules
    @session.within(:header) do
      @session.click_link('Modules')
    end
  end

  def click_on_service_modules
    @session.within(:header) do
      @session.click_link("Modules")
      @session.click_link("Component Modules")
    end
  end

  def click_on_component_modules
    @session.within(:header) do
      @session.click_link("Modules")
      @session.click_link("Component Modules")
    end
  end
end
