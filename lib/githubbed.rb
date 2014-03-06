module GithubApi
  class HTTP
    include HTTParty
     format :json
     base_uri 'https://api.github.com'
     headers({"User-Agent" => "ruby's github-api"})
  end
end
