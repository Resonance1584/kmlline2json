# kmlline2json
# Converts a Google Maps KML file containing LineString placemarks
# to a json file for use in Google Maps API V3
#
# Iterates over all arguments and treats each as a file. Reports an
# error if a file is not found.
# 
# Can be called on a directory if -d <directory> is used instead of
# file name arguments

require 'nokogiri'
require 'json'

# If called with -d flag treat second argument as a directory
if (ARGV[0] == '-d')
    args = Dir.entries(ARGV[1])
    # Remove special directory symbols
    args.remove('.')
    args.remove('..')
else
    # Treat each argument as a filename
    args = ARGV
end

puts args

# Iterate over each file, opening, extracting way information and writing
# a .kml file containing polyline information.
args.each do |inputFileName|
    # Check file exists
    if File::exist?(inputFileName)
        # Open file
        File.open(inputFileName) do |f|
            # Parse document
            doc = Nokogiri::XML(f)

            #Remove namespaces as I am lazy
            doc.remove_namespaces!

            jsonDoc = Hash.new

            doc.xpath('//Placemark').each do |placemark|
                name = placemark.at_xpath('name').inner_text
                coordinates = placemark.at_xpath('LineString/coordinates').inner_text

                coordsArray = Array.new

                coords = coordinates.split(/\r?\n/)
                coords.each do |latLng|
                    latLng = latLng.strip
                    latLng = latLng.split(",")
                    #Avoid nil values
                    if (latLng[1].nil? || latLng[0].nil?)
                        next
                    end
                    #Swap lat - lng order and store in array
                    latLngArray = Array.new
                    latLngArray.push(latLng[1])
                    latLngArray.push(latLng[0])
                    coordsArray.push(latLngArray)
                end

                jsonDoc[name] = coordsArray
            end

            # Append .kml to original filename and write output
            File.open(inputFileName + '.json', 'w') {|f| f.write(JSON.generate(jsonDoc)) }
            

        end
    else
        # Write an error indicating file does not exist
        puts 'Error: File not found "' + inputFileName + '"'
    end
end