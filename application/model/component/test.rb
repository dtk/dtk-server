module DTK
  class Component
    class Test < self

      class ComponentLinkedTests
        attr_reader :component,:test_array
        def initialize(cmp,test_array=[])
          @component = cmp
          @test_array = test_array
        end
        def add_test(test)
          @test_array << test
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
        #first find all components with a link def; get the component id and then get info about these to see if test
        linked_cmp_ids = Array.new
        cmp_with_linked_tests = Array.new
        each_link(aug_cmps) do |cmp,link|
          #TODO: wrong; does not return other side of link def
          linked_cmp_ids << link[:component_component_id]
        end
        return ret if linked_cmp_ids.empty?

        sp_hash = {
          :cols => [:id,:group_id,:display_name,:external_ref,:type],
          :filter => [:oneof,:id,linked_cmp_ids]
        }
        cmp_mh = assembly_instance.model_handle(:component)
        linked_cmp_tests = get_objs(cmp_mh,sp_hash).select{|r|isa_component_test?(r)}
pp linked_cmp_tests
raise Error.new('got here')
        return ret if linked_cmp_tests.empty?
        
        ndx_linked_cmp_tests = linked_cmp_tests.inject(Hash.new){|h,r|h.merge(r[:id] => r)}
        each_link(aug_cmps) do |cmp,link|
        end
        ret
      end

      private
      def self.isa_component_test?(obj)
        return true if obj.kind_of?(Component::Test)
        if obj.kind_of?(Component)
          pp self
          true
        end
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
