require_relative 'maps_distance_api'

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