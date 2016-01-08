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

	end

	def parsed(location_str)
		location_str.gsub(" ", "+").gsub(/[!,.]/, "")
	end

	def valid_parameters?

	end

	def 

	def fetch_json_hash
		query="https://maps.googleapis.com/maps/api/distancematrix/json?"
		query+="?origin="+@origin
		query+="&destinations="@destination
		return_data=Excon.get(query)
		JSON.parse(return_data.body)
	end


end

binding.pry