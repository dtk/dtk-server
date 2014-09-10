module DTK
  class Namespace < Model
    # TODO: get rid of this class and fold into paraent after finish conversion
    class New < self
      NEW_NAMESPACE_DELIMITER = ':'
     private 
      def self.namespace_delimiter()
        NEW_NAMESPACE_DELIMITER
      end
    end

    NAMESPACE_DELIMITER = '::'
    def self.namespace_delimiter()
      NAMESPACE_DELIMITER
    end
    def namespace_delimiter()
      self.class.namespace_delimiter()
    end
    private :namespace_delimiter
    private_class_method :namespace_delimiter

    # TODO: should replace with something more robust to find namespace
    def self.deprecate__namespace_from_ref?(service_module_ref)
      if service_module_ref.include? '::'
        service_module_ref.split("::").first
      end
    end

    def self.common_columns()
      [
        :id,
        :group_id,
        :display_name,
        :name,
        :remote
      ]
    end

    #
    # Get/Create default namespace
    #
    def self.default_namespace(namespace_mh)
      find_or_create(namespace_mh, R8::Config[:repo][:local][:default_namespace])
    end

    def self.enrich_with_default_namespace(module_name)
      module_name.include?(namespace_delimiter()) ? module_name : "#{default_namespace_name}#{namespace_delimiter()}#{module_name}"
    end

    def self.default_namespace_name
      R8::Config[:repo][:local][:default_namespace]
    end

    def self.join_namespace(namespace, name)
      "#{namespace}#{namespace_delimiter()}#{name}"
    end

    # returns [namespace,name]; namespace can be null if cant determine it
    def self.full_module_name_parts?(name_or_full_module_name)
      if name_or_full_module_name =~ Regexp.new("(^.+)#{namespace_delimiter()}(.+$)")
        namespace,name = [$1,$2]
      else
        namespace,name = [nil,name_or_full_module_name]
      end
      [namespace,name]
    end

    def self.find_by_name(namespace_mh, namespace_name)
      sp_hash = {
        :cols => common_columns(),
        :filter => [:eq, :name, namespace_name.downcase]
      }

      results = Model.get_objs(namespace_mh, sp_hash)
      raise Error, "There should not be multiple namespaces with name '#{namespace_name}'" if results.size > 1
      results.first
    end

    def self.find_or_create(namespace_mh, namespace_name)
      raise Error, "You need to provide namespace name where creating object" if namespace_name.nil? || namespace_name.empty?
      namespace = self.find_by_name(namespace_mh, namespace_name)

      unless namespace
        namespace = create_new(namespace_mh, namespace_name)
      end

      namespace
    end

    #
    # Create namespace object
    #
    def self.create_new(namespace_mh, name, remote=nil)
      idh = create_from_rows(namespace_mh,
        [{
          :name => name,
          :display_name => name,
          :ref => name,
          :remote => remote
        }]
        ).first

      idh.create_object()
    end

    def enrich_module_name(module_name)
      "#{self.display_name()}#{namespace_delimiter()}#{module_name}"
    end

    # TODO: would need to enhance if get a legitimate key, but it has nil or false value
    def method_missing(m, *args, &block)
      get_field?(m) || super(m, *args, &block)
    end

  end
end
