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
        MemStore.store @token, queue: @queue.to_i, wait: @wait.to_i, service: @service.to_i
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

module MemStore
  class << self
    def store(key, data)
      @@storage[key] << data
    end

    def get
      @@storage
    end

    def clear
      @@storage = Hash.new{|h,k| h[k] = []}
    end
  end
  @@storage = self.clear
end

module RoutingStore
  extend self
  def store(hash)
    hash.each do |token, data|
      begin
        avgs = calc_avgs(data)
        vals = avgs.merge token: token, count: data.size
        insert(vals)
      rescue => e
        p e
      end
    end
  end

  private

  def insert(vals)
    p vals
  end

  def calc_avgs(data)
    {
      queue:   mean( data.map{|h| h[:queue]  } ),
      wait:    mean( data.map{|h| h[:wait]   } ),
      service: mean( data.map{|h| h[:service]} )
    }
  end

  def mean(ary)
    (ary.inject(:+).to_f / ary.size).to_i
  end
end

EventMachine::run do
  port = (ENV['PORT'] || 4000).to_i
  EventMachine::start_server '0.0.0.0', port, Scanner
  puts 'started server'
  EventMachine.add_periodic_timer(60) do
    RoutingStore.store MemStore.get
    MemStore.clear
  end
end
