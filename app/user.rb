require 'rest_client'
require 'json'

class User < Sequel::Model
  one_to_many :routing_stats,
              :limit => (60*24),
              :order => 'created_at desc'.lit

  def get_config
    response = JSON.parse(RestClient.get(heroku_url))
  end

  def heroku_url
    url = URI.parse(callback_url)
    url.user = ENV["HEROKU_USERNAME"]
    url.password = ENV["HEROKU_PASSWORD"]
    return url.to_s
  end
end
