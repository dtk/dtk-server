require './spec/spec_helper'

repoman_url = "https://repoman1.internal.r8network.com"

namespace_info = {
	:name=>'dtk17',
	:id=>'2'
}

describe "Namespace endpoint tests" do

	let(:repoman) { RepomanRestApi.new(repoman_url) }

	context "Check if namespace exists by namespace name" do
		it "gets existing namespace by name #{namespace_info[:name]}" do
			namespace_exists = false
			response = repoman.check_if_namespace_exists(namespace_info[:name])
			ap response
			namespace_exists = true if response['data']['exists'] == true
			expect(namespace_exists).to eq(true)
		end
	end

	context "NEG - Check if namespace exists by incorrect namespace name: fake_namespace" do
		it "verifies that namespace does not exist" do
			namespace_exists = true
			response = repoman.check_if_namespace_exists('fake_namespace')
			ap response
			namespace_exists = false if response['data']['exists'] == false
			expect(namespace_exists).to eq(false)
		end
	end

	context "Get all modules that belong to namespace by namespace name #{namespace_info[:name]}" do
		it "gets all modules" do
			modules_retrieved_correctly = true
			response = repoman.get_modules_by_namespace(namespace_info[:name])
			ap response
			if response['status'] == 'ok'
				response['data'].each do |module_data|
					modules_retrieved_correctly = false if !module_data.key?('id')
					modules_retrieved_correctly = false if !module_data.key?('name')
					modules_retrieved_correctly = false if !module_data.key?('namespace_id')
					modules_retrieved_correctly = false if !module_data.key?('permission')
					modules_retrieved_correctly = false if !module_data.key?('user_id')
					modules_retrieved_correctly = false if !module_data.key?('namespace_name')
					modules_retrieved_correctly = false if !module_data.key?('git_repo_name')
					modules_retrieved_correctly = false if !module_data.key?('full_name')
					modules_retrieved_correctly = false if !module_data.key?('pp_module_type')
				end
			end
			expect(modules_retrieved_correctly).to eq(true)
		end
	end

	context "Get all modules that belong to namespace by namespace id #{namespace_info[:id]}" do
		it "gets all modules" do
			modules_retrieved_correctly = true
			response = repoman.get_modules_by_namespace(namespace_info[:id])
			ap response
			if response['status'] == 'ok'
				response['data'].each do |module_data|
					modules_retrieved_correctly = false if !module_data.key?('id')
					modules_retrieved_correctly = false if !module_data.key?('name')
					modules_retrieved_correctly = false if !module_data.key?('namespace_id')
					modules_retrieved_correctly = false if !module_data.key?('permission')
					modules_retrieved_correctly = false if !module_data.key?('user_id')
					modules_retrieved_correctly = false if !module_data.key?('namespace_name')
					modules_retrieved_correctly = false if !module_data.key?('git_repo_name')
					modules_retrieved_correctly = false if !module_data.key?('full_name')
					modules_retrieved_correctly = false if !module_data.key?('pp_module_type')
				end
			end
			expect(modules_retrieved_correctly).to eq(true)
		end
	end

	context "NEG - Get all modules that belong to namespace by incorrect namespace name: fake_namespace" do
		it "verifies that namespace does not exist" do
			error_message = ""
			response = repoman.get_modules_by_namespace('fake_namespace')
			ap response
			if response['status'] == 'notok'
				error_message = response['errors'].first['message']
			end
			expect(error_message).to eq("Namespace ('fake_namespace') was not found")
		end
	end

	context "NEG - Get all modules that belong to namespace by incorrect namespace id: 123456" do
		it "verifies that namespace does not exist" do
			error_message = ""
			response = repoman.get_modules_by_namespace('123456')
			ap response
			if response['status'] == 'notok'
				error_message = response['errors'].first['message']
			end
			expect(error_message).to eq("Namespace ('123456') was not found")
		end
	end
end