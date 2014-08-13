define dtk_server::repoman_auth(
    $remote_repo_host,
    $remote_repo_port,
    $remote_repo_username,
    $remote_repo_pass,
    $tenant_pass,
)

{
  $tenant_name = $name

  if $remote_repo_port == '443' {
    $protocol = 'https'
  }
  else {
    $protocol = 'http'
  }

  $tenant_endpoint = "${protocol}://${tenant_name}.dtk.io"

  # auth to tenent
  exec { 'tenant-auth': 
    command => "/usr/bin/curl -fsLm 10 -X POST \"${tenant_endpoint}/rest/user/process_login?username=${tenant_name}&password=${tenant_pass}\" -c /tmp/tenant-cookie.txt -o /dev/null",
    creates => "/tmp/tenant-cookie.txt",
  }



}