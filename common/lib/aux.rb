#TODO: move app aux to heer and then just rename to Aux
module DTK
  module AuxMixin
    def get_ssh_rsa_pub_key()
      path = "#{running_process_home_dir()}/.ssh/id_rsa.pub"
      begin
        File.open(path){|f|f.read}.chomp
      rescue Errno::ENOENT
        raise Error.new("user (#{ENV['USER']}) does not have a public key under #{path}")
      rescue => e
        raise e
      end
    end
    def get_macaddress()
      return @macaddress if @macaddress
      require 'facter'
      collection = ::Facter.collection
      @macaddress = collection.fact('macaddress').value
    end

   private
    def running_process_home_dir()
      File.expand_path("~#{ENV['USER']}") 
    end
    
  end
  module AuxCommon
    class << self
      include AuxMixin
    end
  end
end
