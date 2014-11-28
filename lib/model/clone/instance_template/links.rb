module DTK; class Clone
  module InstanceTemplate
    class Links < Array
#TODO:       def initialize(opts={})
      def initialize(opts)
        super()
        if opts[:parent_model_name]
          @parent_model_name = opts[:parent_model_name]
        end
      end

      def add(instance,template)
        self << Link.new(instance,template)
      end

      def parent_rels(child_mh)
        parent_id_col = child_mh.parent_id_field_name()
        map{|link|{parent_id_col => link.instance.id, :old_par_id => link.template.id}}
      end

      def field_set()
        return @field_set if @field_set
        model_handle = model_handle()
        parent_id_col = model_handle.parent_id_field_name()
        remove_cols = [:id,:local_id,parent_id_col]
        concrete_model_name = Model.concrete_model_name(model_handle[:model_name])
        @field_set = Model::FieldSet.all_real(concrete_model_name).with_removed_cols(*remove_cols)
      end

      def model_handle()
        return @model_handle if @model_handle 
        unless link = first 
          raise Error.new("This method should not be called when no links")
        end

        # isntance and template have same model handle
        @model_handle = link.instance.model_handle()
        if @parent_model_name
         @model_handle[:parent_model_name] ||= @parent_model_name 
        end
        @model_handle
      end

      def get_templates_with_cols(cols)
        templates = templates()
        return templates if templates.empty?()
        # all elements in templates will have same cols
        cols_to_get = cols - templates.first.keys
        return templates if cols_to_get.empty?
        ndx_templates = templates.inject(Hash.new){|h,r|h.merge(r[:id] => r)}
        # templates.first.keys will have id in it, so cols_to_get wont and we need to add in so we can merge
        sp_hash = {
          :cols => cols_to_get +[:id],
          :filter => [:oneof, :id, ndx_templates.keys]
        }
        mh = templates.first.model_handle()
        Model.get_objs(mh,sp_hash).each do |r|
          ndx_templates[r[:id]].merge!(r)
        end
        ndx_templates.values
      end
        
      def template(instance)
        match = match_instance(instance)
        match[:template] || raise(Error.new("Cannot find matching template for instance (#{instance.inspect})"))
      end

      def match_instance(instance)
        instance_id = instance.id
        unless match = find{|l|l.instance and l.instance.id == instance_id}
          raise(Error.new("Cannot find match for instance (#{instance.inspect})"))
        end
        match
      end

      def all_id_handles()
        templates().map{|r|r.id_handle()} + instances().map{|r|r.id_handle()}
      end
      
      def templates()
        #removes dups
        inject(Hash.new) do |h,l|
          template = l.template
          h.merge(template ? {template.id => template} : {})
        end.values
      end
     
      def instances()
        #does not have dups
        map{|l|l.instance}.compact
      end
    end
  end
end; end
