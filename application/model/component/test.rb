module DTK
  class Component
    class Test < self

      class LinkedTest
        attr_reader :var_mappings_hash
        def initialize(test_component,ams)
          @test_component = test_component
          @attribute_mappings = ams
          @var_mappings_hash = nil
        end
        def get_component_attributes()
          @attribute_mappings.map{|am|am_component_attr(am)}
        end
        def find_mapped_component_test_attributes(cmp_attrs)
          #This function flows the cmp_attribute values through component_To_test_attribute_mappings
          mappings = component_to_test_attribute_mappings()
          pp [:debug,:mappings,mappings]
          #code should go here that finds assignments to the test components
          return mappings
        end

       private
        def component_to_test_attribute_mappings()
          return @var_mappings_hash if @var_mappings_hash
          @var_mappings_hash = Hash.new
          @attribute_mappings.each do |am|
            index = am_component_attr(am)
            test_attr = am_test_attr(am)

            if existing_var = @var_mappings_hash[index]
              #TODO: just putting this in temporarily to check assumptions are right
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
        #For LinkedTest objects output corresponds to component and input to component test
        def am_component_attr(am)
          am[:output][:term_index]
        end
        def am_test_attr(am)
          am[:input][:term_index]
        end
      end

      class LinkedTests
        attr_reader :component,:test_array,:node
        def initialize(cmp,test_array=[])
          @node = {:id => cmp[:node][:id]}
          @component = cmp.hash_subset(:id,:display_name)
          @test_array = test_array
        end
        def add_test!(test_component,ams)
          @test_array << LinkedTest.new(test_component,ams)
        end

        def find_test_parameters()
          #find the relevant parameters on @test_component by looking at attribute mappings
          pp "debug: finding needed params for #{@component[:display_name]}"
          cmp_attribute_names = Array.new
          @test_array.each do |test|
            cmp_attribute_names += test.get_component_attributes()
          end
          cmp_attribute_names.uniq!
          pp "debug: cmp_attribute_names: #{cmp_attribute_names.inspect}"
          #Compute the component attribute vars that correspond to cmp_attribute_names
          cmp_attr_vals = nil
          find_mapped_component_test_attributes(cmp_attr_vals)
        end
       private
        def find_mapped_component_test_attributes(cmp_attr_vals)        
          @test_array.find{|test|test.find_mapped_component_test_attributes(cmp_attr_vals)}
        end
      end

      #returns array of ComponentLinkedTests
      def self.get_linked_tests(assembly_instance)
        ret = Array.new
        opts = Opts.new(
            :detail_to_include=>[:component_dependencies]
          )
        aug_cmps = assembly_instance.get_augmented_components(opts)
        #Find all dependencies (link defs) that point to a test
        #first find all link_defs and select ones that are associated with component tests
        link_defs = Array.new

        each_link(aug_cmps) do |cmp,link|
          link_defs << link
        end
        return ret if link_defs.empty?

        #get the link def links
        cols = [:id,:group_id,:display_name,:remote_component_type,:position,:content,:type,:link_def_id]
        link_def_links = LinkDef.get_link_def_links(link_defs.map{|ld|ld.id_handle()},:cols => cols)
        link_def_links.reject!{|ld_link|!isa_component_test_link?(ld_link)}
        return ret if link_def_links.empty?

        ndx_attribute_mappings = Hash.new
        link_def_links.each do |ld_link|
          am_list = ld_link.attribute_mappings()
          unless am_list.size == 1
            Log.error("Unexpected that test link has attribute_mappings wiith size <> 1")
            next
          end
          am = am_list.first
          pntr = ndx_attribute_mappings[ld_link[:link_def_id]] ||= {:test_component => ld_link[:remote_component_type], :ams => Array.new}
          pntr[:ams] << am
        end

        ndx_ret = Hash.new
        each_link(aug_cmps) do |cmp,link|
          cmp_id = cmp.id
          node_id = cmp[:node][:id]
          test_info = ndx_attribute_mappings[link[:id]]
          linked_tests = ndx_ret[cmp_id] ||= LinkedTests.new(cmp)
          linked_tests.add_test!(test_info[:test_component],test_info[:ams])
        end
        ndx_ret.values
      end

      private
      #TODO: stub
      def self.isa_component_test_link?(ld_link)
        ld_link.get_field?(:remote_component_type) =~ /^mongodb_test/
      end
      def self.each_link(aug_cmps,&block)
        aug_cmps.each do |cmp|
          (cmp[:dependencies]||[]).each do |dep|
            if dep.kind_of?(Dependency::Link)
              block.call(cmp,dep.link_def)
            end
          end
        end
      end
    end
  end
end
=begin
        dependency_components.each do |dep|
            #To Do....
          end
        #When I get corresponding attributes, I will merge them to their dependency component hash and then construct test component output with needed info as in the stub hash: ret[:test_instances]
        
        #Rich: will continue working on this; give example of what each eleemnt of aug_cmps looks like; of significance if there is a link def it will have something like
        #which then can be used to see if it is linked to any test component; if so will then have method that hgets what the linked values would be
        #nil causes the calling method to use teh stub values     
        nil
        end
    end
  end
end
=end
=begin
example of what LinkedTests looks like
[#<XYZ::Component::Test::LinkedTests:0x00000005efada8
   @component={:id=>2147536484, :display_name=>"mongodb"},
   @test_array=
    [#<XYZ::Component::Test::LinkedTest:0x00000005efa880
      @attribute_mappings=
       [{:output=>
          {:term_index=>"mongodb.port",
           :type=>"component_attribute",
           :component_type=>"mongodb",
           :attribute_name=>"port"},
         :input=>
          {:term_index=>"mongodb_test__network_port_check.mongo_port",
           :type=>"component_attribute",
           :component_type=>"mongodb_test__network_port_check",
           :attribute_name=>"mongo_port"}},
        {:output=>
          {:term_index=>"mongodb.port",
           :type=>"component_attribute",
           :component_type=>"mongodb",
           :attribute_name=>"port"},
         :input=>
          {:term_index=>"mongodb_test__network_port_check.mongo_port",
           :type=>"component_attribute",
           :component_type=>"mongodb_test__network_port_check",
           :attribute_name=>"mongo_port"}}],
      @test_component="mongodb_test__network_port_check">]>]]
"Components: {:test_instances=>[{:module_name=>\"mongodb\", :component
=end
