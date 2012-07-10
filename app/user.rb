require 'rest_client'
require 'json'

class User < Sequel::Model
  one_to_many :routing_stats,
              :limit => (60*24),
              :order => 'created_at desc'.lit

end
