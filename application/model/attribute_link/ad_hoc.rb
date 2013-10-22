module DTK
  class AttributeLink
    class AdHoc < Hash
      def self.create_adhoc_links(assembly,target_attr_term,source_attr_term,opts={})
        parsed_adhoc_links = attribute_link_hashes(assembly.id_handle(),target_attr_term,source_attr_term)
#TODO: debug
opts[:update_meta] = true
        if opts[:update_meta]
          AssemblyModule::Component.update_from_adhoc_links(assembly,parsed_adhoc_links)
        else
          opts_create = {
            :donot_update_port_info => true,
            :donot_create_pending_changes => true
          }
          AttributeLink.create_attribute_links(assembly.get_target_idh(),parsed_adhoc_links,opts_create)
        end
      end

      # type should be :source or :target
      def attribute_pattern(type)
        @attr_pattern[type]
      end

     private
      def initialize(hash,assembly_idh,target_attr_pattern,source_attr_pattern)
        super()
        replace(hash)
        @assembly_idh = assembly_idh
        @attr_pattern = {
          :target => target_attr_pattern,
          :source => source_attr_pattern.attribute_pattern
        }
      end

      def self.attribute_link_hashes(assembly_idh,target_attr_term,source_attr_term)
        target_attr_pattern = Attribute::Pattern::Assembly.create_attr_pattern(assembly_idh,target_attr_term)
        if target_attr_pattern.attribute_idhs.empty?
          raise ErrorUsage.new("No matching attribute to target term (#{target_attr_term})")
        end
        source_attr_pattern = Attribute::Pattern::Assembly::Source.create_attr_pattern(assembly_idh,source_attr_term)
        
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

        target_attr_pattern.attribute_idhs.map do |target_attr_idh|
          hash = attr_info.merge(:input_id => target_attr_idh.get_id())
          new(hash,assembly_idh,target_attr_pattern,source_attr_pattern)
        end
      end
    end
  end
end

