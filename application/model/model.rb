
#################
# TBD: will seperate into seperate files
# TBD: looks like much shared on relationship between Library, Project, and Deployment (they are all containers; so might refactor as one object that has type)

# TODO: whatever is going on here, very unclear why ClassMixinDataSourceExtensions is def inside of Model.rb

module XYZ
  module ClassMixinDataSourceExtensions
    @@ds_class_objects ||= {}
    def ds_class_object(ds_type)
      @@ds_class_objects[self] ||= {}
      return @@ds_class_objects[self][ds_type] if @@ds_class_objects[self][ds_type]
      obj_class = Aux.demodulize(self.to_s)
      obj_type = Aux.underscore(obj_class)
      require File.expand_path("#{obj_type}/#{ds_type}_#{obj_type}", File.dirname(__FILE__))
      base_class = DSAdapter.const_get ds_type.to_s.capitalize
      @@ds_class_objects[self][ds_type] = base_class.const_get obj_class
    end
  end

  # TODO: why is this called object?
  # TBD: re-examine whether current scheme is best way to implement relationship between model top, specfic model classes and the XYZ::model utility class
  class Object < Model
    set_relation_as_top()
    class << self
      #### Actions
      # idempotent
      def delete(id_handle, opts = {})
        delete_instance(id_handle, opts) if exists? id_handle
      end
      # idempotent
      def create_simple(new_uri, c, opts = {})
        create_simple_instance?(IDHandle[uri: new_uri, c: c], opts)
      end

      # TODO: rewrite using join querey

      def get_contained_attribute_ids(id_handle, opts = {})
        parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
        cmps = get_objects(ModelHandle.new(:c, :component), nil, parent_id: parent_id)
        nodes = get_objects(ModelHandle.new(:c, :node), nil, parent_id: parent_id)
        (cmps || []).map { |cmp| cmp.get_contained_attribute_ids(opts) }.flatten() +
        (nodes || []).map { |node| node.get_contained_attribute_ids(opts) }.flatten()
      end

      # TODO: this seems like generic function but specifically works with nodes?
      # type can be :asserted, :derived or :value
      def get_contained_attributes(type, id_handle, opts = {})
        ret = {}

        parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
        cmps = get_objects(ModelHandle.new(:c, :component), nil, parent_id: parent_id)
        nodes = get_objects(ModelHandle.new(:c, :node), nil, parent_id: parent_id)

        cmps.each{|cmp|
          values = cmp.get_contained_attribute_values(type, opts)

          if values
            ret[:component] ||= {}
            ret[:component][cmp.get_qualified_ref.to_sym] = values
          end
        }

        nodes.each{|node|
          values = node.get_direct_attribute_values(type, opts)
          if values
            ret[:node] ||= {}
            ret[:node][node.get_qualified_ref.to_sym] = values
          end
        }
        ret
      end

      # TBD: temp
      def get_guid(id_handle)
        id_info = IDInfoTable.get_row_from_id_handle(id_handle)
        { guid: IDInfoTable.ret_guid_from_id_info(id_info) }
      end
    end
  end
end
