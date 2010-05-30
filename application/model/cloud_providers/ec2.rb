module XYZ
  module CloudProvider
    module Ec2
      class Top
        class << self
          def connection()
            @@connection ||= CloudConnect::EC2.new
          end

          #TBD: move higher so applies to all cloud providers
          def sync_with_discovered(container_id_handle,vendor_attr_hash_list)
            marked = Array.new
            vendor_attr_hash_list.each do |vendor_attr_hash|
              sync_with_discovered_aux(container_id_handle,vendor_attr_hash,base_attr_fn,marked)
            end
            delete_unmarked(container_id_handle,marked)
          end

         private
          def sync_with_discovered_aux(container_id_handle,vendor_attr_hash,base_attr_fn,marked)
            marked << vendor_key_value(vendor_attr_hash)
            id_handle = find_object(container_id_handle,vendor_attr_hash)
            if id_handle
              update_object(id_handle,vendor_attr_hash,base_attr_fn)
            else
              create_object(container_id_handle,vendor_attr_hash,base_attr_fn)
            end
          end
        
          def delete_unmarked(container_id_handle,marked)
            marked_disjunction = nil
            marked.each do |vk|
              marked_disjunction = SQL.or(marked_disjunction,{:vendor_key => vk})
            end
            where_clause = SQL.not(marked_disjunction)

            Object.delete_instances_wrt_parent(relation_type(),container_id_handle,where_clause)
          end

          def create_object(container_id_handle,vendor_attr_hash,base_attr_fn)
            obj = {:vendor_key => vendor_key_value(vendor_attr_hash)}
            if should_federate()
               obj.merge! :is_federated => true
            else 
               obj.merge! :vendor_attributes => vendor_attr_hash
               obj.merge! base_attr_fn.call(vendor_attr_hash)
            end
            Object.create_multiple_children_from_hash(container_id_handle,
                     {relation_type() => {ref(vendor_attr_hash) => obj}})
          end
          def update_object(container_id_handle,attr_hash,vendor_attr_hash)
            return nil if should_federate()
          end
          def find_object(container_id_handle,vendor_attr_hash)
            where_clause = {:vendor_key => vendor_key_value(vendor_attr_hash)}
            Object.get_object_ids_wrt_parent(relation_type(),container_id_handle,where_clause).first
          end

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
