require './app/torch'
require 'sinatra/base'
require 'json'
require 'rdiscount'
require 'heroku/nav'
require 'gchart'

class App < Sinatra::Base
  use Rack::Session::Cookie, secret: ENV['SSO_SALT']
  enable :inline_templates
  set :environment, ENV['RACK_ENV']

  helpers do
    def refuse_provision(reason)
      throw(:halt, [422, {:message => reason}.to_json])
    end

    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials &&
      @auth.credentials == [ENV['HEROKU_USERNAME'], ENV['HEROKU_PASSWORD']]
    end
  end

  get "/" do
    markdown File.read('./README.md'), :layout_engine => :erb
  end

  # sso sign in
  get "/heroku/resources/:id" do
    #pre_token = params[:id] + ':' + ENV['SSO_SALT'] + ':' + params[:timestamp]
    #token = Digest::SHA1.hexdigest(pre_token).to_s
    #halt 403 if token != params[:token]
    #halt 403 if params[:timestamp].to_i < (Time.now - 2*60).to_i

    user = User[params[:id].to_i]
    halt 404 unless user

    stats = user.routing_stats.reverse

    #service = GChart.bar(title: 'service times (ms)', data: stats.map(&:service))

    service = stats.map{|s| s.service.to_i}
    count   = stats.map{|s| s.count.to_i}
    @chart =  GChart.line do |g|
      g.data = [ service, count]
      g.colors = [:red, :green]
      g.legend = [ 'service time', 'requests' ]
      g.width  = 950
      g.height = 315

      g.axis(:left) do |a|
        a.text_color = :red
        a.range = (service.min)..(service.max)
      end
      g.axis(:right) do |a|
        a.text_color = :green
        a.range = (count.min)..(count.max)
      end
      g.axis(:bottom) do |a|
        a.labels = [stats.first.created_at, stats.last.created_at]
      end
    end

    session[:heroku_sso] = params['nav-data']
    response.set_cookie('heroku-nav-data', value: params['nav-data'])
    haml :graph, :layout_engine => :erb
  end

  # provision
  post '/heroku/resources' do
    protected!
    params = JSON.parse(request.body.read)

    u = User.create logplex_token: params['logplex_token'],
                     callback_url: params['callback_url'],
                     syslog_token: params['syslog_token'],
                        heroku_id: params['heroku_id'],
                             plan: params['plan']

    status 201
    {id: u.id, syslog_drain_url: ENV['DRAIN_URL']}.to_json
  end

  # deprovision
  delete '/heroku/resources/:id' do
    protected!
    u = User[params[:id].to_i]
    if u
      u.destroy
      "ok"
    else
      status 404
    end
  end

  # plan change
  put '/heroku/resources/:id' do
    protected!
    body = JSON.parse(request.body.read)
    u = User[params[:id].to_i]
    if u && u.update(plan: body['plan'])
      "ok"
    else
      status 404
    end
  end
end

__END__

@@ layout
<!DOCTYPE>
<html>
<head><title>Torch</title>
<link rel="stylesheet" type="text/css" href="http://kevinburke.bitbucket.org/markdowncss/markdown.css">
</head>
<body>
<%= yield %>
</body>
</html>


@@ graph
%img{src: @chart.to_url}
