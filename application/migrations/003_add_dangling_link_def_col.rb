=begin
Sequel.migration do
  change do
    alter_table(:link_def__link_def) do
      add_column :dangling,  :boolean, :default => false
    end
  end
end
=end

