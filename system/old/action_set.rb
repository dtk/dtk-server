#TBD: just starting point; will split into different files

#TBD: replace Globals ACTION_SET_DEFS .. with class variables
module XYZ
  module ActionSet
  end
  class ActionSet::Singleton
    #TBD: move so applies to all action sets
    #TBD: assuming that action is a view action and wil be display, edit, or list
    def self.process(object_name,action_name,js_action_ref,id_handle,href_prefix,http_opts)
      view_action =
        case action_name
          when :list
            ViewAction::ListObjects
          when :display
            ViewAction::ListObjects #TBD stub
          else
            raise ErrorNotImplemented.new() 
        end

      #TBD: canned
      ret_hash = {
        :jsConfig => {
          :dateDisplayFormat => "MM/dd/yy",
          :timeDisplayFormat => "HH:mm"
        },
        :actset_list => []
      }
      #TBD stubbed
      panel = http_opts[:action] == :display ? 'appBodyPanel' : 'leftColPanel'

      ret_hash[js_action_ref] = view_action.process(object_name,action_name,js_action_ref,panel,id_handle,href_prefix,http_opts)
      ret_hash[:actset_list] << js_action_ref
      print JSON.pretty_generate(ret_hash) << "\n"
      JSON.generate(ret_hash)
    end
  end

  class ActionSet::Top
    #TBD: not sure if should pass the raw http parameters in
    def self.dispatch_actions(c,http_uri,http_request,href_prefix,http_opts)
      #TBD: may put task at top level and then have sub tasks for parts
      #TBD: want to allow actions to be optionally threaded; not sure if helps
      #  to have instance methods that cache the returned values

      @actions.each{|a|a.dispatch(c,http_uri,http_request,href_prefix,http_opts)}
      ret = {}
      @view_actions.each{|va|
        uri = ret_param_value(va,:uri,http_uri,http_request,http_opts)
        opts = ret_param_value(va,:opts,http_uri,http_request,http_opts)
        result_array = va.get_template_vars(IDHandle[:c => c,:uri => uri],href_prefix,opts)

        #TBD: does not handle multiple instances of same action
	ret[va.ret_action_type()] = result_array
      }
      ret
    end

   private
    class << self
      def inherited(sub)
	#any of these can be overwritten
	sub.actions = []
        sub.view_actions = []
        sub.view_action_params = {}
      end
      def actions(*args)
	return nil if args.nil?
	args.each{|a|
	 a.to_s =~ %r{(^.+)::}
	 case $1
           when "XYZ::Action"
   	     @actions << a
           when "XYZ::ViewAction"
	     @view_actions << a
         end
        }
      end

      def params(view_action,p={})
        @view_action_params[view_action] = p
      end 

      def ret_param_value(action,param_type,http_uri,http_request,http_opts)
        ret = ret_param_value_nil_on_error(action,param_type,http_uri,http_request,http_opts)
        raise Error.new("Error obtaining parameter for #{action.to_s}") if ret.nil?
        ret
      end

      def ret_param_value_nil_on_error(action,param_type,http_uri,http_request,http_opts)
        return nil unless @view_action_params[action]
        return nil unless param_info = @view_action_params[action][param_type]
	case param_info[0]
          when :request
            raise Error.new("param type request needs element var") if param_info[1].nil?
            http_request[param_info[1]] 
          when :opts
            http_opts
	  when :constant
            raise Error.new("param type constant needs element var") if param_info[1].nil?
            param_info[1]
        end
      end

      attr_writer :actions,:view_actions, :view_action_params
    end
  end
end

module XYZ
  module Action
  end
  class Action::Top < HashObject
    def self.dispatch(c,uri,request,href_prefix,opts)
      raise Error.New("action dispatcher class (#{self.to_s})not properly set") if @object.nil? or @method.nil?
      task = Task.create(@is_asynchronous ? c : nil)
      params = ret_params(c,uri,request,href_prefix,opts)
      if false #TBD: stub @is_asynchronous
        #stub in call to gearman
        if true
	 Ramaze.defer{
	   begin
            params << {:task => task} #TBD: make sure tasks not added already
	    @object.send(@method,*params)
            task.update_status(:complete) 
           rescue Exception => err
	    task.add_error_toplevel(err) if err.kind_of?(Error)
	    task.update_status(:error)
          end
	}
        else
          Ramaze.defer{
            require 'gearman'
            servers = '10.5.5.9:4730'
	    client = Gearman::Client.new(servers.split(','), 'example')
	    gearman_taskset = Gearman::TaskSet.new(client)
	    payload_hash = {
	     :object => @object.to_s,
	     :method => @method.to_s,
             :params => params.map{|p|{:class => p.class.to_s, :val => p}}, #TBD: assumes no nested objects
	     :task => task  
            }
	    gearman_task = Gearman::Task.new('import_chef_recipes', JSON.generate(payload_hash))
            #TBD: since worker sets task state; may not be necessary to set
	    gearman_task.on_complete {|d| 
                print "complete: #{d.inspect}\n"
            }
	    gearman_task.on_fail do
                print "fail\n"
            end
	    gearman_taskset.add_task(gearman_task)
            #TBD: since worker sets task state; may not be necessary to set wait to non trivial amount
	    gearman_taskset.wait(600)
         }
        end
      else
        @object.send(@method,*params)
      end
    end
    def self.ret_action_type()
      Local.ret_action_type(self)
    end
   private
    class << self
      def ret_params(c,uri,href_prefix,opts)
        []
      end

      def inherited(sub)
        a = Local.ret_action_type(sub)
        sub.method = a # default that could be overwritten
      end  
      def method_name(method)
        @method = method
      end
      def object(obj)
        @object = obj
      end 
      def is_asynchronous
        @is_asynchronous = TRUE
      end

      attr_writer :method
    end
    module Local
      def self.ret_action_type(klass)
	Aux.underscore(Aux.demodulize(klass.to_s)).to_sym
      end
    end
  end
end

module XYZ
  module ViewAction
  end
  class ViewAction::Top < Action::Top 
    class << self 
      def process(object_name,action_name,js_action_ref,panel,id_handle,href_prefix,http_opts)
        opts = http_opts || {}
        opts[:depth] ||= :scalar_detail #allows explicit setting to override
        opts[:no_hrefs] = true

        tpl_callback = "render_#{object_name}_#{action_name}"

        r8_view = ViewR8.new(object_name,R8::I18N[object_name])
        r8_view.render(action_name)

        r8_tpl = R8Tpl::TemplateR8ForAction.new(tpl_callback,r8_view.css_require,r8_view.js_require)
        vars = get_template_vars(id_handle,href_prefix,opts)
	#TBD: stubbed
        params = action_params = nil
        case action_name
          when :list
            params = vars
            action_params = ("#{object_name}_list").to_sym
          when :display
            params = vars[0]
            action_params = object_name.to_sym
          else
            raise ErrorNotImplemented.new() 
          end

        r8_tpl.assign(action_params,params)
        r8_tpl.panel_set_element_id = panel
        r8_tpl.assign(:listStartPrev, 0)
        r8_tpl.assign(:listStartNext, 0)
        r8_tpl.render(r8_view.tpl_contents)
        r8_tpl.ret_result_array()
      end
     private
      def get_template_vars(id_handle,href_prefix,opts)
         hash = Object.get_instance_or_factory(id_handle,href_prefix,opts)
         hash ? hash.map{|k,v|v} : [] 
       end
    end
  end
end


#TBD: deprecate
module XYZ
  class ResultsArray < Hash
    #fields
    #  :content
    #  :data
    #  :views
    #  :script
    #  :script_includes
    #  :css_includes
    def self.[](x)
      new(x)
    end
    def initialize(x)
      super()
      replace(x)
    end
  end
end
