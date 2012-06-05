require 'singleton'
module R8::RepoManager
  class Config < Hash
    include Singleton
    #include ParseFile
    def self.[](k)
      Config.instance[k]
    end
   private
    def initialize()
      set_defaults()
      #load_config_file()
      validate()
    end
    def set_defaults()
      self[:admin_repo_dir] = '/home/repo_manager/gitolite-admin.git'
      self[:git_user] = 'git'
      self[:git_user_home] = "/home/#{self[:git_user]}"
    end
    def load_config_file()
      parse_key_value_file(ConfigFile).each{|k,v|self[k]=v}
    end
    RequiredKeys = [:admin_repo_dir,:git_user,:git_user_home]
    def validate
      #TODO: need to check for legal values
      missing_keys = RequiredKeys - keys
      raise Error.new("Missing config keys (#{missing_keys.join(",")})") unless missing_keys.empty?
    end
  end
end
