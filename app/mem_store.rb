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

