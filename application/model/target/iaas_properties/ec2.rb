module DTK; class Target
  class IAASProperties
    class Ec2 < self
      def initialize(hash_args,provider_iaas_props=nil)
        super(hash_args)
        @provider_iaas_props = provider_iaas_props
      end
      
      # returns an array of IAASProperties::Ec2 objects
      def self.compute_needed_iaas_properties(target_name,ec2_type,provider,property_hash)
        ret = Array.new
        iaas_property_factory = create_factory(target_name,provider)
        ret << iaas_property_factory.create_target_propeties(ec2_type,property_hash)
        region = property_hash[:region]
        if Ec2TypesNeedingAZTargets.include?(ec2_type)
          # TODO: when have nested targets will nest availability zone targets in the one justa ssociarted with region
          # add iaas_properties for targets created separately for every availability zone
          provider.get_availability_zones(region).each do |az|
            ret << iaas_property_factory.create_target_propeties(ec2_type,property_hash,:availability_zone => az)
          end
        end
        ret
      end
      Ec2TypesNeedingAZTargets = [:ec2_classic]

      def create_target_propeties(ec2_type,target_property_hash,params={})
        name = name()
        if az = params[:availability_zone]
          name = availbility_zone_target_name(name,az)
        end
        iaas_properties = clone_and_check_manditory_params(target_property_hash)
        self.class.new(:name => name,:iaas_properties => {:ec2_type => ec2_type}.merge(iaas_properties))
      end

      def self.equal?(i2)
        i2.type == :ec2 and
          iaas_properties[:region] == i2.iaas_properties[:region]
      end

     private
      def self.create_factory(target_name,provider)
        provider_iaas_props = provider.get_field?(:iaas_properties).reject{|k,v|[:key,:secret].include?(k)}
        new({:name => target_name},provider_iaas_props)
      end


      def availbility_zone_target_name(name,availbility_zone)
        "#{name}-#{availbility_zone}"
      end

      def clone_and_check_manditory_params(target_property_hash)
        ret = target_property_hash
        unless target_property_hash[:keypair]
          if keypair = @provider_iaas_props[:keypair]
            ret = ret.merge(:keypair => keypair)
          else
            raise ErrorUsage.new("The target and its parent provider are both missing a keypair")
          end
        end

        unless target_property_hash[:security_group] or target_property_hash[:security_group_set]
          if security_group = @provider_iaas_props[:security_group]
            ret = ret.merge(:security_group => security_group)
          elsif security_group_set = @provider_iaas_props[:security_group_set]
            ret = ret.merge(:security_group_set => security_group_set)
          else
            raise ErrorUsage.new("The target and its parent provider are both missing any security groups")
          end
        end
        ret
      end

      def self.sanitize_type!(iaas_properties)
        iaas_properties.reject!{|k,v|not SanitizedProperties.include?(k)}
      end
      SanitizedProperties = [:region,:keypair,:security_group,:security_group_set,:subnet_id]
    end
  end
end; end
