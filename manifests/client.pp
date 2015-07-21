define dtk_postgresql::hostname(
  $server_hostname
)
{
  notify{ "server_hostname = ${server_hostname}":}
}
