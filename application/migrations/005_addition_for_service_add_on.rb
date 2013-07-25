#TODO: either add schema or advance schema

=begin
Sequel.migration do
  change do
    create_table(:service__add_on) do
      ### common cols
      column :id, "bigint", :null=>false
      primary_key [:id]
      column :c, "integer", :null=>false
      column :local_id, "integer", :default=>"nextval('top.local_id_seq'::regclass)".lit, :null=>false
      column :ref, "text"
      column :ref_num, "integer"
      column :description, "text"
      column :display_name, "text"
      column :created_at, "timestamp without time zone"
      column :updated_at, "timestamp without time zone"
      column :owner_id, "bigint"
      column :group_id, "bigint"
      ### end: common cols

      column :type, "varchar", :size => 25
      foreign_key :sub_assembly_id, :component,  {:on_delete => :set_null, :on_update => :set_null}

      #many_to_one => [:component]
      foreign_key :component_component_id, :component,  {:on_delete => :set_null, :on_update => :set_null}
    end

    alter_table(:port__link) do
      add_column :required, :boolean
      add_column :output_is_local, :boolean
    end
  end
end
=end
