Sequel.migration do
  change do
    alter_table(:users) do
      add_index :syslog_token
    end

    create_table(:routing_stats) do
      primary_key :id
      column :created_at, :timestamptz, :default => "now()".lit
      column :user_id, :integer
      column :queue, :integer
      column :wait, :integer
      column :service, :integer
      column :count, :integer
      index :user_id
    end
  end
end
