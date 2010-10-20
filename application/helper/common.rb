module Ramaze::Helper
  module Common
    include XYZ #TODO: included because of ModelHandle amd Model; make sure not expensive to laod these defs in this module
   private
    #helpers that interact with model
    def get_objects(model_name,where_clause={},opts={})
      c = ret_session_context_id()
      model_class(model_name).get_objects(ModelHandle.new(c,model_name),where_clause,opts)
    end

    def get_object_by_id(id)
      get_objects(model_name,{:id => id}).first
    end

    def update_from_hash(id,hash)
      opts = Hash.new
      model_class(model_name).update_from_hash_assignments(id_handle(id),Aux.ret_hash_assignments(hash),opts)
    end

    def create_from_hash(parent_id_handle,hash)
      new_id = Model.create_from_hash(parent_id_handle,hash).map{|x|x[:id]}.first
      Log.info("created new object with id #{new_id}") if new_id
      new_id
    end

    def id_handle(id,i_model_name=model_name())
      c = ret_session_context_id()
      IDHandle.new({:c => c,:guid => id.to_i, :model_name => i_model_name.to_sym},{:set_parent_model_name => true})
    end

    def top_id_handle()
      c = ret_session_context_id()
      IDHandle[:c => c,:uri => "/"]
    end

    def ret_id_from_uri(uri)
      c = ret_session_context_id()
      IDHandle[:c => c, :uri => uri].get_id()
    end

    #request parsing fns
    def ret_order_by_list()
      return nil unless request_method_is_post?()
      JSON.parse(request.params["query_params"])["order_by"] if request.params["query_params"] and not request.params["query_params"].empty?
    end

    def request_method_is_get?()
      request.env["REQUEST_METHOD"] == "GET"
    end
    def request_method_is_post?()
      request.env["REQUEST_METHOD"] == "POST"
    end


    #R8 functions
    def set_template_defaults_for_list!(tpl)
      tpl.assign(:list_start_prev, 0)
      tpl.assign(:list_start_next, 0)
      tpl.assign(:search_content, nil)
      tpl.assign(:_app,app_common())
      set_template_order_columns!(tpl)
    end
    
    def set_template_order_columns!(tpl,order_by_list=nil,field_set=Model::FieldSet.default(model_name()))

      order_by_hash = (order_by_list||[]).inject({}){|h,o|h.merge(o["field"] => o["order"])}
      field_set.cols.each do |field|
        sort_order = 'ASC'
        ort_class = ''
        if order_by_hash[field]
          sort_order = 'DESC' if order_by_hash[field]== 'ASC'  
          sort_class = (order_by_hash[field]== 'ASC') ? 'asc' : 'desc'
        end

        tpl.assign((field.to_s+'_order').to_sym,sort_order)
        tpl.assign((field.to_s+'_order_class').to_sym,sort_class)
      end
    end


    def app_common()
      {
        :base_uri => R8::Config[:base_uri],
        :base_css_uri => R8::Config[:base_css_uri],
        :base_js_uri => R8::Config[:base_js_uri],
        :base_images_uri => R8::Config[:base_images_uri],
      }
    end

    #aux fns 
    def model_class(model_name_x=model_name())
      Model.model_class(model_name_x)
    end

   def default_action_name
     this_parent_method.to_sym
   end

   def model_name
      @model_name ||= Aux.demodulize(self.class.to_s).gsub(/Controller$/,"").downcase.to_sym
   end
  end
end

