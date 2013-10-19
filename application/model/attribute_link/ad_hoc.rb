module DTK
  class AttributeLink
    class AdHoc < Hash
      #TODO: right now just treating as preprocessing operation when target attribute term matches a set
      #may enhance to store the inputted info to trigger it for any match when assembly gets compoennt or attributes added
      def self.create_ad_hoc_links(assembly,target_attr_term,source_attr_term)
        parsed_adhoc_links = attribute_link_hashes(assembly.id_handle(),target_attr_term,source_attr_term)
        opts = {
          :donot_update_port_info => true,
          :donot_create_pending_changes => true
        }
        #create_attribute_links updates parsed_adhoc_links
        AttributeLink.create_attribute_links(assembly.get_target_idh(),parsed_adhoc_links,opts)
        parsed_adhoc_links
      end
     private
      def initialize(hash)
        super()
        replace(hash)
      end
      def self.attribute_link_hashes(assembly_idh,target_attr_term,source_attr_term)
        target_attr_idhs = Attribute::Pattern::Assembly.get_attribute_idhs(assembly_idh,target_attr_term)
        if target_attr_idhs.empty?
          raise ErrorUsage.new("No matching attribute to target term (#{target_attr_term})")
        end
        source_attr_idh,fn = Attribute::Pattern::Assembly::Source.get_attribute_idh_and_fn(assembly_idh,source_attr_term)
        
        #TODO: need to do more chaecking and processing to include:
        #  if has a relation set already and scalar conditionally reject or replace
        # if has relation set already and array, ...
        attr_info = {
          :assembly_id =>  assembly_idh.get_id(),
          :output_id => source_attr_idh.get_id()
        }
        attr_info.merge!(:function => fn) if fn
        
        target_attr_idhs.map do |target_attr_idh|
          new(attr_info.merge(:input_id => target_attr_idh.get_id()))
        end
      end
    end
  end
end

