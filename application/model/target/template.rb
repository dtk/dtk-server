module DTK
  #This is a provider
  class Target
    class Template < self

      def self.list(target_mh,opts={})
        sp_hash = {
          :cols => common_columns(),
          :filter => [:eq,:type,'template']
        }
        get_objs(target_mh, sp_hash.merge(opts))
      end

      def self.get(target_mh, id)
        target = super(target_mh, id)
        raise ErrorUsage.new("Target with ID '#{id}' is not a template") unless target.is_template?
        target
      end

      def self.create_provider(project_idh, display_name, params_hash)
        # check iaas type
        supported_types = R8::Config[:ec2][:iaas_type][:supported]
        unless supported_types.include?(params_hash[:iaas_type].downcase)
          raise ErrorUsage.new("Invalid iaas type '#{params_hash[:iaas_type]}', supported types (#{supported_types.join(', ')})") 
        end
        # we first check if we are ok with aws credentials
        params_hash[:iaas_properties] = CommandAndControl.prepare_account_for_target(params_hash[:iaas_type].to_s,params_hash[:iaas_properties])
        
        target_mh = project_idh.createMH(:target)
        display_name = "#{display_name}-template" 
        ref = display_name.downcase.gsub(/ /,"-")
        row = {:type => 'template', :ref => ref, :display_name => display_name}.merge(params_hash)
        create_from_row(target_mh,row,:convert => true) 
      end
    end
  end
end
