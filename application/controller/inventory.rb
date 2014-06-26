module XYZ
  class InventoryController < AuthController

    def index
# TODO: what is proper where clause to generaly get managed nodes
      node_list = get_objects(:node,{:type=>"staged"})
      tpl = R8Tpl::TemplateR8.new("inventory/node_list",user_context())

pp node_list

      run_javascript("R8.InventoryView.init('#{id}');")

      return {:content => ""}
    end

    def seed_content_tpl
# TODO: what is proper where clause to generaly get managed nodes
      tpl = R8Tpl::TemplateR8.new("inventory/seed_content_tpl",user_context())

      return {:content => tpl.render()}
    end

  end
end