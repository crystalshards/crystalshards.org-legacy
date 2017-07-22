require "amber"
require "./controllers/**"
require "./mailers/**"
require "./models/**"
require "./views/**"
require "./middleware/**"
require "../config/*"

Amber::Server.instance.run
