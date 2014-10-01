module DTK
  class NamespaceController < AuthController
    def rest__default_namespace_name()
      rest_ok_response Namespace.default_namespace_name
    end
  end
end