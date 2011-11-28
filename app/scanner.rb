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
