define dtk_user::simple(
  $sha1_password,
  $sudo_access
)
{
  user { $name:
    ensure     => 'present',
    managehome => true,
    password   => $sha1_password
  }
}