#!/usr/bin/env ruby
require_relative "../lib/Geo.rb"
#Application.set_location_interactive
Application.set_location_interactive()
Scrape.add_fandango_theaters
#binding.pry