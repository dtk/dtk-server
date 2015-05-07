module DTK; class Target
  class IAASProperties
    class Ec2 < self
      def initialize(hash_args,provider=nil)
        super(hash_args)
        if provider
          @provider = provider
          #sanitizing what goes in provider_iaas_props, which is used for cloning targets
          @provider_iaas_props = (provider.get_field?(:iaas_properties)||{}).reject{|k,v|[:key,:secret].include?(k)}
        end
      end

      # returns an array of IAASProperties::Ec2 objects
      def self.check_and_compute_needed_iaas_properties(target_name,ec2_type,provider,property_hash)
        ret = Array.new
        iaas_property_factory = new({:name => target_name},provider)
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
        iaas_properties = clone_and_check_manditory_params(target_property_hash)
        iaas_properties = {:ec2_type => ec2_type}.merge(iaas_properties)
        name = name()
        if az = params[:availability_zone]
          name = availbility_zone_target_name(name,az)
          iaas_properties = {:availability_zone => az}.merge(iaas_properties)
        end
        self.class.new(:name => name,:iaas_properties => iaas_properties)
      end

      def self.equal?(i2)
        i2.type == :ec2 and
          iaas_properties[:region] == i2.iaas_properties[:region]
      end

     private

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
        # using @provider[:iaas_properties] because has credentials)
        unless props_with_creds = @provider[:iaas_properties]
          Log.error("Unexpected that @provider[:iaas_properties] is nil")
          return ret
        end
        props_with_creds = props_with_creds.merge(target_property_hash)
        self.class.check(:ec2,props_with_creds,:properties_to_check => PropertiesToCheck)

        ret
      end
      PropertiesToCheck = [:subnet] #TODO: will add more properties to check


      def self.modify_for_print_form!(iaas_properties)
        if iaas_properties[:security_group_set]
          iaas_properties[:security_group] ||= iaas_properties[:security_group_set].join(',')
        end
        iaas_properties
      end

      def self.sanitize!(iaas_properties)
        iaas_properties.reject!{|k,v|not SanitizedProperties.include?(k)}
      end
      SanitizedProperties = [:region,:keypair,:security_group,:security_group_set,:subnet,:ec2_type,:availability_zone]

      def self.more_specific_type?(iaas_properties)
        ec2_type = iaas_properties[:ec2_type]
        case ec2_type && ec2_type.to_sym
          when :ec2_vpc then :ec2_vpc
        end
      end

    end
  end
end; end