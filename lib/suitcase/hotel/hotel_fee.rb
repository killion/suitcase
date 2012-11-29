module Suitcase
  class Hotel < TranslatedHash
    # Public: A HotelFee represents a single hotel fee (excluding surcharges) on a Room.
    class HotelFee
      attr_accessor :description, :amount, :currency
      # Internal: Create a new HotelFee.
      #
      # info - A Hash of parsed info from HotelFee.parse.
      def initialize(info)
        @description, @amount, @currency = info[:description], info[:amount], info[:currency]
      end

      # Internal: Parse a HotelFee from the room response.
      #
      # info - A Hash of the parsed JSON relevant to the hotel fee.
      #
      # Returns a HotelFee representing the info.
      def self.parse(info)
        new(description: info["@description"], amount: info["@amount"], currency: info["@currency"])
      end
    end
  end
end
