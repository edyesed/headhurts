require 'sinatra'
require 'json'
require 'erb'
require 'mongo'
require 'oauth2'
require 'github-oauth'
require 'github-api'
require './lib/githubbed'
#include Mongo

enable :sessions
set :session_secret, 'XX123xxlkjadslkjasd'

#def oath_client_natch
#	OAuth2::Client.new(
#		ENV['GITHUB_KEY'],
#		ENV['GITHUB_SECRET'],
#		:site => 'https://github.com',
#		:authorize_url => '/login/oauth/authorize',
#		:token_url => '/login/oauth/access_token')
#end

def redirect_uri
	uri = URI.parse(request.url)
	uri.path = '/auth/github/callback'
	uri.query = nil
	uri.to_s
end

before do
#	@oauth_client = OAuth2::Client.new(
#		ENV['GITHUB_KEY'],
#		ENV['GITHUB_SECRET'],
#		:site => 'https://headbang.ng.bluemix.net')
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
    	@db = "mytestdb"
    	@client = Mongo::MongoClient.new("localhost", :pool_size => 5, :pool_timeout => 5)
    else
    	@services = JSON.parse(ENV['VCAP_SERVICES'])
    	@mgkey = @services["mongodb-2.2"][0]['credentials']['url']
    	@db = @mgkey[%r{/([^/\?]+)(\?|$)}, 1]
	    @client = Mongo::MongoClient.from_uri(@mgkey,
	                                     :pool_size => 5, :pool_timeout => 5)
	end
	#@client = Mongo::MongoClient.new(@mgkey.to_s, :pool_size => 5, :pool_timeout => 5)
end

get '/auth2' do
	unless session[:access_token]
		redirect GithubOAuth.authorize_url(ENV['GITHUB_SECRET'], ENV['GITHUB_KEY'])
	end
	@user = GithubApi::User.new(session[:access_token])
	if @user.nil?
		"User came back nil"
	else
		"USER: #{@user.data['email']}"
		#{}"User was non-nil. #{@user.data}"
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
	#{}"LOL WUT"o
	#{}"services:#{@services} mgkey:#{@mgkey}"
	"This API is coming soonish"
	#erb :index
end

post '/events/:type' do
	request.body.rewind
	@rawinput = request.body.read
	datas = JSON.parse(@rawinput)

	#"Hello #{datas}"
	datas['@type'] = params[:type]
	##db = @client.db('testdb')
	db = @client.db(@db)
	coll = db.collection(params[:type])
	coll.insert(datas)
	erb :triggers, :locals => {:type => params[:type], :data => datas, :colls => coll }
end

get '/events/:type' do
	##db = @client.db('testdb')
	db = @client.db(@db)
	datas = db.collection(params[:type]).find("@type" => params[:type])
	c = datas.count
	#
	erb :results, :locals => {:type => params[:type], :data => datas }
end