When /^credential information for the monitor user is available$/ do
  add_applicability_condition("lambda{|p|p[:db_info] and p[:db_info].find{|x|x[:username] == p[:monitor_user_id]}}")
end


