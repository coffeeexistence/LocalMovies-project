#!/usr/bin/env ruby
require_relative "../lib/classes.rb"



#Application.set_location_interactive
Application.set_location_interactive()
print "Fetching local theater & movie data"
Scrape.add_fandango_theaters

puts ""
puts ""
puts "Theaters near you:"
Theater.all.each do |theater| 
	Textify.format("	"+theater.name, "|  "+theater.location.distance_miles_text+" away", 40)
end

puts ""
puts "Movies Available:"
movie_hash={}
Movie.all.each{|movie| movie_hash["    "+movie.rating_percent]=movie.name_and_info}

Textify.print_2col_list(movie_hash)

puts ""
puts "Movies worth your money:"
movie_hash={}
Movie.over_75_rating.each_with_index{|movie, index| movie_hash["  " + "[#{index.to_s}] " + movie.name_and_info] = movie.rating_percent}
Textify.print_2col_list(movie_hash)

while true
	puts ""
	print "Enter movie # to see showtimes, type 'exit' to leave: "
	input = gets.chomp.strip
	break if input == "exit"
	movie = Movie.over_75_rating[input.to_i]
	puts ""
	puts "____________________________________________________"
	puts ""
	puts "Movie Selected: "+movie.name
	movie.display_showtimes_all
	puts "____________________________________________________"
end

#binding.pry

