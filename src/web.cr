require "baked_file_system"
require "faker"
require "kemal"
require "mime-types"
require "http/client"
require "json"
require "emoji"
require "./views/index"
require "./models/github_repos"
require "./models/time_cache"

SORT_OPTIONS    = {"stars", "updated", "forks"}
REPOS_CACHE     = TimeCache(String, GithubRepos).new(30.minutes)
ALL_REPOS_CACHE = TimeCache(String, GithubRepos).new(30.minutes)
TRENDING_CACHE  = TimeCache(String, GithubRepos).new(30.minutes)
POPULAR_CACHE   = TimeCache(String, GithubRepos).new(30.minutes)
RECENTLY_CACHE  = TimeCache(String, GithubRepos).new(30.minutes)

def headers
  headers = HTTP::Headers.new
  headers["User-Agent"] = "crystalshards"
  headers
end

class BakedPublic < Kemal::Handler
  BakedFileSystem.load("../static", __DIR__)

  def call(context)
    file = self.class.get(context.request.path)
    context.response.headers["content-type"] = MIME::Types.type_for(context.request.path).to_a.first.to_s
    file.write_to_io(context.response, false)
  rescue BakedFileSystem::NoSuchFileError
    call_next context
  end
end

add_handler BakedPublic.new

def crystal_repos(word = "", sort = "stars", page = 1, limit = 100, after_date = 1.years.ago)
  client = HTTP::Client.new("api.github.com", 443, true)
  client.basic_auth ENV["GITHUB_USER"], ENV["GITHUB_KEY"]
  date_filter = after_date.to_s("%Y-%m-%d")
  url = "/search/repositories?q=#{word.to_s != "" ? "#{word}+" : ""}language:crystal#{date_filter != "" ? "+pushed:>#{date_filter}" : ""}&per_page=#{limit + 10}&sort=#{sort}&page=#{page}"
  p url
  response = client.get(url, headers)
  repos = GithubRepos.from_json(response.body)
  repos.items.select! { |item| item.private == false }
  repos.items = repos.items[0, limit]
  repos
end

def fetch_sort(env)
  env.params.query["sort"]?.try(&.to_s) || ""
end

def fetch_filter(env)
  filter = env.params.query["filter"]?.try(&.to_s.strip.downcase) || ""
  filter.gsub(/[^a-z0-9\_\-]/i, "")
end

def fetch_page(env)
  env.params.query["page"]?.try(&.to_i) || 0
end

def main(env, query = "")
  sort = fetch_sort(env)
  filter = fetch_filter(env)
  page = fetch_page(env)
  env.response.content_type = "text/html"

  repos = REPOS_CACHE.fetch(filter + "_" + query + "_" + sort + "_" + page.to_s) { crystal_repos(query + filter, sort, page) }
  all_repos = ALL_REPOS_CACHE.fetch("all" + query) { crystal_repos(query, sort, page, 100, 5.years.ago) }
  trending = TRENDING_CACHE.fetch(sort + query) { crystal_repos(query, :stars, 1, 10, 1.weeks.ago) }
  popular = POPULAR_CACHE.fetch(sort + query) { crystal_repos(query, :stars, 1, 8) }
  recently = RECENTLY_CACHE.fetch(sort + query) { crystal_repos(query, :updated, 1, 6) }

  total = all_repos.not_nil!.total_count
  view = Views::Index.new total, repos, trending, popular, recently, sort, filter, page, env.params
  view.to_s
end

get "/" do |env|
  main env
end

get "/health" do
  "OK"
end

get "/name" do |env|
  prefix = [Faker::Hacker.ingverb, Faker::Hacker.adjective, Faker::Commerce.color].sample
  random_name = [prefix, Faker::Hacker.noun].join("_").sub(/[-_\s]/, "_").downcase.lchop("_")
  random_name = "#{Faker::Commerce.color}_#{random_name}" if random_name =~ /^\d/
  if env.request.headers["Accept"] == "*/*"
    random_name
  else
    render "#{__DIR__}/views/name.ecr"
  end
end

get "/:user" do |env|
  main env, "user:#{env.params.url["user"]}"
end

get "/:user/:repo" do |env|
  env.redirect("https://github.com/#{env.params.url["user"]}/#{env.params.url["repo"]}")
end

ENV["PORT"] ||= "3000"
Kemal.config.port = ENV["PORT"].to_i

Kemal.run
