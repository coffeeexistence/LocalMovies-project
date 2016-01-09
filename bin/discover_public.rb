puts "Please enter your street and zip code"
street_zip=gets.chomp.strip
fandango_url="http://www.fandango.com/#{zip}_movietimes"


#https://maps.googleapis.com/maps/api/distancematrix/json?origins=39951+Via+Espana+92562&destinations=Murrieta