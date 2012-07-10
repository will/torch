require './app/torch'
require 'sinatra/base'
require 'json'
require 'rdiscount'
require 'heroku/nav'
require 'gchart'

class App < Sinatra::Base
  use Rack::Session::Cookie, secret: ENV['SSO_SALT']
  set :environment, ENV['RACK_ENV']
  set :root, './'
  set :views, settings.root + '/views'

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
    markdown File.read('./README.md'), :layout_engine => :haml
  end

  # sso sign in
  get "/heroku/resources/:id" do
    id, format = params[:id].split(".")
    format = "html" if format.nil?

    user = User.find(:heroku_id => "app#{id}@heroku.com")

    if ENV['RACK_ENV'].nil?
      pre_token = user.id + ':' + ENV['SSO_SALT'] + ':' + params[:timestamp]
      token = Digest::SHA1.hexdigest(pre_token).to_s
      halt 403 if token != params[:token]
      halt 403 if params[:timestamp].to_i < (Time.now - 2*60).to_i
    end

    halt 404 unless user

    stats = user.routing_stats.reverse

    service = stats.map{|s| s.service.to_i}
    service_max = service.max
    service = service.map{|i| i.to_f / service_max }

    count   = stats.map{|s| s.count.to_i}
    count_max = count.max
    count = count.map{|i| i.to_f / count_max }

    if format == "json"
      content_type "text/javascript"
      data = {:service => service, :count => count}
      "#{params[:callback]}(#{data.to_json})"
    else
      purp = "6B5494"
      green = "67843B"
      @chart =  GChart.line do |g|
        g.data = [ service, count]
        g.extras = {chls: "4|5",
                    chm: "B,BF9BFE,0,0,0"}
        g.colors = [ purp, green ]
        g.legend = [ 'service time', 'requests' ]
        g.width  = 950
        g.height = 315

        g.axis(:left) do |a|
          a.text_color = purp
          a.range = 0..(service_max)
        end
        g.axis(:right) do |a|
          a.text_color = green
          a.range = 0..(count_max)
        end
        g.axis(:bottom) do |a|
          a.labels = [stats.first.created_at, stats.last.created_at]
        end
      end

      session[:heroku_sso] = params['nav-data']
      response.set_cookie('heroku-nav-data', value: params['nav-data'])
      haml :graph, :layout_engine => :erb
    end
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
