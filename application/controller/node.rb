module XYZ
  class NodeController < Controller

    def list
      error_405 unless request.get?


#this will ultimately be pushed to some higher level that will probably be handled by the field sets for
#the views
#if empty, or not available, will fall back to default, else then to full model rep
#still good to be able to pass in optionally
      field_set = [
        :id,
        :display_name,
        :description,
        :type,
        :os,
        :image_size,
        :disk_size,
        :data_source,
        :parent_id,
        :parent_path
      ]   
      where_clause = {} # stub

      #ultimately will be very handy to have node_list and all complex vars/hashes in templates to have
      #ur functionality where if undefined it just returns '' instead of error/warning
       node_list = get_objects(:node,field_set,where_clause)

       #need way to be able to define the view template to be used with complex path
       #right now all things are "components" when it comes to rendering to page, even nodes
        set_template_var(:node_list,node_list)

        action_name = "list" #TBD: automatically determine this
        #set view automatically called when controller object created; should this 
        #necessarily done
        
        return render_template("node/basic_node")

      #this call makes sure the latest view is rendered/up-to-date,but can probably clean things up so 
      #behavior happens behind the scenes
        r8_view.render(action_name)

        r8_tpl = R8Tpl::TemplateR8ForAction.new(tpl_callback,r8_view.css_require,r8_view.js_require)

#this can probably be cleaned up.., dont need case b/c context is provided by route
        action_params = ("#{object_name}_list").to_sym

#not quite sure what was happening here, but assign should always be name=>value assignments
        r8_tpl.assign(action_params,node_list)

        r8_tpl.panel_set_element_id = panel
        r8_tpl.assign(:listStartPrev, 0)
        r8_tpl.assign(:listStartNext, 0)
#can probably evolve things to just return results from render, no explicit ret_results_array needed probably
        r8_tpl.render(r8_view.tpl_contents)
        r8_tpl.ret_result_array()

#      return render_template("node/basic_node")

#these should automatically add the appropriate js/css file(s) to the response
 #     js_include('component.r8')
  #    css_include('basic-component')

      #some utility function(s) to deal with object and app strings
      #should probably take some params for view specific strings, else fall back on default
   #   obj_i18n = get_object_i18n()

    end
  end
end

