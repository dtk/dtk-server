module DTK; class  Assembly::Instance
  module Mixin
    def ret_adapter_and_params_from_path(path)
      return unless path
      adapter, *params = path.split(/\//)
      return adapter, params
    end

    def load_adapter_class(base, adapter_name)
      begin
        base.const_get("#{capitalize_adapter_name(adapter_name)}")
      rescue NameError => error
        fail ErrorUsage, "Unsupported path '#{adapter_name}'"
      end
    end

    def capitalize_adapter_name(adapter_name)
      adapter_name.to_s.split(/ |\_|\-/).map(&:capitalize).join("")
    end
  end
end; end