define common_user::test($user)
{

  notify{' common_user::test':
    message => "Need user (${user})"
  }
}


