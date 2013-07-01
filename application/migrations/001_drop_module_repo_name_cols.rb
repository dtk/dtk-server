=begin
Sequel.migration do
  change do
    alter_table(:module__component) do
      drop_column :remote_repo
    end
    alter_table(:module__service) do
      drop_column :remote_repo
    end
  end
end
=end

