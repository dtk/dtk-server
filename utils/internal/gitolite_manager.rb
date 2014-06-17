module DTK
  class GitoliteManager

    def self.instance()
      overriden_configuration = Gitolite::Configuration.new(
        'conf/repo-configs', 
        'conf/group-defs', 
        'keydir',
        "/home/#{R8::Config[:repo][:git][:server_username]}"
      )

      Gitolite::Manager.new(R8::Config[:repo][:git][:gitolite][:admin_directory], overriden_configuration)
    end
  end
end