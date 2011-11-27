require 'eventmachine'
require 'strscan'

module Printer
  class Log
    def initialize(data)
      scan(data)
      scan_router(@log) if @ps == 'router'
    end

    def print
      if @ps == 'router'
        puts "\n#{@token} queue: #{@queue} wait: #{@wait} service: #{@service}"
      else
        print '.'
      end
    end

    private
    def scan(str)
      ss = StringScanner.new(str)
      ss.skip_until(/\s/)
      ss.skip_until(/\s/)
      @date = ss.scan_until(/\s/).strip
      @token = ss.scan_until(/.\s/).strip
      @service = ss.scan_until(/.\s/).strip
      @ps = ss.scan_until(/.\s/).strip
      ss.skip_until(/- - /)
      @log = ss.rest.strip
    end

    def scan_router(str)
      result = Hash[ str.split(/ /).map{|j| j.split(/=/)} ]
      @queue = result['queue']
      @wait = result['wait']
      @service = result['service']
    end

  end

  def receive_data(data)
    Log.new(data).print
  end

end

EventMachine::run do
  port = (ENV['PORT'] || 4000).to_i
  EventMachine::start_server '0.0.0.0', port, Printer
  puts 'started server'
end
