=begin
Sequel.migration do
  change do
    alter_table(:node__node) do
      add_column :role, :varchar, :size => 50
    end
  end
end
=end
