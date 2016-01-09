require 'json'
require 'excon'
require 'pry'
class Geo
	attr_accessor :origin
	def initialize(origin)
		@origin=origin
	end
	#https://maps.googleapis.com/maps/api/distancematrix/json?origins=39951+Via+Espana+92562&destinations=Murrieta
	def return_data(destination)

	end

	def time_to_location(location)

	end
end

class Maps_Distance_API
	attr_accessor :origin, :destination, :hash


	def initialize(origin, destination)
		@origin=parsed(origin)
		@destination=parsed(destination)
		@hash=fetch_json_hash

	end

	def parsed(location_str)
		location_str.gsub(" ", "+")
	end

	def valid_parameters?

	end


	def fetch_json_hash
		query="https://maps.googleapis.com/maps/api/distancematrix/json?"
		query+="origins="+@origin
		query+="&destinations="+@destination
		puts "Querying Google with"
		puts query
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

binding.pry