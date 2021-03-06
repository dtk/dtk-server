#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# TODO: needs cleanup including around mechanism to get object associated with ids
module Ramaze::Helper
  module Common
    require_relative('common/request_params')
    include RequestParams
    include DTK

    def raise_error_usage(msg)
       raise ::DTK::ErrorUsage, msg
    end

    def raise_error(msg)
       raise ::DTK::Error, msg
    end

    # TODO: move request param methods to common/request_params, depreacting ones no longer used

    def create_object_from_id(id, model_name_or_class = nil, opts = {})
      model_name  =
        if model_name_or_class.nil? then model_name()
        elsif model_name_or_class.is_a?(Symbol) then model_name_or_class
        else #it is a model class
          ret_module_name_from_class(model_name_or_class)
        end
      id_handle(id, model_name).create_object(opts.merge(controller_class: self.class))
    end

    def user_object
      ret = user
      if ret.class.nil?
        if R8::Config[:development_test_user]
          c = ret_session_context_id()
          ret = @test_user ||= User.get_user(ModelHandle.new(c, :user), R8::Config[:development_test_user])
        end
        return nil
      end
      ret
    end

    def default_namespace
      # CurrentSession.new().get_user_object().get_namespace()
      # we don't want username as default namespace, we will use tenant unique name instead
      Common::Aux.running_process_user()
    end

    def model_handle(model_name_x = model_name())
      user_obj = user_object()
      ModelHandle.create_from_user(user_obj, model_name_x)
    end

    def model_handle_with_private_group(model_name_x = model_name())
      user_obj = user_object()
      ret = ModelHandle.create_from_user(user_obj, model_name_x)
      group_obj = UserGroup.get_private_group(ret.createMH(:user_group), user_obj[:username])
      ret.merge(group_id: group_obj[:id])
    end

    # looks for default if no target is given
    def target_with_default(target_id = nil)
      target = target_id ?
      id_handle(target_id, :target).create_object(model_name: :target_instance) :
        Target::Instance.get_default_target(model_handle(:target), ret_singleton_target: true, prune_builtin_target: true)

      if target
        target
      else
        target_option, set_default_target = ['--context CONTEXT', 'dtk service set-default-context SERVICE-NAME']
        fail DTK::ErrorUsage, "The command was called without '#{target_option}' option and no default context has been set. You can set default context with service instance command '#{set_default_target}'"
      end
    end

    def default_target
      target_with_default
    end

    def get_default_project
      projects = ::DTK::Project.get_all(model_handle(:project))
      if projects.empty?
        fail DTK::Error.new('Cannot find any projects')
      elsif projects.size > 1
        fail DTK::Error.new('Not implemented yet: case when multiple projects')
      end
      projects.first
    end

    private

    # helpers that interact with model
    def get_objects(model_name, where_clause = {}, opts = {})
      model_name = :datacenter if model_name == :target  #TODO: remove temp datacenter->target
      model_class(model_name).get_objects(model_handle(model_name), where_clause, opts)
    end

    def get_object_by_id(id, model_name_x = model_name())
      get_objects(model_name_x, id: id).first
    end

    def update_from_hash(id, hash, opts = {})
      idh = id_handle(id, model_name, hash['display_name'])
      model_class(model_name).update_from_hash_assignments(idh, Aux.col_refs_to_keys(hash), opts)
    end

    def create_from_hash(parent_id_handle, hash)
      new_id = model_class(model_name).create_from_hash(parent_id_handle, hash).map { |x| x[:id] }.first
      Log.info("created new object with id #{new_id}") if new_id
      new_id
    end

    def delete_instance(id)
      c = ret_session_context_id()
      Model.delete_instance(IDHandle[c: c, id: id, model_name: model_name()])
    end

    def id_handle(id, i_model_name = model_name(), display_name = nil)
      model_name = :datacenter if model_name == :target  #TODO: remove temp datacenter->target
      c = ret_session_context_id()
      hash = { c: c, guid: id.to_i, model_name: i_model_name.to_sym }
      hash.merge!(display_name: display_name) if display_name
      idh = IDHandle.new(hash, set_parent_model_name: true)
      obj = idh.create_object().update_object!(:group_id)
      idh.merge!(group_id: obj[:group_id]) if obj[:group_id]
      idh
    end

    def top_level_factory_id_handle
      c = ret_session_context_id()
      IDHandle[c: c, uri: "/#{model_name()}", is_factory: true]
    end

    def top_id_handle(opts = {})
      c = ret_session_context_id()
      idh = IDHandle[c: c, uri: '/']
      idh.merge!(group_id: opts[:group_id]) if opts[:group_id]
      idh
    end

    def ret_id_from_uri(uri)
      c = ret_session_context_id()
      IDHandle[c: c, uri: uri].get_id()
    end

    # request parsing fns
    # TODO: may deprecat; befoe so would have to remove from call in some list views in display
    def ret_where_clause(field_set = Model::FieldSet.all_real(model_name()))
      hash = ret_hash_for_where_clause()
      hash ? field_set.ret_where_clause_for_search_string(hash.reject { |k, _v| k == :parent_id }) : nil
    end

    def ret_parent_id
      (ret_hash_for_where_clause() || {})[:parent_id]
    end

    def ret_order_by_list
      # TODO: handle case when this is a get
      # TODO: filter fields to make sure real fields or treat virtual columns
      saved_search = ret_saved_search_in_request()
      return nil unless (saved_search || {})['order_by']
      saved_search['order_by'].map { |x| { field: x['field'].to_sym, order: x['order'] } }
    end

    # TODO: just for testing
    TestOveride = 100 # nil
    LimitDefault = 20
    NumModelItemsDefault = 10000
    def ret_paging_info
      # TODO: case on request_method_is_post?()
      # TODO: might be taht query is optimzied by not having start being 0 included
      saved_search = ret_saved_search_in_request()
      # TODO: just for testing
      if TestOveride && (saved_search || {})['start'].nil?
        return { start: 0, limit: TestOveride, num_model_items: NumModelItemsDefault }
      end
      return nil unless saved_search
      return nil unless saved_search['start'] || saved_search['limit']
      start = (saved_search['start'] || 0).to_i
      limit = (saved_search['limit'] || R8::Config[:page_limit] || LimitDefault).to_i
      # TODO: just for testing
      limit = TestOveride if TestOveride
      num_model_items = (saved_search['num_model_items'] || NumModelItemsDefault)
      { start: start, limit: limit, num_model_items: num_model_items }
    end

    def ret_model_for_list_search(field_set)
      request_params = ret_request_params() || {}
      field_set.cols.inject({}) { |ret, field| ret.merge(field => request_params[field] || '') }
    end

    def ret_request_params_filter
      json_form = (ret_request_params() || {})['search']
      search = convert_search_item_from_json(json_form)
      search && check_and_convert_filter_form(search['filter'])
    end

    def ret_saved_search_in_request
      json_form = (ret_request_params() || {})['saved_search']
      convert_search_item_from_json(json_form)
    end

    def convert_search_item_from_json(item)
      unless item.nil? || item.empty?
        JSON.parse(item)
      end
    end

    def check_and_convert_filter_form(filter)
      ret = convert_filter_form(filter)
      fail ErrorUsage.new("Filter having form (#{filter.inspect}) not treated") if ret.nil?
      ret
    end

    def convert_filter_form(filter)
      if filter.is_a?(Array) && filter.size == 3
        if filter[0].to_sym == :eq && filter[2].to_s =~ /^[0-9]+$/
          [filter[0].to_sym, filter[1].to_sym, filter[2].to_i]
        end
      end
    end

    def ret_hash_for_where_clause
      request_method_is_get?() ? ret_parsed_query_string_when_get() : ret_request_params()
    end

    def ret_parsed_query_string_when_get
      explicit_qs = ret_parsed_query_string_from_uri()
      return @parsed_query_string if explicit_qs.nil? || explicit_qs.empty?
      return explicit_qs if @parsed_query_string.nil? || @parsed_query_string.empty?
      @parsed_query_string
    end

    # TODO: needs refinement
    def ret_parsed_query_string_from_uri
      ret = {}
      query_string = ret_query_string()
      return ret unless query_string
      # TBD: not yet looking for errors in the query string
      query_string.scan(%r{([/A-Za-z0-9_]+)=([/A-Za-z0-9_]+)}) do
        key = Regexp.last_match(1).to_sym
        value = Regexp.last_match(2)
        if value == 'true'
          ret[key] = true
        elsif value == 'false'
          ret[key] = false
        elsif value =~ /^[0-9]+$/
          ret[key] = value #should be converted into an integer
        else
          ret[key] = value
          # TODO: find where value shoudl be sym   ret[key] = value.to_sym
        end #TBD: not complete; for example not for decimals
      end
      ret
    end

    def ret_query_string
      request.env['QUERY_STRING']
    end

    # TODO: these three methods below need some cleanup
    # param refers to key that can have id or name value
    # If list of params finds first one with a value
    def create_obj(param_or_params, model_class = nil, extra_context = nil)
      params = param_or_params.kind_of?(Array) ? param_or_params : [param_or_params]
      param = 
        if params.size == 1
          params.first
        else
          param = params.find { |p| !request_params(p).nil? }
        end
      fail Error, "Illegal rest params" if param.nil?
      create_object_from_id(ret_request_param_id(param, model_class, extra_context), model_class)
    end

    # param refers to key that can have id or name value
    def ret_request_param_id_handle(param, model_class = nil, version = nil)
      id = ret_request_param_id(param, model_class, version)
      id_handle(id, ret_module_name_from_class(model_class))
    end

    def ret_id_handle_from_value(id_or_name_value, model_class = nil, extra_context = nil)
      id = resolve_id_from_name_or_id(id_or_name_value, model_class, extra_context)
      id_handle(id, ret_module_name_from_class(model_class))
    end
    # TODO: One part of cleanup is to have name_to_id and check_valid return the object with keys :id and :group id
    # we can put in an option flag for this, but need to check we cover all instances of these
    # make this a speacte function called by create_obj and then have
    # ret_request_param_id_handle and ret_request_param_id call id and id_handle methods on it
    # which avoids needing to call create_object_from_id in create_obj

    # param refers to key that can have id or name value
    def ret_request_param_id?(param, model_class = nil, extra_context = nil)
      if id_or_name = ret_request_params(param)
        resolve_id_from_name_or_id(id_or_name, model_class, extra_context)
      end
    end

    def numeric_id?(id_or_name)
      if id_or_name.is_a?(Fixnum)
        id_or_name
      elsif id_or_name.is_a?(String) and id_or_name =~ /^[0-9]+$/
        id_or_name.to_i
      end
    end

    def resolve_id_from_name_or_id(id_or_name, model_class = nil, extra_context = nil)
      model_name = ret_module_name_from_class(model_class)
      model_class ||= model_class(model_name)
      model_handle = model_handle(model_name)

      if id = numeric_id?(id_or_name)
        params = [model_handle, id]
        params << extra_context if extra_context
        model_class.check_valid_id(*params)
      else
        params = [model_handle, id_or_name]
        params << extra_context if extra_context
        model_class.name_to_id(*params)
      end
    end


    def ret_module_name_from_class(model_class = nil)
      if model_class
        ::DTK::Model::SubclassProcessing.model_name(model_class) || Aux.underscore(Aux.demodulize(model_class.to_s)).to_sym
      else
        model_name()
      end
    end
    private :ret_module_name_from_class

    def ret_request_params_force_nil(*params)
      ret = ret_request_params(params)
      ret = [*ret].collect { |v| v.empty? ? nil : v }
      ret.size <= 1 ? ret.first : ret
    end

    def ret_symbol_params_hash(*params)
      ret_params_hash(*params).inject({}) { |h, (k, v)| h.merge(k => v.to_s.to_sym) }
    end

    def ret_boolean_params_hash(*params)
      ret_params_hash(*params).inject({}) { |h, (k, v)| h.merge(k => boolean_form(v)) }
    end

    # method will use nil where param empty
    def ret_params_hash_with_nil(*params)
      ret = {}
      return ret unless request_method_is_post?()
      return ret if params.size == 0
      params.inject({}) do |h, p|
        val = request.params[p.to_s]
        val = nil if val.empty?
        (val ? h.merge(p.to_sym => val) : h)
      end
    end

    def ret_params_av_pairs
      pattern, value, av_pairs_hash = ret_request_params(:pattern, :value, :av_pairs_hash)
      ret = []
      if av_pairs_hash
        av_pairs_hash.each { |k, v| ret << { pattern: k, value: v } }
      elsif pattern
        ret = [{ pattern: pattern, value: value }]
      else
        fail ::DTK::ErrorUsage.new('Missing parameters')
      end
      ret
    end

    def node_binding_ruleset?(node_template_identifier_param, node_binding_identifier = nil)
      if node_binding_identifier ||= ret_request_params(node_template_identifier_param)
        model_handle = model_handle(:node_binding_ruleset)
        if node_binding_identifier.match(/^[0-9]+$/)
          node_binding_rs_id = NodeBindingRuleset.check_valid_id(model_handle, node_binding_identifier)
        else
          unless node_binding_rs_id = NodeBindingRuleset.name_to_id(model_handle, node_binding_identifier)
            fail ::DTK::ErrorUsage.new("Illegal node template indentifier (#{node_binding_identifier})")
          end
        end
        create_object_from_id(node_binding_rs_id, :node_binding_ruleset)
      end
    end

    def ret_component_template(param, opts = {})
      component_template, component_title = ret_component_template_and_title(param, opts)
      if component_title
        fail ::DTK::ErrorUsage.new('Component title should not be given')
      end
      component_template
    end
    # returns [component_template, component_title] where component_title could be nil
    def ret_component_template_and_title(param, opts = {})
      version = opts[:versions] || opts[:version]
      component_template_idh = ret_request_param_id_handle(param, ::DTK::Component::Template, version)
      component_template = component_template_idh.create_object(model_name: :component_template)
      component_title = ::DTK::ComponentTitle.parse_title?(ret_non_null_request_params(param))
      [component_template, component_title]
    end

    def ret_component_template_and_title_for_assembly(param, assembly)
      opts = { versions: [::DTK::ModuleVersion.ret(assembly), nil] } #so first tries the assembly module context and then the component module context
      ret_component_template_and_title(param, opts)
    end

    def ret_component_title?(component_name)
      ::DTK::ComponentTitle.parse_title?(component_name)
    end

    def raise_error_null_params?(*null_params)
      unless null_params.empty?
        error_msg = (null_params.size == 1 ? "Rest post parameter '#{null_params.first}' is missing" : "Rest post parameters #{null_params.join(',')} are missing")
        fail ErrorUsage.new(error_msg)
      end
    end

    def request_method_is_get?
      request.env['REQUEST_METHOD'] == 'GET'
    end

    def request_method_is_post?
      request.env['REQUEST_METHOD'] == 'POST'
    end

    # R8 functions
    def set_template_defaults_for_list!(tpl)
      tpl.assign(:list_start_prev, 0)
      tpl.assign(:list_start_next, 0)
      tpl.assign(:search_context, nil)
      tpl.assign(:search_content, nil)
      tpl.assign(:_app, app_common())
      set_template_order_columns!(tpl)
    end

    def set_template_paging_info!(tpl, paging_info)
      if paging_info.empty? || paging_info.nil?
        tpl.assign(:list_start_prev, 0)
        tpl.assign(:list_start_next, 0)
        return nil
      end
      start = paging_info[:start]; limit = paging_info[:limit]; num_model_items = paging_info[:num_model_items]
      start_prev = ((start - limit) < 0) ? 0 : (start - limit)
      tpl.assign(:list_start_prev, start_prev)
      start_next = ((start + limit) > num_model_items) ? nil : (start + limit)
      tpl.assign(:list_start_next, start_next)
    end

    def set_template_order_columns!(tpl, order_by_list = nil, field_set = Model::FieldSet.default(model_name()))
      # TODO: should default field set by default or all real
      order_by_hash = (order_by_list || []).inject({}) { |h, o| h.merge(o[:field] => o[:order]) }
      field_set.cols.each do |field|
        sort_order = 'ASC'
        ort_class = ''
        if order_by_hash[field]
          sort_order = 'DESC' if order_by_hash[field] == 'ASC'
          sort_class = (order_by_hash[field] == 'ASC') ? 'asc' : 'desc'
        end

        tpl.assign((field.to_s + '_order').to_sym, sort_order)
        tpl.assign((field.to_s + '_order_class').to_sym, sort_class)
      end
    end

    def app_common
      {
        base_uri: R8::Config[:base_uri],
        base_css_uri: R8::Config[:base_css_uri],
        base_js_uri: R8::Config[:base_js_uri],
        base_images_uri: R8::Config[:base_images_uri],
        avatar_base_uri: R8::Config[:avatar_base_uri]
      }
    end

    # aux fns
    def model_class(model_name_x = model_name())
      Model.model_class(model_name_x)
    end

   def default_action_name
     this_parent_method.to_sym
   end

   def model_name
     return @model_name if @model_name
     model_name_x = Aux.demodulize(self.class.to_s).gsub(/Controller$/, '').downcase.to_sym
     @model_name =  ConvertFromSubtypeModelName[model_name_x] || model_name_x
   end

   # TODO: unify with  model/subclass_processing
   ConvertFromSubtypeModelName = {
     assembly: :component,
     node_group: :node
   }
  end
end
