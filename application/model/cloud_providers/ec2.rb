module XYZ
  module CloudProvider
    module Ec2
      class Top
        class << self
          def connection()
            @@connection ||= CloudConnect::EC2.new
          end

          #TBD: move higher so appliers to all cloud providers
          def create_object(container_id_handle,vendor_attr_hash)
            new_objs = {relation_type() => {ref(vendor_attr_hash) =>
                {:vendor_key => vendor_key_value(vendor_attr_hash),
                  :vendor_attributes => vendor_attr_hash}}}
            Object.create_multiple_children_from_hash(container_id_handle,new_objs)          
          end
          def update_object(container_id_handle,vendor_attr_hash)
          end
          def find_object(container_id_handle,vendor_attr_hash)
            where_clause = {:vendor_key => vendor_key_value(vendor_attr_hash)}
            Object.get_object_ids_wrt_parent(relation_type(),container_id_handle,where_clause).first
          end
         private
          def vendor_key_value(vendor_attr_hash)
            unique_key_fields().map{|k|vendor_attr_hash[k]}.inspect
          end
          def ref(vendor_attr_hash)
            name_fields().map{|k|vendor_attr_hash[k]}.join("-")
          end
          def relation_type
            Aux.underscore(Aux.demodulize(self.to_s)).to_sym
          end
        end
      end
    end
  end
end
