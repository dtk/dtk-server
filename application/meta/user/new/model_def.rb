{
  :schema=>:app_user, #cannot use schema user because reserved
  :table=>:user,
  :columns=>{
    :username => {:type=>:varchar, :size => 50},
    :password => {:type=>:varchar, :size => 50},
    :first_name => {:type=>:varchar, :size => 50},
    :last_name => {:type=>:varchar, :size => 50},
    :is_admin_user=> {:type=>:boolean},
    :email_addresses_primary => {:type=>:varchar, :size => 50},
    :settings => {:type=>:json, :size => 50},
    :status => {:type=>:varchar, :size => 50}
  }
}
