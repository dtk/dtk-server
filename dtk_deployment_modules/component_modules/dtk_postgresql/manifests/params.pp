class dtk_postgresql::params()
{
 	$version = "8.4"

	case $::osfamily {
		'RedHat', 'Linux': {
		  $server_package = "postgresql-server"
		  $server_conf_dir = "/var/lib/pgsql/data/" 
		  $server_data_dir = $server_conf_dir
		  # make sure that '-h localhost' is only used on RHEL/CentOS
		  $hostname_argument = "-h localhost"
		  $external_pid_file = "(none)"
		  $ssl = "off"
		  $unix_socket_directory = ""
		}
		'Debian' : {
		  $server_package = "postgresql-${version}"
		  $server_conf_dir = "/etc/postgresql/${version}/main"
		  $server_data_dir = "/var/lib/postgresql/${version}/main"
		  $hostname_argument = ""
		  $external_pid_file = "/var/run/postgresql/${version}-main.pid" 
		  $ssl = "true"
		  $unix_socket_directory = "/var/run/postgresql"
		}
	}
	
	$server_user = "postgres"

}