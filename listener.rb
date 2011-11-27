require 'eventmachine'
require 'strscan'

module Scanner
  class Log
    def initialize(data)
      scan(data)
      scan_router(@log) if @ps == 'router'
    end

    def output
      if @ps == 'router'
        MemStore.store @token, [@queue.to_i, @wait.to_i, @service.to_i]
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
    begin
      Log.new(data).output
    rescue => e
      p e.inspect
    end
  end
end

class Array
  def mean
    (self.inject(:+).to_f / self.size).to_i
  end
end

module MemStore
  class << self
    def store(key, data)
      @@storage[key] << data
    end

    def calculate
      Hash[@@storage.map {|k,v| [k, v.transpose.map(&:mean)]}]
    end

    def clear
      @@storage = Hash.new{|h,k| h[k] = []}
    end
  end
  @@storage = self.clear
end

EventMachine::run do
  port = (ENV['PORT'] || 4000).to_i
  EventMachine::start_server '0.0.0.0', port, Scanner
  puts 'started server'
  EventMachine.add_periodic_timer(20) do
    p MemStore.calculate
    MemStore.clear
  end
end
