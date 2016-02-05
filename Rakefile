desc "Add copyright headers"
task :headers do
  require 'rubygems'
  require 'copyright_header'

  args = {
    :license_file => '.license_header',
    :add_path => 'application/:lib/:scripts/:server_side_files/:system/:utils/:docker/',
    :output_dir => '.',
    :guess_extension => true,
  }

  command_line = CopyrightHeader::CommandLine.new( args )
  command_line.execute
end