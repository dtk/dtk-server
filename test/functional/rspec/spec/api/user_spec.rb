require './spec/spec_helper'

repoman_url = "https://repoman1.internal.r8network.com"

user_info = { 
	:username=>'test', 
	:email=>'test@r8network.com', 
	:first_name=>'test_name', 
	:last_name=>'test_last_name', 
	:user_group=>'test', 
	:namespace=>'test' 
}

user_info_2 = { 
	:username=>'test2', 
	:email=>'test2@r8network.com', 
	:user_group=>'test2', 
	:namespace=>'test2' 
}

user_info_3 = { 
	:username=>'test3', 
	:email=>'test3@r8network.com', 
}

describe "User endpoint tests" do

	let(:repoman) { RepomanRestApi.new(repoman_url) }

	context "Create user with all correct params (username, email, firstname, lastname)" do
		it "creates user" do
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

	context "Get all repos by username for previously created user #{user_info[:username]}" do
		it "gets list of repos for created user" do
			repos_retrieved = false
			response = repoman.get_repos_by_user(user_info[:username])
			ap response
			repos_retrieved = true if response['status'] == 'ok'
			expect(repos_retrieved).to eq(true)
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

	context "NEG - Check if user: fake_user exists by providing false email and username" do
		it "verifies that user: fake_user does not exist" do
			user_exists = true
			response = repoman.check_if_user_exists('fake_user', 'fake@r8network.com')
			ap response
			if response['status'] == 'ok'
				user_exists = false if response['data']['exists'] == false
			end	
			expect(user_exists).to eq(false)
		end
	end

	context "NEG - Check if user: fake_user exists by providing false email and existing username" do
		it "verifies that user does not exist" do
			user_exists = true
			response = repoman.check_if_user_exists(user_info[:username], 'fake@r8network.com')
			ap response
			if response['status'] == 'ok'
				user_exists = false if response['data']['exists'] == false
			end	
			expect(user_exists).to eq(false)
		end
	end

	context "NEG - Check if user: fake_user exists by providing existing email and false username" do
		it "verifies that user does not exist" do
			user_exists = true
			response = repoman.check_if_user_exists('fake_user', user_info[:email])
			ap response
			if response['status'] == 'ok'
				user_exists = false if response['data']['exists'] == false
			end	
			expect(user_exists).to eq(false)
		end
	end

	context "Create user with only required params (username, email)" do
		it "creates user" do
			user_created = false
			response = repoman.create_user(user_info_2[:username], user_info_2[:email], nil, nil)
			ap response
			if response['status'] == 'ok'
				username = response['data']['username']
				email = response['data']['email']
				user_group = response['data']['user_groups'].first['name']
				namespace = response['data']['namespaces'].first['name']
				user_created = true if (username == user_info_2[:username] && email == user_info_2[:email] &&
					user_group == user_info_2[:user_group] && namespace == user_info_2[:namespace])
			end
			expect(user_created).to eq(true)
		end
	end

	context "NEG - Create user with only username specified" do
		it "returns error that both username and email are required" do
			error_message = ""
			response = repoman.create_user(user_info_3[:username], nil, nil, nil)
			ap response
			if response['status'] == 'notok'
				error_message = response['errors'].first['message']
			end
			expect(error_message).to include("Missing required parameter ('email')")
		end
	end

	context "NEG - Create user with only email specified" do
		it "returns error that both username and email are required" do
			error_message = ""
			response = repoman.create_user(nil, user_info_3[:email], nil, nil)
			ap response
			if response['status'] == 'notok'
				error_message = response['errors'].first['message']
			end
			expect(error_message).to include("Missing required parameter ('username')")
		end
	end
end