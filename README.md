## Welcome to DTK Server

### Installation

Under development.

### Setup

Under development.

## DEV GUIDE

Following are snippets that will introudce you to basic user of system and it's code base

#### DTK ORM
##### Getting default project

	default_project = Project.get_all(ModelHandle.new(c = 2, :project)).first

##### SELECT from DB


	Model.get_objs(default_project.model_handle(:user), { :cols => User.common_columns })


##### UPDATE from DB

  users = ::DTK::Model.get_objs(default_project.model_handle(:user), { :cols => [:id, :password] })

  users.each do |user|
    user[:password] = ::DTK::DataEncryption.hash_it(user[:password])
  end

  ::DTK::Model.update_from_rows(default_project.model_handle(:user), users)