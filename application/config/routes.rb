
#TODO: figure out how to use routing to select/define specific templates
#      and action_set's to be used for a given route

module R8
  Routes = XYZ::HashObject.create_with_auto_vivification()
end
=begin
#alias and action set should not be defined together
#if template not set, should be default at higher level based on user profile
#template should be simple name, higher level will 
#action_set
  If panel_id not set, and panel not explicitly set inside ctrlr action, should default to main_body
routes[:model][:action] = {
  :template => 'tplname',
  :alias => 'some_alternate/route',
  :action_set => {
    {
      :route => 'action1/route',
      :panel_id => 'dom_obj_id',
    }
  },
}
=end

R8::Routes[:workspace] = {
  :layout => 'workspace',
}

=begin
:layout => defines what master layout to use for the request if its an normal non-js response
:panel => defines what partial rtpl assign var gets the contents if render type is html and not js
          if js rendering/ajax call defines what DOM element ID gets assigned the contents,
          if not defined, should always default to main_body

:assign_type => defines how to assign/render the returned contents, either append | prepend | replace for now,
                if not defined and there are dupes for a :panel should default to append

****NOTES
Used leading routes[:component][:display] as example, switch like the other meta to whatever is necessary to mesh
with out-of-box ramaze routing

  Need to figure out best way to pass along request params to each action, as well as any trailing route info
    ie: request => http://siteurl.com/component/display/239439
        should hit route component/display and execute the action set instead
        the 239439 and any other ones should be passed on the end of each action set call by default
=end
R8::Routes["component/display"] = {
  :layout => 'default',
  :alias => '',
  :params => [:id],
  :action_set => 
  [
   {
     :route => "component/display",
     :action_params => ["$id$"],
     :panel => "main_body"
#     :assign_type => :append 
   },
   {
#     :route => "attribute/list",
     :route => "attribute/component_display",
     :action_params => [{:parent_id => "$id$"}],
     :panel => "main_body",
#      :assign_type => 'append | prepend | replace'
     :assign_type => :append 
   }
  ]
}

R8::Routes[:login] = {
  :alias => 'user/login',
}
R8::Routes.freeze

