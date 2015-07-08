module DTK; class DB
  module DataProcessingUpdate
    # classes that support recursive delete
    class CreateStackArray < Array
      def self.create?(assigns)
        if assigns.is_a?(HashObject) && assigns.apply_recursively?
          new()
        end
      end

      def indexed_form
        ret = IndexedStackArray.new()
        level = 1
        each do |create_stack|
          create_stack.add_to_index!(ret,level)
        end
        ret
      end

      def add!(relation_type,id)
        create_stack = CreateStack.new(relation_type,id)
        self << create_stack
        create_stack
      end

      def add_empty!(relation_type)
        create_stack = CreateStackEmpty.new(relation_type)
        self << create_stack
        create_stack
      end
    end

    class CreateStackBase
      def initialize(relation_type)
        @relation_type = relation_type
      end
      attr_reader :relation_type
    end

    class CreateStackEmpty < CreateStackBase
      def initialize(relation_type)
        super(relation_type)
      end

      def add_to_index!(_indexed_create_stack,_level)
        # no op
      end
    end

    class CreateStack < CreateStackBase
      def initialize(relation_type,id)
        super(relation_type)
        @id = id
        @children = CreateStackArray.new
      end

      attr_reader :children,:id

      def add_to_index!(indexed_create_stack,level)
        @children.each do |child_create_stack|
          indexed_create_stack.add!(level,self,child_create_stack)
          child_create_stack.add_to_index!(indexed_create_stack,level+1)
        end
      end
    end

    # form index is [level][parent_type][child_type][parent_id] and value is array with elements children ids:
    class IndexedStackArray < Hash
      def add!(level,parent_stack,child_stack)
        level_pntr = self[level] ||= {}
        parent_pntr = level_pntr[parent_stack.relation_type] ||= {}
        child_pntr = parent_pntr[child_stack.relation_type] ||= {}
        pntr = child_pntr[parent_stack.id] ||= []
        if child_stack.is_a?(CreateStack)
          pntr << child_stack.id
        end
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
end; end
