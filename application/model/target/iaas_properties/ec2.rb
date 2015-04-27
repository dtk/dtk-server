module DTK; class Target
  class IAASProperties
    class Ec2 < self
      def initialize(hash_args,provider_iaas_props=nil)
        super(hash_args)
        @provider_iaas_props = provider_iaas_props
      end
      
      def self.create_factory(target_name,provider)
        provider_iaas_props = provider.get_field?(:iaas_properties).reject{|k,v|[:key,:secret].include?(k)}
        new({:name => target_name},provider_iaas_props)
      end

      def create_target_propeties(target_iaas_props,params={})
pp @provider_iaas_props
        name = target_iaas_props[:name] || @provider_iaas_props[:name]
        if az = params[:availability_zone]
          name = availbility_zone_target_name(name,az)
        end
        iaas_properties = clone_and_check_manditory_params(target_iaas_props)
ret =         self.class.new(:name => name,:iaas_properties => iaas_properties)
pp ret
ret
      end

      def self.equal?(i2)
        i2.type == :ec2 and
          iaas_properties[:region] == i2.iaas_properties[:region]
      end


     private
      def availbility_zone_target_name(name,availbility_zone)
        "#{name}-#{availbility_zone}"
      end

      def clone_and_check_manditory_params(target_iaas_props)
        ret = target_iaas_props
        unless target_iaas_props[:keypair]
          if keypair = @provider_iaas_props[:keypair]
            ret = ret.merge(:keypair => keypair)
          else
            raise ErrorUsage.new("The target and its parent provider are both missing a specfied keypair")
          end
        end

        unless target_iaas_props[:security_group] or target_iaas_props[:security_group_set]
          if security_group = @provider_iaas_props[:security_group]
            ret = ret.merge(:security_group => security_group)
          elsif security_group_set = @provider_iaas_props[:security_group_set]
            ret = ret.merge(:security_group_set => security_group_set)
          else
            raise ErrorUsage.new("The target and its parent provider are both missing a specfied security group(s)")
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
