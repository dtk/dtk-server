require './spec/spec_helper'

namespace_info = {
	:name=>'dtk17'
}

describe "(Repoman Drupal API) Test Case 6: Get namespace and get all modules that belong to this namespace by namespace name/id" do

	let(:repoman) { RepomanRestApi.new }

	context "Check if namespace exists by namespace name" do
		it "gets existing namespace by name #{namespace_info[:name]}" do
			namespace_exists = false
			response = repoman.check_if_namespace_exists(namespace_info[:name])
			ap response
			namespace_exists = true if response['data']['exists'] == true
			expect(namespace_exists).to eq(true)
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

	context "Get all modules that belong to namespace by namespace id" do
		it "gets all modules" do
			modules_retrieved_correctly = true
			all_namespaces = repoman.get_namespaces
			namespace_id = all_namespaces['data'].select { |namespace| namespace['name'] == namespace_info[:name] }.first['id']
			response = repoman.get_modules_by_namespace(namespace_id)
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
end