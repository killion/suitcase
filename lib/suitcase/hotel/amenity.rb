module Suitcase
  class Hotel < TranslatedHash
    class Amenity
      attr_accessor :id, :description

      BITS = { business_services: 1,
        fitness_center: 2,
        hot_tub: 4,
        internet_access: 8,
        kids_activities: 16,
        kitchen: 32,
        pets_allowed: 64,
        swimming_pool: 128,
        restaurant: 256,
        whirlpool_bath: 1024,
        breakfast: 2048,
        babysitting: 4096,
        jacuzzi: 8192,
        parking: 16384,
        room_service: 32768,
        accessible_path: 65536,
        accessible_bathroom: 131072,
        roll_in_shower: 262144,
        handicapped_parking: 524288,
        in_room_accessibility: 1048576,
        deaf_accessiblity: 2097152,
        braille_or_signage: 4194304,
        free_airport_shuttle: 8388608,
        indoor_pool: 16777216,
        outdoor_pool: 33554432,
        extended_parking: 67108864,
        free_parking: 134217728
      }

      def initialize(info)
        @id, @description = info[:id], info[:description]
      end

      def self.parse_mask(bitmask)
        return nil unless bitmask

        BITS.select { |amenity, bit| (bitmask & bit) > 0 }.keys
      end
    end
  end
end
