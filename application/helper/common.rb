module Ramaze::Helper
  module Common
    include XYZ #TODO: included because of ModelHandle amd Model; make sure not expensive to laod these defs in this module

    def create_object_from_id(id,model_name_x=model_name(),opts={})
      id_handle(id,model_name_x).create_object(opts)
    end      

    def user_object()
      ret = user
      if ret.class == nil
        if defined?(R8::EnvironmentConfig::TestUser)
          c = ret_session_context_id()
          ret = @test_user ||= XYZ::User.get_user(ModelHandle.new(c,:user),R8::EnvironmentConfig::TestUser)
        end
      end
      ret
    end
    def model_handle(model_name_x=model_name())
      user_obj = user_object()
      ModelHandle.create_from_user(user_obj,model_name_x)
    end
   private

    #helpers that interact with model
    def get_objects(model_name,where_clause={},opts={})
      model_name = :datacenter if model_name == :target  #TODO: remove temp datacenter->target
      model_class(model_name).get_objects(model_handle(model_name),where_clause,opts)
    end

    def get_object_by_id(id,model_name_x=model_name())
      get_objects(model_name_x,{:id => id}).first
    end

    def update_from_hash(id,hash,opts={})
      idh = id_handle(id,model_name,hash["display_name"])
      hash_assigns = Aux.col_refs_to_keys(hash)
      model_class(model_name).update_from_hash_assignments(idh,Aux.col_refs_to_keys(hash),opts)
    end

    def create_from_hash(parent_id_handle,hash)
      new_id = model_class(model_name).create_from_hash(parent_id_handle,hash).map{|x|x[:id]}.first
      Log.info("created new object with id #{new_id}") if new_id
      new_id
    end

    def delete_instance(id)
      c = ret_session_context_id()
      Model.delete_instance(IDHandle[:c => c, :id => id,:model_name => model_name()])
    end

    def id_handle(id,i_model_name=model_name(),display_name=nil)
      model_name = :datacenter if model_name == :target  #TODO: remove temp datacenter->target
      c = ret_session_context_id()
      hash = {:c => c,:guid => id.to_i, :model_name => i_model_name.to_sym}
      hash.merge!(:display_name => display_name) if display_name
      idh = IDHandle.new(hash,{:set_parent_model_name => true})
      obj = idh.create_object().update_object!(:group_id)
      idh.merge!(:group_id => obj[:group_id]) if obj[:group_id]
      idh
    end

    def top_level_factory_id_handle()
      c = ret_session_context_id()
      IDHandle[:c => c,:uri => "/#{model_name()}", :is_factory => true]
    end

    def top_id_handle(opts={})
      c = ret_session_context_id()
      idh = IDHandle[:c => c,:uri => "/"]
      idh.merge!(:group_id => opts[:group_id]) if opts[:group_id]
      idh
    end

    def ret_id_from_uri(uri)
      c = ret_session_context_id()
      IDHandle[:c => c, :uri => uri].get_id()
    end

    #request parsing fns
#TODO: may deprecat; befoe so would have to remove from call in some list views in display
    def ret_where_clause(field_set=Model::FieldSet.all_real(model_name()))
      hash = ret_hash_for_where_clause()
      hash ? field_set.ret_where_clause_for_search_string(hash.reject{|k,v|k == :parent_id}) : nil
    end

    def ret_parent_id()
      (ret_hash_for_where_clause()||{})[:parent_id]
    end

    def ret_order_by_list()
      #TODO: handle case when this is a get
      #TODO: filter fields to make sure real fields or treat virtual columns
      saved_search = ret_saved_search_in_request()
      return nil unless (saved_search||{})["order_by"]
      saved_search["order_by"].map{|x|{:field => x["field"].to_sym, :order => x["order"]}}
    end

#TODO: just for testing
TestOveride = 100# nil
    LimitDefault = 20
    NumModelItemsDefault = 10000
    def ret_paging_info()
      #TODO: case on request_method_is_post?()
      #TODO: might be taht query is optimzied by not having start being 0 included
      saved_search = ret_saved_search_in_request()
#TODO: just for testing
if TestOveride and (saved_search||{})["start"].nil?
  return {:start => 0, :limit => TestOveride, :num_model_items => NumModelItemsDefault}
end
      return nil unless saved_search
      return nil unless saved_search["start"] or saved_search["limit"]
      start = (saved_search["start"]||0).to_i
      limit = (saved_search["limit"] || R8::Config[:page_limit] || LimitDefault).to_i
#TODO: just for testing
limit = TestOveride if TestOveride 
      num_model_items = (saved_search["num_model_items"] || NumModelItemsDefault)
      {:start => start, :limit => limit, :num_model_items => num_model_items}
    end

    def ret_model_for_list_search(field_set)
      request_params = ret_request_params()||{}
      field_set.cols.inject({}){|ret,field|ret.merge(field => request_params[field]||'')}
    end

    def ret_saved_search_in_request()
      json_form = (ret_request_params()||{})["saved_search"]
      return nil if json_form.nil? or json_form.empty?
      #TODO: temp hack to convert from ' to " in query params
      JSON.parse(json_form.gsub(/'/,'"'))
    end


    def ret_hash_for_where_clause()
      request_method_is_get?() ? ret_parsed_query_string_when_get() : ret_request_params()
    end

    def ret_parsed_query_string_when_get()
      explicit_qs = ret_parsed_query_string_from_uri()
      return @parsed_query_string if explicit_qs.nil? or explicit_qs.empty?
      return explicit_qs if @parsed_query_string.nil? or @parsed_query_string.empty?
      @parsed_query_string 
    end


    #TODO needs refinement
    def ret_parsed_query_string_from_uri()
      ret = Hash.new
      query_string = ret_query_string()
      return ret unless query_string
      #TBD: not yet looking for errors in the query string
      query_string.scan(%r{([/A-Za-z0-9_]+)=([/A-Za-z0-9_]+)}) do
        key = $1.to_sym
        value = $2
        if value == "true" 
          ret[key] = true
        elsif value == "false"
          ret[key] = false
        elsif value =~ /^[0-9]+$/
          ret[key] = value #should be converted into an integer
        else
          ret[key] = value
       #TODO find where value shoudl be sym   ret[key] = value.to_sym
        end #TBD: not complete; for example not for decimals
      end
      ret
    end

    def ret_query_string()
      request.env["QUERY_STRING"]
    end

    def ret_request_params()
      return nil unless request_method_is_post?()
      return request.params
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
      tpl.assign(:search_context, nil)
      tpl.assign(:search_content, nil)
      tpl.assign(:_app,app_common())
      set_template_order_columns!(tpl)
    end

    def set_template_paging_info!(tpl,paging_info)
      if paging_info.empty? or paging_info.nil?
        tpl.assign(:list_start_prev, 0)
        tpl.assign(:list_start_next, 0)
        return nil
      end
      start = paging_info[:start]; limit = paging_info[:limit]; num_model_items = paging_info[:num_model_items] 
      start_prev = ((start - limit) < 0) ? 0 : (start-limit)
      tpl.assign(:list_start_prev, start_prev)
      start_next = ((start + limit) > num_model_items) ? nil : (start+limit)
      tpl.assign(:list_start_next, start_next)
    end

    def set_template_order_columns!(tpl,order_by_list=nil,field_set=Model::FieldSet.default(model_name()))
      #TODO: should default field set by default or all real
      order_by_hash = (order_by_list||[]).inject({}){|h,o|h.merge(o[:field] => o[:order])}
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
        :avatar_base_uri => R8::Config[:avatar_base_uri]
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
     return @model_name if @model_name
     model_name_x = Aux.demodulize(self.class.to_s).gsub(/Controller$/,"").downcase.to_sym
     @model_name =  ConvertFromSubtypeModelName[model_name_x]||model_name_x
   end

   #TODO: unify with  SubClassRelations in system/model
   ConvertFromSubtypeModelName = {
     :assembly => :component
   }
  end
end

