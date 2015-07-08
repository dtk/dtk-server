require './spec/spec_helper'

login = {
  username: 'dtk-admin',
  password: 'r8server'
}

describe "(Repoman Drupal API) Test Case 3: NEG - Get all repos by non-existing username, non-existing user id" do
  let(:repoman) { @repoman }

  context "Login" do
    it "passed successfully" do
      repoman.login(login[:username],login[:password])
      expect(repoman.authorization_token).not_to be_empty
    end
  end

  context "NEG - Get all repos by non-existing username: fake_user" do
    it "returns error indicating this user does not exist" do
      error_message = ""
      response = repoman.get_repos_by_user('fake_user')
      ap response
      if response['status'] == 'notok'
        error_message = response['errors'].first['message']
      end
      expect(error_message).to eq("User ('fake_user') was not found")
    end
   end

   context "NEG - Get all repos by non-existing user's id: 123456" do
    it "returns error indicating this user does not exist" do
      error_message = ""
      response = repoman.get_repos_by_user('123456')
      ap response
      if response['status'] == 'notok'
        error_message = response['errors'].first['message']
      end
      expect(error_message).to eq("User ('123456') was not found")
    end
   end

   context "Logout" do
    it "passed successfully" do
      response = repoman.logout
      expect(response['data']['success']).to eq(true)
    end
  end
end
