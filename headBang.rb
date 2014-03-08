require 'sinatra'
require 'json'
require 'erb'
require 'mongo'
require 'oauth2'
require 'github-oauth'
require 'github-api'
require 'pp'
require './lib/githubbed'
require './lib/setupenv.rb'

enable :sessions
set :session_secret, 'XX123xxlkjadslkjasd'

def redirect_uri
  uri = URI.parse(request.url)
  uri.path = '/auth/github/callback'
  uri.query = nil
  uri.to_s
end

configure do
  GetConfig.new.for_deployment
end

before do
  if request.env['HTTP_X_AUTH_TOKEN']
    session[:access_token] = request.env['X-Auth-Token']   
  end 
  puts "session token before : #{session[:access_token]}"
end


get '/auth2' do
  unless session[:access_token]
   redirect GithubOAuth.authorize_url(ENV['GITHUB_SECRET'], ENV['GITHUB_KEY'])
  end
  @user = GithubApi::User.new(session[:access_token])
  if @user.nil?
    "User came back nil"
  else
    #"USER: #{@user.data['email']}"
    "User was non-nil. #{@user.data}"
  end
  #{}"you have authenticated #{session[:access_token]}"
  #{}"you have repos #{repos}"
end

get '/oauth' do
  session[:access_token] = GithubOAuth.token(ENV['GITHUB_SECRET'],
                                    ENV['GITHUB_KEY'], params[:code])
  redirect '/auth2'
end

get '/' do
  #"This API is coming soonish"
  #"#{request.env['X-Auth-Token']}"
  "#{session[:access_token]}"
  #erb :explain
end

post '/events/:type' do
  request.body.rewind
  @rawinput = request.body.read
  datas = JSON.parse(@rawinput)
  #"Hello #{datas}"
  datas['@type'] = params[:type]
  db = @client.db(@db)
  coll = db.collection(params[:type])
  coll.insert(datas)
  erb :triggers, :locals => {:type => params[:type], :data => datas, :colls => coll }
end

get '/events/:type' do
  db = @client.db(@db)
  datas = db.collection(params[:type]).find("@type" => params[:type])
  c = datas.count
  erb :results, :locals => {:type => params[:type], :data => datas }
end
