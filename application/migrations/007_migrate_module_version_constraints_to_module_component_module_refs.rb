=begin
Sequel.migration do
  change do
    rename_table(:module__version_constraints, :module__component_module_refs)
    alter_table(:module__component_module_refs) do
      rename_column :constraints, :content
    end
  end
end
=end


