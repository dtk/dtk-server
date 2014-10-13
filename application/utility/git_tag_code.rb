require 'pp'

# no stdout buffering
STDOUT.sync = true

# checks for windows/unix for chaining commands
OS_COMMAND_CHAIN = RUBY_PLATFORM =~ /mswin|mingw|cygwin/ ? "&" : ";"

unless ARGV[0]
  print "You need to pass version tag as param to script call"
  exit(1)
end

puts "WARNING!"
puts
puts "************* PROVIDED DATA *************"
puts " VERSION TAG:    #{ARGV[0]}"
puts "*****************************************"
puts "Make sure that provided data is correct, and press ENTER to continue OR CTRL^C to stop"
a = $stdin.gets

# ['dtk-common-repo','dtk-common',

['dtk-common-repo','dtk-common','server','dtk-repo-manager','dtk-repoman-admin', 'dtk-node-agent'].each do |entry|
  if File.directory? File.join('.', entry)
    puts "Skipping '#{entry}' already exists"
  else
    puts `git clone #{PREFIX_R8SERVER_SSH_URL}#{entry}.git`
  end
end