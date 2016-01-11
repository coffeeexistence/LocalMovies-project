require 'json'
require 'excon'
require 'pry'
require 'nokogiri'
require 'colorize'

Excon.defaults[:middlewares] << Excon::Middleware::RedirectFollower # will make sure to follow redirects, for better or worse


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

class User
	@@user_location=""
	def self.user_location
    	@@user_location
  	end

  	def self.zip_code
		@@user_location.split(", ")[-2].split(" ")[1]
	end

  	def self.set_location_interactive(force=nil)
  		test_destination="San Diego, CA"
  		if force
  			location_class=Maps_Distance_API.new(force, test_destination)
  			@@user_location=location_class.origin_result_full
  			return "Location forced to #{location_class.origin_result_full}"
  		end
  		print "Please enter your street address & zip code: "
		location=gets.chomp.strip
		
		location_class=Maps_Distance_API.new(location, test_destination)
		if location_class.parameters_valid? 
			@@user_location=location_class.origin_result_full
			puts "Location has been set to #{location_class.origin_result_full}"
		else
			puts "Unfortunately, that location didn't work. I can't handle that"
			raise 'farewell cruel world'
		end
  	end
end

class Scrape
	def self.get_page(url)
		page=Excon.get(url)
        Nokogiri::HTML(page.body)
       
    end

    def self.get_tomato_rating_from_page(page)
    	page=page.css("#all-critics-numbers")
    	#puts page
    	if page.css(".noReviewText").any?
    		#puts page
    		return nil 
    	end
    	#puts page
    	rating = page.css(".ratingValue").css(".meter-value").css("span")

    	if rating.empty?
    		#puts "didn't find a rating that way, let me try another way"
    		rating = page.css('[itemprop="ratingValue"]') 
    	end
    	rating.text.gsub("%", "")
    end

    def self.tomato_rating(movie_name)
    	query_start = "http://www.rottentomatoes.com/search/?search="
    	formatted_name = movie_name.gsub(" ", "+")
    	search_page = self.get_page(query_start+formatted_name)
    	print "."
    	STDOUT.flush
    	#Site will either show results page or go directly to the movie's page
    	if search_page.css("title").text.include?("Search Results")
    		result = search_page.css("#movie_results_ul").css(".tMeterScore")[0]
    		return nil if !result #if no rating could be found
    		return result.text.gsub("%", "")
    	else
    		self.get_tomato_rating_from_page(search_page)
    	end


    end

    def self.get_fandango_theater_arr
    	zip = User.zip_code
    	initial_url = "http://www.fandango.com/#{zip}_movietimes" 
    	page = self.get_page(initial_url)
    	#puts page
    	page.css(".showtimes-theater")
    end

    def self.generate_theater(theater)
    		name = theater.css(".showtimes-theater-title").css("a").text.strip
    		address = theater.css(".showtimes-theater-address").css("a").text
    		Theater.new(name, address)
    end


    def self.generate_movies_and_showtimes(theater_page, theater_class)
    	movie_sections = theater_page.css(".showtimes-movie-container")

    	movie_sections.each do |movie_section|

    		showtime_buttons = movie_section.css(".showtimes-times-area")
    		showtimes = showtime_buttons.css("time").map{|showtime| showtime.text}
    		movie_title = movie_section.css(".showtimes-movie-title").text
    		if movie_title.include?("An IMAX 3D Experience")
    			movie_title.gsub!("An IMAX 3D Experience", "")
    			movie_class = Movie.new_or_return_existing(movie_title)
    			movie_class.has_imax = true
    			theater_class.add_imax_showtimes(movie_class, showtimes)
    		elsif movie_title.include?("3D")
    			movie_title.gsub!("3D", "")
    			movie_class = Movie.new_or_return_existing(movie_title)
    			movie_class.has_3d = true
    			theater_class.add_3d_showtimes(movie_class, showtimes)
    		else
    			movie_class = Movie.new_or_return_existing(movie_title)
    			theater_class.add_movie_showtimes_arr(movie_class, showtimes)
    			movie_class.has_regular = true
    		end
    		movie_class.theaters << theater_class
    	end

    end

    def self.add_fandango_theaters
    	self.get_fandango_theater_arr.each do |theater_page| 
    		theater_class = self.generate_theater(theater_page)
    		self.generate_movies_and_showtimes(theater_page, theater_class)

    	end
    end
end


class Movie
	@@all=[]
	attr_accessor :theaters, :name, :description, :rating, :has_imax, :has_3d, :has_regular
	def initialize(name)
		@name=name.strip
		@theaters=[]
		@rating=Scrape.tomato_rating(@name)
		self.class.all << self
	end

	def self.over_75_rating
		self.sorted_movies.find_all{|movie| movie.rating.to_i>75}
	end

	def self.sorted_movies
		self.all.sort{|a,b| b.rating.to_i <=> a.rating.to_i}
	end

	def self.top_count
		(self.over_75_rating.length/2.5).ceil
	end

	def self.top_movies
		movie_arr=[]
		self.top_count.times do |i|
			index=(i)
			movie_arr << self.sorted_movies[index]
		end
		movie_arr
	end

	def name_and_info
		name = self.name
		name+="(Reg)" if (self.has_imax || self.has_3d) && self.has_regular
		name+="(IMAX)" if self.has_imax
		name+="(3D)" if self.has_3d
		name
	end

	def display_showtimes_all
		puts "  "+"Regular:".underline
		self.display_showtimes
		if self.has_3d
			puts "  "+"3D:".underline
			self.display_showtimes_3d
		end
		if self.has_imax
			puts "  "+"IMAX:".underline
			self.display_showtimes_imax
		end
		puts ""
	end

	def display_showtimes
		self.showtimes.each do |theater, showtimes|
			next if showtimes==nil
			puts "    "+theater.name+" - "+theater.location.distance_miles_text
			showtimes_str = showtimes.join(" - ").yellow
			puts "      "+showtimes_str
		end 
	end

	def display_showtimes_3d
		self.showtimes_3d.each do |theater, showtimes|
			next if showtimes==nil
			puts "    "+theater.name+" - "+theater.location.distance_miles_text
			showtimes_str = showtimes.join(" - ").yellow
			puts "      "+showtimes_str
		end 
	end

	def display_showtimes_imax
		self.showtimes_imax.each do |theater, showtimes|
			next if showtimes==nil
			puts "    "+theater.name+" - "+theater.location.distance_miles_text
			showtimes_str = showtimes.join(" - ").yellow
			puts "      "+showtimes_str
		end 
	end

	def showtimes
		showtimes_hash={}
		self.theaters.each do |theater|
			showtimes_hash[theater]=theater.showtimes(self)
		end
		showtimes_hash
	end

	def showtimes_3d
		showtimes_hash={}
		self.theaters.each do |theater|
			showtimes_hash[theater]=theater.showtimes_3d(self)
		end
		showtimes_hash
	end

	def showtimes_imax
		showtimes_hash={}
		self.theaters.each do |theater|
			showtimes_hash[theater]=theater.showtimes_imax(self)
		end
		showtimes_hash
	end

	def self.new_or_return_existing(name)
		search = self.all.find{|existing_movie| existing_movie.name==name.strip}
		return search if search
		self.new(name)
	end



	def rating_of_10
		return "N/A" if self.rating==nil
		"got a "+(self.rating.to_i/10).to_s+"/10"
	end

	def rating_percent
		return "N/A" if self.rating==nil
		(self.rating.to_i).to_s+"%"
	end

	def self.all
		@@all
	end
	def self.all=(all)
		@@all=all
	end
end

class Theater
	@@all=[]
	attr_accessor :name, :address, :movies, :location, :movie_showtimes_hash, :showtimes_imax_hash, :showtimes_3d_hash
	def initialize(name, address)
		@name=name
		@address=address
		@movies=[]
		@movie_showtimes_hash={}
		@showtimes_imax_hash={}
		@showtimes_3d_hash={}
		location_class = Maps_Distance_API.new(User.user_location, address)
		if location_class.parameters_valid? 
			@location=location_class
			#puts "Theater '#{@name}' At #{location_class.destination_result_full}"
		else
			puts "Unfortunately, that location didn't work. I can't handle that"
			raise 'farewell cruel world'
		end
		self.class.all << self
	end

	def showtimes(movie_class)
		@movie_showtimes_hash[movie_class.name]
	end

	def showtimes_3d(movie_class)
		@showtimes_3d_hash[movie_class.name]
	end

	def showtimes_imax(movie_class)
		@showtimes_imax_hash[movie_class.name]
	end

	def add_movie_showtimes_arr(movie_class, array)
		@movie_showtimes_hash[movie_class.name]=array
	end

	def add_3d_showtimes(movie_class, array)
		@showtimes_3d_hash[movie_class.name]=array
	end

	def add_imax_showtimes(movie_class, array)
		@showtimes_imax_hash[movie_class.name]=array
	end

	def add_movie(movie)
		@moves << movie
	end

	def self.all
    	@@all
  	end

end

class Maps_Distance_API
	attr_reader :origin, :destination, :hash

	def initialize(origin, destination)
		@origin=parsed(origin)
		@destination=parsed(destination)
		@hash=fetch_json_hash

		#raise 'Maps Class had an error - invalid parameters' if !parameters_valid?
	end

	def parsed(location_str)
		location_str.gsub(/[ \u{a0}]/, "+")
	end

	def parameters_valid?
		@hash['status']=="OK" && @hash['rows'][0]['elements'][0]['status']=="OK"
	end

	def origin_zip_code
		origin_result_full.split(", ")[-2].split(" ")[1]
	end

	def fetch_json_hash
		query="https://maps.googleapis.com/maps/api/distancematrix/json?"
		query+="origins="+@origin
		query+="&destinations="+@destination
		#puts "Querying Google with"
		#puts query
		return_data=Excon.get(query)
		JSON.parse(return_data.body)
	end

	def meters_to_miles(m)
		km = m / 1000
		km * 0.621371
	end

	def distance_miles
		meters=@hash['rows'][0]['elements'][0]['distance']['value']
		meters_to_miles(meters).to_i
	end


	def distance_miles_text
		"#{distance_miles} miles"
	end

	def origin_result_full
		@hash['origin_addresses'][0]
	end

	def destination_result_full
		@hash['destination_addresses'][0]
	end

	def duration_minutes
		seconds = @hash['rows'][0]['elements'][0]['duration']['value']
		(seconds/60).to_i
	end

	def duration_minutes_text
		"#{duration_minutes} minutes"
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

