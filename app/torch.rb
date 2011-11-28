require 'sequel'

module Torch
  DB = Sequel.connect ENV['DATABASE_URL'] || 'postgres:///torch'
end

require_relative 'user'
require_relative 'routing_stat'

