module DTK::Client
  class ModuleCommand < CommandBaseThor
    def self.pretty_print_cols()
      [:display_name, :id, :version]
    end
    desc "list [library|workspace]","List library or workspace modules"
    def list(parent)
      case parent
       when "library":
        post rest_url("implementation/list_from_library")
       when "workspace":
          post rest_url("implementation/list_from_workspace")
       else ResponseBadParams.new("module type" => parent)
      end
    end
  end
end

