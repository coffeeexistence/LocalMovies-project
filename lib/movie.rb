require_relative 'theater'
require_relative 'scrape'
require 'colorize'

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
