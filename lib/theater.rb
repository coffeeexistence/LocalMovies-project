require_relative 'maps_distance_api'

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
