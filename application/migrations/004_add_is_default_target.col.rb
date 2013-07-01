=begin
Sequel.migration do
  change do
    alter_table(:datacenter__datacenter) do
      add_column :is_default_target, :boolean, :default => false
    end
  end
end
=end
