module DTK
  class Component
    class Test < self

      class LinkedTest
        attr_reader :test_component, :attribute_mappings
        def initialize(test_component,ams)
          @test_component = test_component
          @attribute_mappings = ams
        end
      end
      class LinkedTests
        attr_reader :component,:test_array
        def initialize(cmp,test_array=[])
          @component = cmp.hash_subset(:id,:display_name)
          @test_array = test_array
        end
        def add_test!(test_component,ams)
          @test_array << LinkedTest.new(test_component,ams)
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
Example of dependency info per component
 {:id=>2147536484,
  :display_name=>"mongodb",
  :component_type=>"mongodb",
  :basic_type=>"service",
  :extended_base=>nil,
  :description=>nil,
  :version=>"master",
  :module_branch_id=>2147494462,
  :node_node_id=>2147536478,
  :assembly_id=>2147536477,
  :node=>
   {:id=>2147536478,
    :display_name=>"node1",
    :os_type=>"ubuntu",
    :admin_op_status=>"running",
    :external_ref=>
     {:image_id=>"ami-fce20e94",
      :type=>"ec2_instance",
      :size=>"m1.small",
      :instance_id=>"i-ecc2e7bc",
      :ec2_public_address=>"ec2-54-221-142-70.compute-1.amazonaws.com",
      :dns_name=>"ec2-54-221-142-70.compute-1.amazonaws.com",
      :private_dns_name=>
       {:"ec2-54-221-142-70.compute-1.amazonaws.com"=>
         "ip-10-167-151-11.ec2.internal"}}},
  :dependencies=>
   [#<XYZ::Dependency::Link:0x00000008b0d2d8
     @link_def=
      {:id=>2147536491,
       :group_id=>2147484431,
       :display_name=>"local_mongodb_test::network_port_check",
       :description=>nil,
       :local_or_remote=>"local",
       :link_type=>"mongodb_test::network_port_check",
       :required=>false,
       :dangling=>false,
       :has_external_link=>true,
       :has_internal_link=>true,
       :component_component_id=>2147536484},
     @satisfied_by_component_ids=[]>]}]
=end
