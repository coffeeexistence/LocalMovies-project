require 'nokogiri'
require 'excon'
require_relative 'user'
require_relative 'theater'
require_relative 'movie'

Excon.defaults[:middlewares] << Excon::Middleware::RedirectFollower # will make sure to follow redirects, for better or worse


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