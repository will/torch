require 'eventmachine'

module Printer
  def receive_data(data)
    p data
  end
end

EventMachine::run do
  port = (ENV['PORT'] || 4000).to_i
  EventMachine::start_server '0.0.0.0', port, Printer
  puts 'started server'
end
