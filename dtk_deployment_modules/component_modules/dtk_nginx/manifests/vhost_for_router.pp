define dtk_nginx::vhost_for_router(
  $instance_name = $name,
  $ssl_cert_path = '/etc/nginx/ssl/dtk.io_combined_2015.crt',
  $ssl_key_path = '/etc/nginx/ssl/2015.wildcard.dtk.io.key',
  $multitenant_host = 'dtkhost2.internal.r8network.com',
)
{
  include nginx

  $vhost_file = "/etc/nginx/conf.d/${instance_name}.conf"
  file { $vhost_file:
    mode    => '0644',
    content => template('dtk_nginx/vhost_router.erb'),
    notify  => Service['nginx'],
  }
}
