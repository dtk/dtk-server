class Main < PageContainer
    
  def get_usergroups
    return Usergroups.new(@session)
  end
  
  def get_users
    return Users.new(@session)
  end

  def get_namespaces
    return Namespaces.new(@session)
  end

  def get_modules
    return Modules.new(@session)
  end
end
