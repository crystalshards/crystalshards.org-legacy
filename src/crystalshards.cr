{% run "./sass-compile", "assets/stylesheets", "../public/assets/stylesheets" %}

require "amber"
require "./controllers/**"
require "./mailers/**"
require "./models/**"
require "./views/**"
require "./middleware/**"
require "../config/*"

Amber::Server.instance.run
