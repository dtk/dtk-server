module DTK; class Attribute::Pattern
  class Assembly
    class Link < self
      r8_nested_require('link','source')

      class Info
        attr_reader :links,:dep_component_instance,:antec_component_instance
        def initialize(parsed_adhoc_links,dep_component_instance,antec_component_instance)
          @links = parsed_adhoc_links
          @dep_component_instance = dep_component_instance
          @antec_component_instance = antec_component_instance
        end
        def dep_component_template()
          @dep_component_template ||= @dep_component_instance.get_component_template_parent()
        end
        def antec_component_template()
          @antec_component_template ||= @antec_component_instance.get_component_template_parent()
        end
      end

      #returns object of type Info
      def self.parsed_adhoc_link_info(parent,assembly,target_attr_term,source_attr_term,opts={})
        assembly_idh = assembly.id_handle()
        target_attr_pattern = create_attr_pattern(assembly,target_attr_term)
        if target_attr_pattern.attribute_idhs.empty?
          raise ErrorUsage.new("No matching attribute to target term (#{target_attr_term})")
        end
        source_attr_pattern = Source.create_attr_pattern(assembly,source_attr_term)
        
        #TODO: need to do more chaecking and processing to include:
        #  if has a relation set already and scalar conditionally reject or replace
        # if has relation set already and array, ...
        attr_info = {
          :assembly_id =>  assembly_idh.get_id(),
          :output_id => source_attr_pattern.attribute_idh.get_id()
        }
        if fn = source_attr_pattern.fn()
          attr_info.merge!(:function => fn) 
        end
        
        parsed_adhoc_links = target_attr_pattern.attribute_idhs.map do |target_attr_idh|
          hash = attr_info.merge(:input_id => target_attr_idh.get_id())
          parent.new(hash,target_attr_pattern,source_attr_pattern)
        end
        dep_cmp,antec_cmp = determine_dep_and_antec_components(target_attr_pattern,source_attr_pattern)
        Info.new(parsed_adhoc_links,dep_dep_cmp,antec_cmp)
      end
    private
      def self.determine_dep_and_antec_components(target_attr_pattern,source_attr_pattern)
        unless target_cmp = target_attr_pattern.component_instance()
          raise Error.new("Unexpected that target_attr_pattern.component() is nil")
        end
        #source_cmp can be nil when link to a node attribute
        source_cmp = source_attr_pattern.component_instance()
        unless source_cmp
          raise Error.new("Not implemented yet when source_cmp is nil")
        end
        #TODO: stub heuristic that chooses target_cmp as dependent
        dep_cmp = target_cmp
        antec_cmp = source_cmp
        [dep_cmp,antec_cmp]
      end    
    end
  end
end; end
