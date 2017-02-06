#!/usr/bin/ruby
require 'aws-sdk'
require 'yaml'
require 'ap'

aws_access_key = ENV['AWS_ACCESS_KEY']
aws_secret_key = ENV['AWS_SECRET_ACCESS_KEY']
aws_regions = ['us-east-1', 'us-west-1', 'us-west-2', 'eu-west-1']
raise ArgumentError, 'You must provide AWS Access Key and AWS Secret Access Key' unless aws_access_key && aws_secret_key
raise ArgumentError, 'You must provide list of aws:image_aws versions that have to be tagged' if ARGV[0].nil?

component_module_namespace = 'aws'
component_module_name = 'image_aws'
component_module_versions = ARGV[0].split(',')
component_module_file = 'dtk.module.yaml'

dtk_client_dir = "#{ENV['HOME']}/dtk/modules/#{component_module_name}"
system("mkdir -p #{dtk_client_dir}")
system("dtk module clone -d #{dtk_client_dir} #{component_module_namespace}/#{component_module_name}")
dtk_server_version = ARGV[1] || 'master'
dtk_arbiter_version = ARGV[2] || 'master'


puts "Starting AMI Tag process...", "---------------------------"
component_module_versions.each do |version|
  dtk_model = YAML.load_file("#{dtk_client_dir}/#{component_module_file}")
  dtk_model_images = dtk_model['components']['image_aws']['attributes']['images']['default']

  puts "Component-module #{component_module_namespace}:#{component_module_name} version #{version} selected: "
  aws_regions.each do |region|
    Aws.config.update({region: region})

    puts "  Tagging images on: #{region} region: "
    amis = dtk_model_images[region]
    amis.each do |image_type, image_attr|
      image = Aws::EC2::Image.new(image_attr['ami'])
      image.create_tags(tags: [ {key: 'DTK Server Version', value: dtk_server_version},
      {key: 'DTK Arbiter Version', value: dtk_arbiter_version},
      {key: 'Image_aws Version', value: version}])
      puts "    AMI #{image_type}:#{image_attr['ami']} tagged with DTK Server Version: #{dtk_server_version}, DTK Arbiter Version: #{dtk_arbiter_version}"
    end
  end
  puts ''
end
#cleanup of modules direcotry
system("rm -rf #{ENV['HOME']}/dtk/modules/#{component_module_name}")
