module TestModulesMixin
	def delete_test_module(test_module_to_delete)
		puts "Delete test module:", "--------------------"
		test_module_deleted = false
		test_modules_list = send_request('/rest/test_module/list', {})

		if (test_modules_list['data'].select { |x| x['display_name'] == test_module_to_delete }.first)
			puts "Test module #{test_module_to_delete} exists in test module list. Try to delete test module..."
			delete_response = send_request('/rest/test_module/delete', {:test_module_id=>test_module_to_delete})
			puts "Test module delete response:"
			pretty_print_JSON(delete_response)

			if (delete_response['status'] == 'ok' && test_modules_list['data'].select { |x| x['module_name'] == nil })
				puts "Test module #{test_module_to_delete} deleted successfully"
				test_module_deleted = true
			else
				puts "Test module #{test_module_to_delete} was not deleted successfully"
				test_module_deleted = false
			end
		else
			puts "Test module #{test_module_to_delete} does not exist in test module list and therefore cannot be deleted."
			test_module_deleted = false
		end
		puts ""
		return test_module_deleted
	end
end