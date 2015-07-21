define dtk_server::add_user(
  $tenant_user,
  $tenant_user_password = 'r8server',
  $tenant_db_user = "no_user"
)
{
  $tenant_db = $tenant_user

  if $tenant_db_user != "no_user" {
    dtk_server::tenant::schema_exec { "add_user.rb ${tenant_db_user}" :
      db          => $tenant_db,
      user        => $tenant_user,
      app_homedir => "/home/${tenant_user}",
      utility_cmd => "add_user.rb ${tenant_db_user} -p ${tenant_user_password}",
      sql_test    => "unavaliable"
    }
  }
}
