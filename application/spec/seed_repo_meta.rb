require 'rubygems'
require 'json'

x={
  "gitolite-admin".to_sym  => {:access_rights => "RW+", :users => %w{gitolite-admin}},
  :repo2  => {:access_rights => "RW+", :users => %w{r8server}},
  "r8server-repo".to_sym     => {:access_rights => "RW+", :users => %w{r8server r8client}},
:mysql        => {:access_rights => "RW+", :users => %w{r8server r8client}},
:java      => {:access_rights => "RW+", :users => %w{r8server r8client}},
:java_webapp        => {:access_rights => "RW+", :users => %w{r8server r8client}},
:gitolite        => {:access_rights => "RW+", :users => %w{r8server r8client}},
:apache2        => {:access_rights => "RW+", :users => %w{r8server r8client}},
:postgresql        => {:access_rights => "RW+", :users => %w{r8server r8client}},
:nagios        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:tomcat        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:redis        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:php        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:wordpress        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:haproxy        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:rabbitmq        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:user        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:users        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:nrpe        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:apt        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:hadoop        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:activemq        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:ntp        => {:access_rights => "RW+", :users => %w{r8server r8client}},

:test        => {:access_rights => "RW+", :users => %w{r8server r8client}},

"puppet-mysql".to_sym        => {:access_rights => "RW+", :users => %w{r8server r8client}},

"puppet-debconf".to_sym        => {:access_rights => "RW+", :users => %w{r8server r8client}},

"puppet-java_webapp".to_sym        => {:access_rights => "RW+", :users => %w{r8server r8client}},

"puppet-java".to_sym        => {:access_rights => "RW+", :users => %w{r8server r8client}},

"puppet-stdlib".to_sym        => {:access_rights => "RW+", :users => %w{r8server r8client}},

"puppet-apt".to_sym        => {:access_rights => "RW+", :users => %w{r8server r8client}},

"puppet-hadoop".to_sym        => {:access_rights => "RW+", :users => %w{r8server r8client}},

"puppet-hadoop_apache".to_sym        => {:access_rights => "RW+", :users => %w{r8server r8client}},

"puppet-hbase".to_sym        => {:access_rights => "RW+", :users => %w{r8server r8client}},

"puppet-ganglia".to_sym        => {:access_rights => "RW+", :users => %w{r8server r8client}},

"puppet-gearman".to_sym        => {:access_rights => "RW+", :users => %w{r8server r8client}},

"merge-test".to_sym        => {:access_rights => "RW+", :users => %w{r8server r8client}},

"puppet-test".to_sym        => {:access_rights => "RW+", :users => %w{r8server r8client}},
}

all_users = Array.new
x.each_value do |v|
  v[:users].each{|u| all_users << u unless all_users.include?(u)}
end

users = all_users.inject({}) do |h,u|
  h.merge(u => {"display_name" => u, "user_name" => u})
end

repos = Hash.new
x.each do |k_x,v|
  k = k_x.to_s
  acls = v[:users].inject({}) do |h,u|
    acl = {
      "#{k}_#{u}" => {
        "display_name" => "#{k}_#{u}",
        "access_rights" => v[:access_rights],
        "*repo_user_id" => "/repo_user/#{u}"
      }
    }
    h.merge(acl)
  end
  repos[k] = {
    "display_name" => k,
    "repo_name" => k,
    "repo_user_acl" => acls
  }
end
output_hash = {"repo" => repos, "repo_user" => users}
outfile = ARGV[0]
File.open(outfile,"w"){|f|f.puts(JSON.pretty_generate(output_hash))}

