module DTK
  class Namespace < Model
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
      module_name.include?('::') ? module_name : "#{default_namespace_name}::#{module_name}"
    end

    def self.default_namespace_name
      R8::Config[:repo][:local][:default_namespace]
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
      "#{self.display_name()}::#{module_name}"
    end

    def method_missing(m, *args, &block)
      if self.keys.include?(m)
        return self[m]
      end
      super(m, *args, &block)
    end

  end
end
