description       "Installs a user account"

version           "0.0.1"
recipe            "user_account", "Installs a user account"

attribute "user_account/username",
  :display_name => "User name",
  :description => "User name",
  :recipes => ["user_account"]

attribute "user_account/uid",
  :display_name => "User id",
  :description => "User id",
  :recipes => ["user_account"]

attribute "user_account/gid",
  :display_name => "Group id",
  :description => "User's group id",
  :recipes => ["user_account"]

###TODO may put in seprate file
attribute "_meta_info",
  :basic_types => {
    "user_account" => "user" 
   }



