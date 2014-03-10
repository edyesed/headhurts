require 'sinatra'
require 'json'
require 'erb'
require 'mongo'
require 'oauth2'
require 'github-oauth'
require 'github-api'
require 'logger'
require 'pp'
require './lib/githubbed'
require './lib/setupenv.rb'

enable :sessions
enable :logging
set :session_secret, 'XX123xxlkjadslkjasd'
set :protection, :origin_whitelist => ['http://localhost']

def redirect_uri
  uri = URI.parse(request.url)
  uri.path = '/auth/github/callback'
  uri.query = nil
  uri.to_s
end


before do
  @env = {}
  ENV.each do |key, value|
    begin
      hash = JSON.parse(value)
      @env[key] = hash
    rescue
      @env[key] = value
    end
  end
  if @env['VCAP_SERVICES'].nil?
    @mgkey = "localhost"
    @db = "localhost_testdb"
    @client = Mongo::MongoClient.new(@mgkey, :pool_size => 5, :pool_timeout => 5)
  else
    @services = JSON.parse(ENV['VCAP_SERVICES'])
    @mgkey = @services["mongodb-2.2"][0]['credentials']['url']
    @db = @mgkey[%r{/([^/\?]+)(\?|$)}, 1]
    @client = Mongo::MongoClient.from_uri(@mgkey,
                :pool_size => 5, :pool_timeout => 5)
  end
  if request.env['HTTP_X_AUTH_TOKEN']
    begin
      session[:access_token] = request.env['HTTP_X_AUTH_TOKEN']
      @user = GithubApi::User.new(session[:access_token])
      session[:gh_user_id] = @user.data['id']
    rescue
      logger.info "What the shit. submitted user id but couldn't look it up?"
      halt(404, erb(:explain))
    end
  end 
  logger.info "session access_token before : #{session[:access_token]}"
  logger.info "session gh_user_id before : #{session[:gh_user_id]}"
end

get '/yourmom' do
  puts "How did we get here? Auth with token failed"
end

get '/auth2' do
  @user = GithubApi::User.new(session[:access_token])
  if @user.nil?
    "User came back nil"
  else
    "User was non-nil. #{@user.data}"
    session[:gh_user_id] = @user.data['id']
  end
  redirect "/"
end

get '/oauth' do
  session[:access_token] = GithubOAuth.token(ENV['GITHUB_SECRET'],
                                    ENV['GITHUB_KEY'], params[:code])
  redirect '/auth2'
end

get '/' do
  erb :explain
end

post '/events/:type' do
  logger.info "in the events POSTer"
  if session[:gh_user_id].nil?
    halt(403,erb(:explain))
  end
  request.body.rewind
  @rawinput = request.body.read
  datas = JSON.parse(@rawinput)
  datas['@type'] = params[:type]
  db = @client.db(@db)
  coll = db.collection(session[:gh_user_id].to_s)
  coll.insert(datasdatas)
  erb :triggers, :locals => {:type => params[:type], :data => datas, :colls => coll }
end

get '/events/:type' do
  db = @client.db(@db)
  datas = db.collection(session[:gh_user_id].to_s).find("@type" => params[:type])
  c = datas.count
  erb :results, :locals => {:type => params[:type], :data => datas }
end
