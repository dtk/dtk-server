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

       node_list = get_objects(:node,field_set,where_clause)

       #need way to be able to define the view template to be used with complex path
       #right now all things are "components" when it comes to rendering to page, even nodes

      #ultimately will be very handy to have node_list and all complex vars/hashes in templates to have
      #ur functionality where if undefined it just returns '' instead of error/warning
      action_name = :list #TBD: automatically determine this
      view = create_and_render_view(action_name)
      tpl = create_template_for_action(view,action_name)

#this can probably be cleaned up.., dont need case b/c context is provided by route
        action_params = ("#{object_name}_list").to_sym

#not quite sure what was happening here, but assign should always be name=>value assignments
        tpl.assign(action_params,node_list)
        tpl.assign(:listStartPrev, 0)
        tpl.assign(:listStartNext, 0)
#        tpl.panel_set_element_id = panel

#can probably evolve things to just return results from render, no explicit ret_results_array needed probably
        testing_js_templating_on = false
        if testing_js_templating_on
          tpl.render(view.tpl_contents,testing_js_templating_on)
          tpl.ret_result_array()
        else
          tpl.render(view.tpl_contents,testing_js_templating_on)
        end

#these should automatically add the appropriate js/css file(s) to the response
 #     js_include('component.r8')
  #    css_include('basic-component')

      #some utility function(s) to deal with object and app strings
      #should probably take some params for view specific strings, else fall back on default
   #   obj_i18n = get_object_i18n()

    end
  end
end

