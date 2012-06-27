module XYZ
  class ModuleBranch < Model
    #virtual columns
    def prety_print_version()
      self[:version]||"master"
    end
    
    def self.ret_hash_for_create(version="master")

    end
  end
end
