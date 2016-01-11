require 'colorize'
require_relative 'user'
require_relative 'theater'
require_relative 'movie'
require_relative 'scrape'

class Discover

	def self.get_user_and_theater_info
		User.set_location_interactive()
		print "Fetching local theater & movie data"
		Scrape.add_fandango_theaters
		puts ""
	end

	def self.display_theaters_near_you
		puts ""
		puts "Theaters near you:"
		Theater.all.each do |theater| 
			Textify.format("    "+theater.name, "|  "+theater.location.distance_miles_text+" away", 40)
		end
	end

	def self.display_available_movies
		puts ""
		puts "Movies Available:"
		movie_hash={}
		Movie.all.each{|movie| movie_hash["    "+movie.rating_percent]=movie.name_and_info}
		Textify.print_2col_list(movie_hash)
	end

	def self.display_movies_over_75
		puts ""
		puts "Movies worth your money:"
		movie_hash={}
		Movie.over_75_rating.each_with_index{|movie, index| movie_hash["  " + "[#{index.to_s}] " + movie.name_and_info] = movie.rating_percent}
		Textify.print_2col_list(movie_hash)
	end

	def self.start
		while true
			puts "\n\n"
			print "Enter movie # to see showtimes, type 'exit' to leave: "
			input = gets.chomp.strip
			puts ""
			break if input == "exit"
			self.get_and_display_showtimes(input)
		end
	end

	def self.get_and_display_showtimes(input)
		movie = Movie.over_75_rating[input.to_i]
		puts ""
		puts "____________________________________________________"
		puts ""
		puts "Movie Selected: "+movie.name.blue.bold
		movie.display_showtimes_all
		puts "____________________________________________________"

	end

end



class Textify
	def self.format(entry_1, entry_2, fixed_distance)
		padding_length=fixed_distance-entry_1.length
		padding=""
		padding_length.times do 
			padding << " "
		end
		puts entry_1+padding+entry_2
	end

	def self.print_2col_list(text_hash)
		fixed_distance=self.size_of_longest_string(text_hash.keys)+3
		text_hash.each do |key, value|
			pad = self.make_pad(fixed_distance-key.to_s.length)
			puts key.to_s+pad+value.to_s
		end
	end



	def self.size_of_longest_string(array)
		array.max_by(&:length).length
	end

	def self.make_pad(size)
		padding=""
		size.times do |i|
			if i==0 || i==size-1
				padding << " "
			else
				padding << "-"
			end
		end
		padding
	end

end

