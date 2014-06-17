define :process_instance, :element => {} do
  user_account = params[:element]
  home = user_account[:home]||( user_account[:home_base] ? "#{user_account[:home_base]}/#{user_account[:user_name]}" : nil)
  if home
    # make home dir (if does not exist)
  end
require 'pp';pp [:home,user_account[:username],home]
  user user_account[:username] do
    uid  user_account[:uid]
    gid user_account[:gid]
    home home 
    shell user_account[:shell]
  end
end
