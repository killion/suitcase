module Suitcase
  class Hotel < TranslatedHash
    class RoomType
      attr_accessor :description, :description_long, :room_amenities, :room_code, :room_type_id
      
      def initialize(info)
        @description = info[:description]
        @description_long = info[:description_long]
        @room_amenities = []
        info[:room_amenities].each do |room_amenity|
          @room_amenities << Suitcase::Hotel::RoomAmenity.new(:id => room_amenity["@amenityId"], 
            :description => room_amenity["amenity"])
        end
        @room_code = info[:room_code]
        @room_type_id = info[:room_type_id]
      end
    end
  end
end