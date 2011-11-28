require 'eventmachine'
require 'strscan'

require './app/torch'

require './app/scanner'
require './app/routing_store'
require './app/mem_store'

EventMachine::run do
  port = (ENV['PORT'] || 4000).to_i
  EventMachine::start_server '0.0.0.0', port, Scanner
  puts 'started server'
  EventMachine.add_periodic_timer(60) do
    RoutingStore.store MemStore.get
    MemStore.clear
  end
end
