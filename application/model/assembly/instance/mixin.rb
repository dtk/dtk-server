module DTK; class  Assembly::Instance
  module Mixin
    def ret_adapter_and_params_from_path(path)
      return unless path
      adapter, *params = path.split(/\//)
      return adapter, params
    end

    def load_for(adapter_name)
      base, *rest = adapter_name.split('::')
      loaded = self.class.const_get(base)

      rest.each { |part| loaded = loaded.const_get(part.to_s.split(/ |\_|\-/).map(&:capitalize).join("")) }

      loaded
    end

    def capitalize_adapter_name(adapter_name)
      adapter_name.to_s.split(/ |\_|\-/).map(&:capitalize).join("")
    end
  end
end; end