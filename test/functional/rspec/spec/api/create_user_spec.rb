require 'spec_helper'
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

describe "Create user" do

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
end