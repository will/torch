require 'spec_helper'

describe User, 'create' do
  it 'has default heroku things' do
    User.count.should == 0
    User.create heroku_id: 'app123',
                plan: 'test',
                callback_url: 'https://blah',
                syslog_token: 'blah',
                logplex_token: 't.239d9f'
    u = User.first
    u.plan.should == 'test'
    u.created_at.should_not be_nil
  end
end

