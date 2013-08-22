module DTK; class Attribute
  class Pattern 
    r8_nested_require('pattern','type')

    def self.get_attribute_idhs(base_object_idh,attr_term)
      create(attr_term).ret_or_create_attributes(base_object_idh)
    end

    def self.set_attributes(base_object,av_pairs,opts={})
      ret = Array.new
      attribute_rows = Array.new
      av_pairs.each do |av_pair|
        pattern = create(av_pair[:pattern],opts)
        #conditionally based on type ret_or_create_attributes may only ret and not create attributes
        attr_idhs = pattern.ret_or_create_attributes(base_object.id_handle(),Aux.hash_subset(opts,[:create]))
        unless attr_idhs.empty?
          attribute_rows += attr_idhs.map{|idh|{:id => idh.get_id(),:value_asserted => av_pair[:value]}}
        end
      end
      return ret if attribute_rows.empty?
      attr_ids = attribute_rows.map{|r|r[:id]}
      attr_mh = base_object.model_handle(:attribute)

      sp_hash = {
        :cols => [:id,:group_id,:display_name,:node_node_id,:component_component_id],
        :filter => [:oneof,:id,attribute_rows.map{|a|a[:id]}]
      }
      existing_attrs = Model.get_objs(attr_mh,sp_hash)
      ndx_new_vals = attribute_rows.inject(Hash.new){|h,r|h.merge(r[:id] => r[:value_asserted])}
      LegalValue.raise_usage_errors?(existing_attrs,ndx_new_vals)

      Attribute.update_and_propagate_attributes(attr_mh,attribute_rows)
      SpecialProcessing::Update.handle_special_processing_attributes(existing_attrs,ndx_new_vals)

      #TODO: clean up; modified because attr can be of type attribute or may have field :attribute]
      filter_proc = Proc.new do |attr|
        attr_id =
          if attr.kind_of?(Attribute) then attr[:id]
          elsif attr[:attribute] then attr[:attribute][:id]
          else
            raise Error.new("Unexpected argument attr (#{attr.inspect})")
          end
        attr_ids.include?(attr_id)
      end
      #filter_proc = proc{|attr|attr_ids.include?(attr[:id])}
      base_object.info_about(:attributes,Opts.new(:filter_proc => filter_proc))
    end
  
    class Assembly < self
      def self.create(attr_term,opts={})
        #considering attribute id to belong to any format so processing here
        if attr_term =~ /^[0-9]+$/
          return Type::ExplicitId.new(attr_term)
        end

        format = opts[:format]||Format::Default
        klass = 
          case format
            when :simple then Simple
            when :canonical_form then CanonicalForm
          else raise Error.new("Unexpected format (#{format})")
          end
        klass.create(attr_term,opts)
      end

      #for attribute relation sources
      class Source < self
        def self.get_attribute_idh(base_object_idh,source_attr_term)
          if source_attr_term =~ /^\$(.+$)/
            attr_term = $1
            attr_idhs = get_attribute_idhs(base_object_idh,attr_term)
            if attr_idhs.size > 1
              raise ErrorUsage.new("Source attribute term must match just one, not multiple attributes")
            end
            attr_idhs.first
          else
            raise ErrorParse.new(source_attr_term)
          end
        end
      end

      class Simple
        def self.create(attr_term,opts={})
          split_term = attr_term.split("/")
          if split_term.size > 3 
            raise ErrorParse.new(attr_term)
          end
          case split_term.size          
            when 1 
              Type::AssemblyLevel.new("attribute[#{split_term[0]}]")
            when 2 
              Type::NodeLevel.new("node[#{split_term[0]}]/attribute[#{split_term[1]}]")
            when 3 
              Type::ComponentLevel.new("node[#{split_term[0]}]/component[#{split_term[1]}]/attribute[#{split_term[2]}]")
          end
        end
      end

      class CanonicalForm
        def self.create(attr_term,opts={})
          #can be an assembly, node or component level attribute
          if attr_term =~ /^attribute/
            Type::AssemblyLevel.new(attr_term)
          elsif attr_term  =~ /^node[^\/]*\/component/
            Type::ComponentLevel.new(attr_term)
          elsif attr_term  =~ /^node[^\/]*\/attribute/
            Type::NodeLevel.new(attr_term)
          else
            raise ErrorParse.new(attr_term)
          end
        end
      end
    end

    class Node < self
      def self.create(pattern)
        if pattern =~ /^[0-9]+$/
          Type::ExplicitId.new(pattern)
        else
          raise ErrorParse.new(pattern)
        end
      end
    end

    class ErrorParse < ErrorUsage
      def initialize(pattern)
        super("Cannot parse #{pattern}")
      end
    end
    class ErrorNotImplementedYet < Error
      def initialize(pattern)
        super("not implemented yet: #{pattern}")
      end
    end
  end
end; end

