module DTK; class DB
  module DataProcessingUpdate
    module RecursiveDelete
     private
      #TODO: more efficient way to delete recursive; for one theer are whole trees taht once get deleted at base level do not need to be deleted above
      def delete_not_matching_children(child_id_list,factory_id_info,assigns,create_stack_array,opts={})
        parent_id_handle = IDHandle[:c => factory_id_info[:c], :guid => factory_id_info[:parent_id]]
        relation_type = factory_id_info[:relation_type]
        where_clause = child_id_list.empty? ? nil : SQL.not(SQL.or(*child_id_list.map{|id|{:id=>id}}))
        where_clause = SQL.and(where_clause,assigns.constraints) unless assigns.constraints.empty?
        delete_instances_wrt_parent(relation_type,parent_id_handle,where_clause,opts)
        if assigns.apply_recursively?
          indexed_create_stack = CreateStack.create_indexed(create_stack_array)
          indexed_create_stack.each_parent_child_pair do |parent_type,child_type,id_rels|
            delete_instances_wrt_parents(parent_id_handle,parent_type,child_type,id_rels)
          end
        end
      end

      class CreateStackArray < Array
        def self.create?(assigns)
          if assigns.kind_of?(HashObject) and assigns.apply_recursively? 
            new()
          end
        end
        def add_child!(child_relation_type,child_id)
          child_create_stack = CreateStack.new(child_relation_type,child_id)
          self << child_create_stack
          child_create_stack
        end
      end

      class CreateStack
        def initialize(relation_type,id)
          @relation_type = relation_type
          @id = id
          @children = CreateStackArray.new
        end

        def self.create_indexed(create_stack_array)
          ret = Indexed.new()
          create_stack_array.each do |create_stack|
            level = 1
            create_stack.add_to_index!(ret,level)
          end
          ret
        end
        attr_reader :children,:relation_type,:id

        def add_to_index!(indexed_create_stack,level)
          @children.each do |child_create_stack|
            indexed_create_stack.add!(level,self,child_create_stack)
            child_create_stack.add_to_index!(indexed_create_stack,level+1)
          end
        end

         #form index is [level][parent_type][child_type][parent_id] and value is array with elements children ids:
        class Indexed < Hash
          def add!(level,parent_stack,child_stack)
            pntr = self[level] ||= Hash.new
            pntr = pntr[parent_stack.relation_type] ||= Hash.new
            pntr = pntr[child_stack.relation_type] ||= Hash.new
            (pntr[parent_stack.id] ||= Array.new) << child_stack.id
          end

          def each_parent_child_pair(&block)
            each_value do |l1|
              l1.each do |parent_type,l2|
                l2.each do |child_type,id_rels|
                  block.call(parent_type,child_type,id_rels)
                end
              end
            end
          end
        end
      end
    end
  end
end; end
