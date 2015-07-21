define dtk_server::cron_idle_instances (
	$tenant_password = 'r8server',
	) 
{
	$tenant_name = $name

	file { "/home/${tenant_name}/check_idle_instances.sh":
	    owner   => $tenant_name,
	    content => template('dtk_server/check_idle_instances.sh.erb'),
	    mode	=> '0700',
	  }

	cron { $tenant_name:
	  command => "/home/${tenant_name}/check_idle_instances.sh >> /home/${tenant_name}/check_idle_instances.log 2>&1",
	  user    => $tenant_name,
	  hour    => '*',
	  minute  => 0,
	  require => File["/home/${tenant_name}/check_idle_instances.sh"]
	}
}