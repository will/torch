require 'rest_client'
require 'json'

class User < Sequel::Model
  one_to_many :routing_stats,
              :limit => 120,
              :order => 'created_at desc'.lit

end
