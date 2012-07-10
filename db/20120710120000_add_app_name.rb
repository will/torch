Sequel.migration do
  change do
    alter_table(:users) do
      add_column :name, :text
    end
  end
end
