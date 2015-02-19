require 'ap'

module XYZ
  class IntegrationController < Controller

    def rest__spin_tenant
      username, password, email = ret_non_null_request_params(:username, :password, :email)

      # Rich: You have other params in request in case you need them


      ap " Sync Started"
      ap username
      ap password
      ap email

      # Spin up tenants goes here

      # notify back repoman that tenant is ready and repoman will send email
      client = RepoManagerClient.new
      ap client.notify_tenant_ready(email, username)

      rest_ok_response
    end

  end
end