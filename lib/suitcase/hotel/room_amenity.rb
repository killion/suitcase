module Suitcase
  class Hotel < TranslatedHash
    class RoomAmenity
      attr_accessor :description, :id
      
      def initialize(info)
        @id = info[:id]
        @description = info[:description]
      end
    end
  end
end