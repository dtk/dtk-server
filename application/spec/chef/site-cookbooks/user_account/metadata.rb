description       "Installs a user account"

version           "0.0.1"
recipe            "user_account", "Installs a user account"

attribute "user_account/username",
  :display_name => "User name",
  :description => "User name",
  :required => true,
  :recipes => ["user_account"]

attribute "user_account/uid",
  :display_name => "User id",
  :description => "Numeric user id",
  :data_type => "integer",
  :recipes => ["user_account"]

attribute "user_account/gid",
  :display_name => "Group id",
  :description => "Primary group id",
  :data_type => "integer",
  :recipes => ["user_account"]

attribute "user_account/home",
  :display_name => "Home dir",
  :description => "Home directory location",
  :recipes => ["user_account"]

attribute "user_account/home_base",
  :display_name => "Home dir base",
  :description => "Home directories base location (home will be $home_base/$username",
  :recipes => ["user_account"]

attribute "user_account/shell",
  :display_name => "Login shell",
  :description => "Login shell",
  :recipes => ["user_account"]

###############
attribute "_meta_info",
  :basic_types => {
    "user_account" => "user" 
   }



