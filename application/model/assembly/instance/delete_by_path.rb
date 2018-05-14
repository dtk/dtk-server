module DTK; class  Assembly
  class Instance
    module DeleteByPath
      require_relative('delete_by_path/components')
      require_relative('delete_by_path/actions')

      def delete_by_path(path)
        delete_adapter, params = ret_adapter_and_params_from_path(path)
        delete_class = load_adapter_class(Module.nesting.first, delete_adapter)

        raise ErrorUsage, "Unexpected that delete adapter #{delete_class} does not implement delete method!" unless delete_class.respond_to?(:delete)

        delete_class.delete(self, params)
      end
    end
  end
end;end