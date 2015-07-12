module TestModulesMixin
  def delete_test_module(test_module_to_delete)
    puts 'Delete test module:', '--------------------'
    test_module_deleted = false
    test_modules_list = send_request('/rest/test_module/list', {})

    if (test_modules_list['data'].find { |x| x['display_name'] == test_module_to_delete })
      puts "Test module #{test_module_to_delete} exists in test module list. Try to delete test module..."
      delete_response = send_request('/rest/test_module/delete', test_module_id: test_module_to_delete)
      puts 'Test module delete response:'
      pretty_print_JSON(delete_response)

      if (delete_response['status'] == 'ok' && test_modules_list['data'].select { |x| x['module_name'].nil? })
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
    puts ''
    test_module_deleted
  end

  def list_test_modules_with_filter(namespace)
    puts 'List test modules with filter:', '---------------------------------'
    test_modules_retrieved = true
    test_modules_list = send_request('/rest/test_module/list', detail_to_include: [], module_namespace: namespace)
    pretty_print_JSON(test_modules_list)

    if test_modules_list['data'].empty?
      test_modules_retrieved = false
    else
      test_modules_list['data'].each do |cmp|
        if cmp['namespace']['display_name'] != namespace
          test_modules_retrieved = false
          break
        end
      end
    end
    puts ''
    test_modules_retrieved
  end

  def list_remote_test_modules_with_filter(namespace)
    puts 'List remote test modules with filter:', '------------------------------------'
    test_modules_retrieved = true
    test_modules_list = send_request('/rest/test_module/list_remote', rsa_pub_key: self.ssh_key, module_namespace: namespace)
    pretty_print_JSON(test_modules_list)

    if test_modules_list['data'].empty?
      test_modules_retrieved = false
    else
      test_modules_list['data'].each do |cmp|
        unless cmp['display_name'].include? namespace
          test_modules_retrieved = false
          break
        end
      end
    end
    puts ''
    test_modules_retrieved
  end
end
