module DTK; class  Assembly
  class Instance
    module AddByPath
      require_relative('add_by_path/components')
      require_relative('add_by_path/actions')

      def add_by_path(path, content)
        delete_adapter, path_params = ret_adapter_and_params_from_path(path)
        add_class = load_adapter_class(Module.nesting.first, delete_adapter)

        raise ErrorUsage, "Unexpected that add adapter #{add_class} does not implement add method!" unless add_class.respond_to?(:add)

        add_class.add(self, { name: path_params.last, content: content })
      end
    end
  end
end;end