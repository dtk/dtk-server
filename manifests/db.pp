define dtk_postgresql::db($db_name)
{
  include dtk_postgresql::params
  $hostname_argument = $dtk_postgresql::params::hostname_argument

  $cmd = "createdb ${db_name} -U postgres ${hostname_argument}"
  $check_query = "select count(*) from pg_database where datname = '${db_name}';"
  $check = inline_template('psql --tuples-only -U postgres ${hostname_argument} --command "<%= check_query %>" | grep 0') 
  
  exec { "create-${db_name}" :
  	command => $cmd,
    onlyif  => $check,
    path    => ['/bin','/usr/bin']
  }
}
