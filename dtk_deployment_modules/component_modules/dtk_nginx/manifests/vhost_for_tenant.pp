define dtk_nginx::vhost_for_tenant(
  $instance_name
)
{
  include nginx

  $dtk_tenant_name = $name

  nginx::resource::upstream { $dtk_tenant_name:
    members => ["unix:/home/${dtk_tenant_name}/thin/thin.sock"]
  }

  nginx::resource::vhost { "${instance_name}.dtk.io":
    listen_port         => $dtk_nginx::base::listen_port,
    proxy               => "http://${dtk_tenant_name}",
    ssl		              => true,
    ssl_cert            => "puppet:///modules/dtk_nginx/dtk.io_combined.crt",
    ssl_key             => "puppet:///modules/dtk_nginx/wildcard.dtk.io.key",
    ssl_protocols       => "TLSv1 TLSv1.1 TLSv1.2 SSLv3",
    ssl_ciphers         => "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:ECDHE-RSA-RC4-SHA:ECDHE-ECDSA-RC4-SHA:RC4-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK",
    ssl_cache           => "shared:SSL:50m",
  }

}

define dtk_nginx::vhost_for_router(
  $instance_name,
  $ssl_cert_path = '/etc/nginx/ssl/dtk.io_combined_2015.crt',
  $ssl_key_path = '/etc/nginx/ssl/2015.wildcard.dtk.io.key',
  $multitenant_host = 'dtkhost2.internal.r8network.com',
)
{
  $vhost_file = "/etc/nginx/conf.d/${instance_name}"
  file { $vhost_file:
    mode    => '0644',
    content => template('dtk_nginx/vhost_router.erb'),
    notify  => Service['nginx'],
  }
}

# not usable with jfryman/nginx
define dtk_nginx::vhost_enable(
  $instance_name = $name,
  $vhost_file
)
{
  $vhost_file_enabled = "/etc/nginx/sites-enabled/${instance_name}"

  file { $vhost_file_enabled:
    ensure => symlink,
    target => $vhost_file,
    notify => Service['nginx']
  }
}
