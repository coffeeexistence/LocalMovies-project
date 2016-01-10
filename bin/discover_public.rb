#!/usr/bin/env ruby
require_relative "../lib/Geo.rb"



#Application.set_location_interactive
Application.set_location_interactive()
Scrape.add_fandango_theaters
puts ""
puts "Theaters near you:"
Theater.all.each do |theater| 
	Textify.format("	"+theater.name, "|  "+theater.location.distance_miles_text+" away", 40)
end
puts ""
puts "Movies Available:"
Movie.all.each{|movie| puts "	"+movie.name}