Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      column :heroku_id, :text
      column :plan, :text
      column :logplex_token, :text
      column :syslog_token, :text
      column :created_at, :timestamptz, :default => "now()".lit
      column :callback_url, :text
    end
  end
end
