require './app/routing_stat'
module RoutingStore
  extend self
  def store(hash)
    hash.each do |token, data|
      begin
        avgs = calc_avgs(data)
        vals = avgs.merge count: data.size
        insert(token, vals)
      rescue => e
        p e
      end
    end
  end

  private

  def insert(token, vals)
    user = User[syslog_token: token]
    return unless user
    vals.merge! user_id: user.id
    p RoutingStat.create(vals)
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
