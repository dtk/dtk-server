module XYZ
  module DSConnector
    class Top
      def initialize(container_uri)
        @container_uri = container_uri
        initialize_extra()
      end
      # this can be overwritten
      def initialize_extra
      end

      def get_objects(obj_type,source_obj_type,&block)
        method_name = "get_objects__#{obj_type}#{source_obj_type ? "__" + source_obj_type : ""}".to_sym
        send(method_name){|source_obj|block.call(source_obj)}
      end
    end
  end
  module DataSourceConnectorInstanceMixin
    def set_and_share_ds_connector!(common_ds_connectors,container_uri)
      common_ds_connectors[container_uri] ||=  {}
      common_ds_connectors[container_uri][@ds_connector_class] ||= @ds_connector_class.new(container_uri)
      @ds_connector_instance = common_ds_connectors[container_uri][@ds_connector_class]
    end

    private

    def load_ds_connector_class
      rel_path = "#{ds_name()}/#{ds_name()}"
      begin
        file_path = File.expand_path(rel_path, File.dirname(__FILE__))
        require file_path
       rescue Exception => e
        raise Error.new("Connector file to process object data source #{ds_name()} does not exist") unless File.exists?(file_path + ".rb")
        raise e
      end

      @ds_connector_class = DSConnector.const_get Aux.camelize(ds_name())
    end

    def get_objects(&block)
      @ds_connector_instance.get_objects(obj_type(),source_obj_type(),&block)
    end
  end
end

