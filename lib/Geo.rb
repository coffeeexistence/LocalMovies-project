require 'json'
require 'excon'
require 'pry'
require 'nokogiri'
class Application
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
  		puts "Please enter your street address & zip code(mandatory) :)"
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

    def self.get_fandango_theater_arr
    	zip = Application.zip_code
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


    def self.movies_and_showtimes_hash(theater)
    	movie_sections = theater.css("showtimes-movie-container")
    	hash = {}
    	movie_sections.each do |movie_section|
    		showtime_buttons = movie_section.css(".btn-ticket")
    		showtimes = showtime_buttons.map{|showtime| showtime.css("time").text}
    		movie_title = movie_section.css(".showtimes-movie-title").text
    		#binding.pry
    		#movie_class = Movie.create_new_or_return_existing()

    	end

    end

    def self.add_fandango_theaters
    	self.get_fandango_theater_arr.each do |theater| 
    		theater_class = self.generate_theater(theater)
    		movies_showtimes = self.movies_and_showtimes_hash(theater)

    	end
    end
end

class Movie

end

class Theater
	@@all=[]
	attr_accessor :name, :address, :movies, :location
	def initialize(name, address)
		@name=name
		@address=address
		location_class = Maps_Distance_API.new(Application.user_location, address)
		if location_class.parameters_valid? 
			@location=location_class
			puts "Theater '#{@name}' At #{location_class.destination_result_full}"
		else
			puts "Unfortunately, that location didn't work. I can't handle that"
			raise 'farewell cruel world'
		end
		self.class.all << self
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

