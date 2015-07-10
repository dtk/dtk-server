class Main < PageContainer

  def get_usergroups
    Usergroups.new(@session)
  end

  def get_users
    Users.new(@session)
  end

  def get_namespaces
    Namespaces.new(@session)
  end

  def get_modules
    Modules.new(@session)
  end
end
