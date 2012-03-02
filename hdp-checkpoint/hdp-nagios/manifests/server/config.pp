class hdp-nagios::server::config($targets)
{
  hdp-nagios::server::config::host{$targets : }
}

define hdp-nagios::server::config::host()
{
  nagios_host { $name:
    address => $name,
    alias   => $name,
    use     => 'linux-server'
  }
}
