=begin
Sequel.migration do
  change do
    alter_table(:repo__repo) do
      add_column :remote_repo_namespace,  :varchar, :size => 30
    end
  end
end
=end

