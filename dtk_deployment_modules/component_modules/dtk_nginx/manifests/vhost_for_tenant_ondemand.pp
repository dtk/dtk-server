define dtk_nginx::vhost_for_tenant_ondemand(
  $instance_name = $name
)
{
  include nginx

  $vhost_file = "/etc/nginx/conf.d/${instance_name}.conf"
  file { $vhost_file:
    mode    => '0644',
    content => template('dtk_nginx/vhost_ondemand.erb'),
    notify  => Service['nginx'],
  }

}
