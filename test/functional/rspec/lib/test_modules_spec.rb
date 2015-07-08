require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context "Create test module" do |test_module_name|
  it "creates #{test_module_name} test module" do
    puts "Create tests module:", "------------------------"
    pass = true
    value = `dtk test-module create #{test_module_name}`
    puts value
    pass = false if ((value.include? "ERROR") || (value.include? "exists on client") || (value.include? "denied") || (value.include? "Conflicts with existing server local module"))
    puts "Test module #{test_module_name} created successfully!" if pass == true
    puts "Test module #{test_module_name} has not been created successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Create test module in specific namespace" do |test_module_name, namespace|
  it "creates #{test_module_name} test module in namespace #{namespace}" do
    puts "Create tests module in specific namespace:", "-------------------------------------"
    pass = true
    value = `dtk test-module create #{namespace}:#{test_module_name}`
    puts value
    pass = false if ((value.include? "ERROR") || (value.include? "exists on client") || (value.include? "denied") || (value.include? "Conflicts with existing server local module"))
    puts "Test module #{test_module_name} created successfully in namespace #{namespace}!" if pass == true
    puts "Test module #{test_module_name} has not been created successfully in namespace #{namespace}!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Install test module" do |test_module_name|
  it "installs #{test_module_name} test module from remote repo" do
    puts "Import remote test module:", "----------------------------"
    pass = true
    value = `dtk test-module install #{test_module_name}`
    puts value
    pass = false if ((value.include? "ERROR") || (value.include? "exists on client") || (value.include? "denied") || (value.include? "Conflicts with existing server local module"))
    puts "Install of test module #{test_module_name} completed successfully!" if pass == true
    puts "Install of test module #{test_module_name} did not complete successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Check test module created on local filesystem" do |test_module_filesystem_location, test_module_name|
  it "checks that #{test_module_name} test module is created on local filesystem on location #{test_module_filesystem_location}" do
    puts "Check test module created on local filesystem:", "--------------------------------------------------"
    pass = false
    `ls #{test_module_filesystem_location}/#{test_module_name}`
    pass = true if $?.exitstatus == 0
    if (pass == true)
      puts "Test module #{test_module_name} created on local filesystem successfully!"
    else
      puts "Test module #{test_module_name} was not created on local filesystem successfully!"
    end
    puts ""
    pass.should eq(true)
  end
end

shared_context "Delete test module" do |dtk_common, test_module_name|
  it "deletes #{test_module_name} test module from server" do
    test_module_deleted = dtk_common.delete_test_module(test_module_name)
    test_module_deleted.should eq(true)
  end
end

shared_context "Delete test module from local filesystem" do |test_module_filesystem_location, test_module_name|
  it "deletes #{test_module_name} test module from local filesystem" do
    puts "Delete test module from local filesystem:", "--------------------------------------------"
    pass = false
    value = `rm -rf #{test_module_filesystem_location}/#{test_module_name}`
    pass = !value.include?("cannot remove")
    puts "Test module #{test_module_name} deleted from local filesystem successfully!" if pass == true
    puts "Test module #{test_module_name} was not deleted from local filesystem successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "List test modules with filter" do |dtk_common, namespace|
  it "gets all modules from namespace #{namespace}" do
    test_modules_retrieved = dtk_common.list_test_modules_with_filter(namespace)
    test_modules_retrieved.should eq(true)
  end
end

shared_context "NEG - List test modules with filter" do |dtk_common, namespace|
  it "returns empty list of test modules because there are no test modules in namespace #{namespace}" do
    test_modules_retrieved = dtk_common.list_test_modules_with_filter(namespace)
    test_modules_retrieved.should eq(false)
  end
end

shared_context "List test modules with filter on remote" do |dtk_common, namespace|
  it "gets all modules from namespace #{namespace} on remote" do
    test_modules_retrieved = dtk_common.list_remote_test_modules_with_filter(namespace)
    test_modules_retrieved.should eq(true)
  end
end

shared_context "NEG - List test modules with filter on remote" do |dtk_common, namespace|
  it "returns empty list of test modules because there are no test modules in namespace #{namespace} on remote" do
    test_modules_retrieved = dtk_common.list_remote_test_modules_with_filter(namespace)
    test_modules_retrieved.should eq(false)
  end
end
