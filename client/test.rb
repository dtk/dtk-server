require 'rubygems'
require 'restclient'
require 'pp'

class R8
  class Client
    def initialize()
      @cookies = Hash.new
    end
    def login()
      username,password = get_credentials()
      pp [username,password]
    end

    class Error < NameError
    end
   private
    def get_credentials()
      cred_file = File.expand_path("~/.r8client")
      raise Error.new("Credential file (#{cred_file}) does not exist") unless File.exists?(cred_file)
      username = password = nil
      File.open(cred_file) do |io|
        io.each_line do |line|
          line.chomp!
          if m = matches_var(:username,line)
            username = m
          elsif m = matches_var(:password,line)
            password = m
          end
        end
      end
      [username,password]
    end
    def matches_var(var,line)  
      if line =~ Regexp.new(":#{var}:[ ]+([^ ]+)")
        $1
      end
    end
  end
end

R8::Client.new.login()

=begin
r = RestClient.post 'http://localhost:7000/xyz/user/process_login',{"username"=> "joe","password" => "r8server"}
pp r.cookies

pp RestClient.get 'http://localhost:7000/xyz/task/state_info.json', {:cookies =>
{"innate.sid"=>
  "aeba7aa8e632d0c878745638a3506351f9465b025bd1b5429bf6fa341d0d15c2a0c442f26fd092086d53e4b2ca570b041e91a43c900324fa007a8ee9d269f190"}
}
=end
