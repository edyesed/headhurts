class GetConfig
  def initialize
    @env = {}
  def for_deployment
    ENV.each do |key, value|
    begin
      hash = JSON.parse(value)
      @env[key] = hash
    rescue
      @env[key] = value
    end

    if @env['VCAP_SERVICES'].nil?
      @mgkey = "localhost"
      @db = "mytestdb"
      @client = Mongo::MongoClient.new(@mgkey, :pool_size => 5, :pool_timeout => 5)
    else
      @services = JSON.parse(ENV['VCAP_SERVICES'])
      @mgkey = @services["mongodb-2.2"][0]['credentials']['url']
      @db = @mgkey[%r{/([^/\?]+)(\?|$)}, 1]
      @client = Mongo::MongoClient.from_uri(@mgkey,
                  :pool_size => 5, :pool_timeout => 5)
    end
