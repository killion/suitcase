FILENAME = ENV["HOTEL_IMAGES"] || "HotelImageList.txt"

IMAGES = {}

def images_for(hotel)
  IMAGES[hotel.id.to_i] ||= IO.foreach(FILENAME).map do |line|
    split = line.split("|")
    if hotel.id.to_i == split[0].to_i
      Suitcase::Image.new({
        "caption" => split[1],
        "url" => split[2],
        "thumbnailUrl" => split[6],
        "width" => split[3],
        "height" => split[4]
      })
    else
      nil
    end
  end.compact
end

# examples

images_for(Suitcase::Hotel.find(location: "Boston")[0])