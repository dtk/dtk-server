require './spec/spec_helper'

login = {
  username: 'dtk-admin',
  password: 'r8server'
}

user_info = {
  username: 'test',
  email: 'test@r8network.com',
  first_name: 'test_name',
  last_name: 'test_last_name',
  user_group: 'test',
  namespace: 'test'
}

describe '(Repoman Drupal API) Test Case 4: Create user and check if it is possible to get user by providing valid username/email combinations' do
  let(:repoman) { @repoman }

  context 'Login' do
    it 'passed successfully' do
      repoman.login(login[:username],login[:password])
      expect(repoman.authorization_token).not_to be_empty
    end
  end

  context 'Create user with all correct params (username, email, firstname, lastname)' do
    it 'creates user' do
      user_created = false
      response = repoman.create_user(user_info[:username], user_info[:email], user_info[:first_name], user_info[:last_name])
      ap response
      if response['status'] == 'ok'
        username = response['data']['username']
        email = response['data']['email']
        first_name = response['data']['first_name']
        last_name = response['data']['last_name']
        user_group = response['data']['user_groups'].first['name']
        namespace = response['data']['namespaces'].first['name']
        user_created = true if (username == user_info[:username] && email == user_info[:email] && first_name == user_info[:first_name] && last_name == user_info[:last_name] &&
          user_group == user_info[:user_group] && namespace == user_info[:namespace])
      end
      expect(user_created).to eq(true)
    end
  end

  context "Check if previously created user #{user_info[:username]} exists by providing both username and email" do
    it "verifies that user #{user_info[:username]} exists" do
      user_exists = false
      response = repoman.check_if_user_exists(user_info[:username], user_info[:email])
      ap response
      if response['status'] == 'ok'
        user_exists = true if response['data']['exists'] == true
      end
      expect(user_exists).to eq(true)
    end
  end

  context "Check if previously created user #{user_info[:username]} exists by providing only username" do
    it "verifies that user #{user_info[:username]} exists" do
      user_exists = false
      response = repoman.check_if_user_exists(user_info[:username], nil)
      ap response
      if response['status'] == 'ok'
        user_exists = true if response['data']['exists'] == true
      end
      expect(user_exists).to eq(true)
    end
  end

  context "Check if previously created user #{user_info[:username]} exists by providing only email" do
    it "verifies that user #{user_info[:username]} exists" do
      user_exists = false
      response = repoman.check_if_user_exists(nil, user_info[:email])
      ap response
      if response['status'] == 'ok'
        user_exists = true if response['data']['exists'] == true
      end
      expect(user_exists).to eq(true)
    end
  end

  context 'Delete private user group user_info[:user_group]' do
    it 'deletes user group' do
      user_group_deleted = false
      all_user_groups = repoman.get_user_groups
      user_group_id = all_user_groups['data'].find { |group| group['name'] == user_info[:user_group] }['id']
      response = repoman.delete_user_group(user_group_id)
      sleep 10
      ap response
      if response['status'] == 'ok'
        user_group_deleted = true if response['data']['success'] == true
      end
      expect(user_group_deleted).to eq(true)
    end
  end

  context 'Delete user user_info[:username]' do
    it 'deletes user' do
      user_deleted = false
      all_users = repoman.get_users
      user_id = all_users['data'].find { |user| user['username'] == user_info[:username] }['id']
      response = repoman.delete_user(user_id)
      ap response
      if response['status'] == 'ok'
        user_deleted = true if response['data']['success'] == true
      end
      expect(user_deleted).to eq(true)
    end
  end

  context "Delete user's namespace user_info[:namespace]" do
    it "deletes user's namespace" do
      namespace_deleted = false
      all_namespaces = repoman.get_namespaces
      namespace_id = all_namespaces['data'].find { |namespace| namespace['name'] == user_info[:namespace] }['id']
      response = repoman.delete_namespace(namespace_id)
      ap response
      if response['status'] == 'ok'
        namespace_deleted = true if response['data']['success'] == true
      end
      expect(namespace_deleted).to eq(true)
    end
  end

  context 'Logout' do
    it 'passed successfully' do
      response = repoman.logout
      expect(response['data']['success']).to eq(true)
    end
  end
end
