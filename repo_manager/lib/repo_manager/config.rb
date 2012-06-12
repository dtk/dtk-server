require 'singleton'
module DTK::RepoManager
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
      self[:git_user] = 'git'
      self[:git_user_home] = "/home/#{self[:git_user]}"
      self[:bare_repo_dir] = "#{self[:git_user_home]}/repositories"

      self[:admin_user] = self[:git_user]
      self[:admin_repo_dir] = "/home/#{self[:admin_user]}/gitolite-admin"
    end
    def load_config_file()
      parse_key_value_file(ConfigFile).each{|k,v|self[k]=v}
    end
    RequiredNonDefaultKeys = []
    def validate
      #TODO: need to check for legal values
      missing_keys = RequiredNonDefaultKeys - keys
      raise Error.new("Missing config keys (#{missing_keys.join(",")})") unless missing_keys.empty?
    end
  end
end
