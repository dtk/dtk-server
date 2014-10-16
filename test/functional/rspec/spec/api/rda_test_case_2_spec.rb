require './spec/spec_helper'

login = {
	:username=>'dtk-admin',
	:password=>'r8server'
}

user_info = { 
	:username=>'test', 
	:email=>'test@r8network.com', 
	:user_group=>'test', 
	:namespace=>'test' 
}

describe "(Repoman Drupal API) Test Case 2: Create user with only required params (username, email)" do

	let(:repoman) { @repoman }

	context "Login" do
		it "passed successfully" do
			repoman.login(login[:username],login[:password])
			expect(repoman.authorization_token).not_to be_empty
		end
	end

	context "Create user with only required params (username, email)" do
		it "creates user" do
			user_created = false
			response = repoman.create_user(user_info[:username], user_info[:email], nil, nil)
			ap response
			if response['status'] == 'ok'
				username = response['data']['username']
				email = response['data']['email']
				user_group = response['data']['user_groups'].first['name']
				namespace = response['data']['namespaces'].first['name']
				user_created = true if (username == user_info[:username] && email == user_info[:email] &&
					user_group == user_info[:user_group] && namespace == user_info[:namespace])
			end
			expect(user_created).to eq(true)
		end
	end

	context "Get all repos by username for previously created user #{user_info[:username]}" do
		it "gets list of repos for created user" do
			repos_retrieved = false
			response = repoman.get_repos_by_user(user_info[:username])
			ap response
			repos_retrieved = true if response['status'] == 'ok'
			expect(repos_retrieved).to eq(true)
		end
 	end

	context "Delete private user group user_info[:user_group]" do
		it "deletes user group" do
			user_group_deleted = false
			all_user_groups = repoman.get_user_groups
			user_group_id = all_user_groups['data'].select { |group| group['name'] == user_info[:user_group] }.first['id']
			response = repoman.delete_user_group(user_group_id)
			ap response
			if response['status'] == 'ok'
				user_group_deleted = true if response['data']['success'] == true
			end
			expect(user_group_deleted).to eq(true)
		end
	end

	context "Delete user user_info[:username]" do
		it "deletes user" do
			user_deleted = false
			all_users = repoman.get_users
			user_id = all_users['data'].select { |user| user['username'] == user_info[:username] }.first['id']
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
			namespace_id = all_namespaces['data'].select { |namespace| namespace['name'] == user_info[:namespace] }.first['id']
			response = repoman.delete_namespace(namespace_id)
			ap response
			if response['status'] == 'ok'
				namespace_deleted = true if response['data']['success'] == true
			end
			expect(namespace_deleted).to eq(true)
		end
	end

	context "Logout" do
		it "passed successfully" do
			response = repoman.logout
			expect(response['data']['success']).to eq(true)
		end
	end
end