# This test script is used to install modules from repoman

require 'aws-sdk'
require 'yaml'

creds = YAML.load(File.read(ARGV[0]))
output_directory = ARGV[1]
environment = ARGV[2]
cleanup = ARGV[3] || nil

selected_modules = nil
if environment == "prod"
  selected_modules = YAML.load(File.open(File.dirname(__FILE__) + "/prod_repoman_module_list.yaml"))['modules']
else
  selected_modules = YAML.load(File.open(File.dirname(__FILE__) + "/test_repoman_module_list.yaml"))['modules']
end

# Instatiate needed STS credentials to access S3 buckets for verification of publish
sts = Aws::STS::Client.new(
  region: creds["region"],
  access_key_id: creds["aws_sts_key"],
  secret_access_key: creds["aws_sts_secret"]
)

policy = {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket", "s3:GetObject"],
      "Resource": [
        "arn:aws:s3:::#{creds["aws_s3_catalog_bucket"]}/*"
      ]
    }
  ]
}
p_json = policy.to_json
response = sts.assume_role(
  duration_seconds: 900,
  external_id: "nod_test_1",
  policy: p_json,
  role_arn: creds["aws_sts_catalog_role_arn"],
  role_session_name: "node_test_1"
)

s3creds = response.to_h[:credentials]

client = Aws::S3::Client.new(
  access_key_id: s3creds[:access_key_id],
  secret_access_key: s3creds[:secret_access_key],
  session_token: s3creds[:session_token],
  region: creds["region"],
)

# Extract unique namespace names and create those namespaces on dtk network
selected_namespaces = selected_modules.map { |x| x.split("/").first }.uniq
selected_namespaces.each do |namespace|
  puts "Creating namespace #{namespace} if it doesn't exist already..."
  `dtk account create-namespace #{namespace}`
end

# Iterate through list of modules for publish, get their version directories and publish them
# Check that publish passed by fetching objects from S3 bucket
# If cleanup is turned on, it will do unpublish at the end also (delete from dtk network and S3)
selected_modules.each do |sm|
  module_name = sm.gsub(/\//,'_')
  entries = Dir.entries("#{output_directory}/#{module_name}")
  versions = []
  if entries.include? 'master'
    vs = entries.reject { |entry| File.directory?(entry) } - ['master']
    versions = vs.sort_by { |v| Gem::Version.new(v) }.unshift('master')
  else
    vs = entries.reject { |entry| File.directory?(entry) }
    versions = vs.sort_by { |v| Gem::Version.new(v) }
  end

  versions.each do |version|
    # cleanup of dtk.service.yaml and modules directory if exists (not needed in module)
    `rm -rf #{output_directory}/#{module_name}/#{version}/dtk.service.yaml`
    `rm -rf #{output_directory}/#{module_name}/#{version}/modules`

    puts "Publish module #{sm} with version #{version}..."
    output = `dtk module publish -u -d #{output_directory}/#{module_name}/#{version}`
    puts output

    unless output.include? "ERROR"
      namespace_id = output.scan(/:namespace_id: (\S+)/).last.first
      module_id = output.scan(/:module_version_id: (\S+)/).last.first

      puts "Check if module #{sm} with version #{version} exists on S3..."
      begin
        tmp = client.get_object({
          bucket: creds["aws_s3_catalog_bucket"],
          key: "#{namespace_id}/#{module_id}.gz", 
        })
        puts tmp
      rescue Exception => e
        puts "Unable to get module #{sm} with version #{version} from S3...Reason: #{e.message}"
      end
    end
  end
end

# Cleanup of all published modules
if cleanup
  puts ""
  puts "Cleanup of published modules:"
  puts "-----------------------------"
  selected_modules.each do |sm|
    puts "Delete module #{sm} and its versions from dtkn..."
    puts `dtk module delete-from-dtkn -y #{sm}`
  end
end