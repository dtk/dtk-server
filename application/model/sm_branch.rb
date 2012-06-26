module XYZ
  class SmBranch < Model
    #virtual columns
    def prety_print_version()
      self[:version]||"master"
    end
  end
end
