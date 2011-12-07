#TODO: incomplete; when refactored to use adapter structure; structure looked like mock used all same as grit except for clone branch
module XYZ
  class RepoManagerMock < RepoManager
    def self.create(path,branch,opts={})
      new(path,branch,opts)
    end
    def initialize(path,branch,opts={})
      raise Error.new("mock mode only supported when branch=='master'") unless  branch=="master"
      root = R8::Config[:repo][:base_directory]
      @path = "#{root}/#{path}"
    end
    def get_file_content(file_asset)
      Dir.chdir(@path){File.open(file_asset[:path]){|f|f.read}}
    end

    def self.delete_all_server_repos()
    end
  end
end
