require './spec/spec_helper'

namespace_info = {
	:name=>'dtk17'
}

describe "(Repoman Drupal API) Test Case 7: NEG - Get non-existing namespace and get all modules that belong to this namespace by incorrect namespace name/id" do

	let(:repoman) { RepomanRestApi.new }

	context "NEG - Check if namespace exists by incorrect namespace name: fake_namespace" do
		it "verifies that namespace does not exist" do
			namespace_exists = true
			response = repoman.check_if_namespace_exists('fake_namespace')
			ap response
			namespace_exists = false if response['data']['exists'] == false
			expect(namespace_exists).to eq(false)
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