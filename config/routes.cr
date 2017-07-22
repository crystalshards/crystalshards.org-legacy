Amber::Server.instance.config do |app|
  pipeline :web do
    plug Amber::Pipe::Logger.new
  end

  # All static content will run these transformations
  pipeline :static do
    plug Amber::Pipe::Logger.new
    plug BakedStatic.new
    plug HTTP::CompressHandler.new
  end

  routes :web do
    get "/", HomeController, :index
    get "/*", HomeController, :index
  end

  routes :static do
    get "/assets/*", StaticController, :index
  end
end
