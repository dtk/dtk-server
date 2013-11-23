module DTK; class ComponentDSL; class V3
  class IncrementalGenerator
    class LinkDef < IGBase::LinkDef
      r8_nested_require('link_def','dependencies_section')
      r8_nested_require('link_def','link_defs_section')
      def generate(aug_link_def,opts={})
        dependencies = super(aug_link_def,:no_attribute_mappings => true)
        link_defs = LinkDefsSection.new.generate(aug_link_def)
        {'dependencies' => dependencies,'link_defs' => link_defs}
      end

      def merge_fragment!(full_hash,fragment,context={})
        DependenciesSection.new.merge_fragment!(full_hash,fragment['dependencies'],context)
        LinkDefsSection.new.merge_fragment!(full_hash,fragment['link_defs'],context)
        full_hash
      end
    end
  end
end; end; end
