require 'spec_helper'
require './app/routing_store'

describe RoutingStore do
  before(:each) do
    @abc = User.create(syslog_token: 'abc')
    @def = User.create(syslog_token: 'def')
  end

  let(:data) do
    {
     'abc' => [{queue: 2, wait: 0, service: 30},
               {queue: 2, wait: 1, service: 32}],
     'def' => [{queue: 0, wait: 2, service: 5}]
    }
  end

  it 'hello' do
    RoutingStat.count.should == 0
    RoutingStore.store(data)
    RoutingStat.count.should == 2

    abc_stat = @abc.routing_stats.first
    abc_stat.queue.should   ==  2
    abc_stat.wait.should    ==  0
    abc_stat.service.should == 31

    def_stat = @def.routing_stats.first
    def_stat.queue.should   == 0
    def_stat.wait.should    == 2
    def_stat.service.should == 5
  end
end
