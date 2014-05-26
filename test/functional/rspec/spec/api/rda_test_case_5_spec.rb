require './spec/spec_helper'

user_info = { 
	:username=>'test', 
	:email=>'test@r8network.com', 
	:first_name=>'test_name', 
	:last_name=>'test_last_name', 
	:user_group=>'private_test', 
	:namespace=>'test' 
}

describe "(Repoman Drupal API) Test Case 5: NEG - Get user by providing incorrect username/email combinations" do

	let(:repoman) { RepomanRestApi.new }

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
end