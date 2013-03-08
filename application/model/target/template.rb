module DTK
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
        return target
      end

      def self.create_from_user_input(project_idh, display_name, params_hash,default_create=false)
        target_mh = project_idh.createMH(:target)
        display_name = "#{display_name}-template" if default_create  
        ref = display_name.downcase.gsub(/ /,"-")
        row = {:type => 'template'}.merge(:ref => ref, :display_name => display_name).merge(params_hash)
        return create_from_row(target_mh,row,:convert => true) 
      end

    end
  end
end
