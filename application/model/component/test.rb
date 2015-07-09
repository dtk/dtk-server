module DTK
  class Component
    class Test < self
      class LinkedTest
        attr_reader :test_component, :var_mappings_hash
        def initialize(test_component, ams)
          @test_component = test_component
          @attribute_mappings = ams
          @var_mappings_hash = nil
        end

        def get_component_attributes
          @attribute_mappings.map { |am| am_component_attr(am) }
        end

        def find_mapped_component_test_attributes(_cmp_attrs)
          # This function flows the cmp_attribute values through component_To_test_attribute_mappings
          component_to_test_attribute_mappings()
        end

        private

        def component_to_test_attribute_mappings
          return @var_mappings_hash if @var_mappings_hash
          @var_mappings_hash = {}
          @attribute_mappings.each do |am|
            index = am_component_attr(am)
            test_attr = am_test_attr(am)

            if existing_var = @var_mappings_hash[index]
              # TODO: just putting this in temporarily to check assumptions are right
              unless existing_var == test_attr
                Log.error("Unexpected that #{index} has multiple mappings")
                next
              end
            end

            @var_mappings_hash[index] = am_test_attr(am)
          end
          @var_mappings_hash
        end

        #'output' is the attribute that is used to propagate value to the input
        # For LinkedTest objects output corresponds to component and input to component test
        def am_component_attr(am)
          output = []
          am.each do |a|
            output << a[:output][:term_index]
          end
          return output
        end

        def am_test_attr(am)
          output = []
          am.each do |a|
            output << a[:input][:term_index]
          end
          return output
        end
      end

      class LinkedTests
        attr_reader :component, :test_array, :node
        def initialize(cmp, test_array = [])
          @node = { id: cmp[:node][:id], display_name: cmp[:node][:display_name] }
          @component = cmp.hash_subset(:id, :display_name)
          @test_array = test_array
        end

        def add_test!(test_component, ams)
          @test_array << LinkedTest.new(test_component, ams)
        end

        def find_relevant_linked_test_array
          # find the relevant parameters on @test_component by looking at attribute mappings
          cmp_attribute_names = []
          @test_array.each do |test|
            cmp_attribute_names += test.get_component_attributes()
          end
          cmp_attribute_names.uniq!
          # Compute the component attribute vars that correspond to cmp_attribute_names
          cmp_attr_vals = nil
          find_mapped_component_test_attributes(cmp_attr_vals)
        end

        private

        def find_mapped_component_test_attributes(cmp_attr_vals)
          @test_array.select { |test| test.find_mapped_component_test_attributes(cmp_attr_vals) }
        end
      end

      # returns array of ComponentLinkedTests
      def self.get_linked_tests(assembly_instance, project, filter_component = nil)
        ret = []
        opts = Opts.new(
          detail_to_include: [:component_dependencies],
          filter_component: filter_component
        )

        aug_cmps = assembly_instance.get_augmented_components(opts)
        # ndx_test_cmps is tests components indexed by field component_type
        #TODO: need to factor in taest namespaces
        link_def_links, ndx_test_cmps = get_link_def_links_to_tests(project, aug_cmps)
        return ret if link_def_links.empty?

        ndx_attribute_mappings = {}
        link_def_links.each do |ld_link|
          am_list = ld_link.attribute_mappings()
          pntr = ndx_attribute_mappings[ld_link[:link_def_id]] ||= { test_component: ld_link[:remote_component_type], ams: [] }
          pntr[:ams] << am_list
        end

        ndx_ret = {}
        each_link(aug_cmps) do |cmp, link|
          cmp_id = cmp.id
          if test_info = ndx_attribute_mappings[link[:id]]
            linked_tests = ndx_ret[cmp_id] ||= LinkedTests.new(cmp)
            test_component = ndx_test_cmps[test_info[:test_component]]
            linked_tests.add_test!(test_component, test_info[:ams])
          end
        end
        ndx_ret.values
      end

      private

      # returns [link_def_links, ndx_test_cmps] (ndx is component_type)
      def self.get_link_def_links_to_tests(project, aug_cmps)
        ret = [[], []]
        # Find all dependencies (link defs) that point to a test
        # then find all link_defs and select ones that are associated with component tests
        link_defs = []
        each_link(aug_cmps) do |_cmp, link|
          link_defs << link
        end
        return ret if link_defs.empty?

        # get the link def links
        cols = [:id, :group_id, :display_name, :remote_component_type, :position, :content, :type, :link_def_id]
        link_def_links = LinkDef.get_link_def_links(link_defs.map(&:id_handle), cols: cols)
        # remove any link def link not associated with a test
        # first remove any link that is not internal (link on same compoennt)
        link_def_links.reject! { |ldl| ldl[:type] != 'internal' }
        return ret if link_def_links.empty?

        possible_test_cmp_types = link_def_links.map { |ldl| ldl[:remote_component_type] }.uniq
        ndx_test_cmps = get_ndx_test_components(project, possible_test_cmp_types)
        return ret if ndx_test_cmps.empty?

        # remove any element on link_def_links not associated with a test
        link_def_links.reject! { |ldl| ndx_test_cmps[ldl[:remote_component_type]].nil? }
        return ret if ndx_test_cmps.empty?

        [link_def_links, ndx_test_cmps]
      end

      def self.get_ndx_test_components(project, possible_test_cmp_types)
        ret = {}
        sp_hash = {
          cols: [:id, :group_id, :display_name, :attributes, :component_type, :external_ref, :module_branch_id],
          filter: [:and,
                   [:eq, :assembly_id, nil],
                   [:eq, :project_project_id, project.id],
                   [:oneof, :component_type, possible_test_cmp_types]]
          }
        Model.get_objs(project.model_handle(:component), sp_hash).each do |r|
          next unless TestExternalRefTypes.include?((r[:external_ref] || {})[:type])
          ndx = r[:component_type]
          cmp = ret[ndx] ||= r.hash_subset(:id, :group_id, :display_name, :component_type, :external_ref).merge(attributes: [])
          cmp[:attributes] << r[:attribute]
        end
        ret
      end
      TestExternalRefTypes = ['serverspec_test']

      def self.each_link(aug_cmps, &block)
        aug_cmps.each do |cmp|
          (cmp[:dependencies] || []).each do |dep|
            if dep.is_a?(::DTK::Dependency::Link)
              block.call(cmp, dep.link_def)
            end
          end
        end
      end
    end
  end
end
