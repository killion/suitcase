module Suitcase
  class Hotel < TranslatedHash
    class Reservation < TranslatedHash
      attr_accessor :raw, :surcharges, :hotel_fees
      
      translation_root "HotelRoomReservationResponse"
      translate "itineraryId", :into => :itinerary_id
      translate "confirmationNumbers", :into => :confirmation_numbers, :using => lambda { |numbers| [numbers].flatten }
      translate "hotelReplyText", :into => :hotel_reply_text
      translate "reservationStatusCode", :into => :reservation_status_code
      translate "numberOfRoomsBooked", :into => :number_of_rooms_booked
      translate "checkInInstructions", :into => :check_in_instructions
      translate "arrivalDate", :into => :arrival_date
      translate "departureDate", :into => :departure_date
      translate "roomDescription", :into => :room_description
      translate "nonRefundable", :into => :non_refundable
      translate "rateOccupancyPerRoom", :into => :rate_occupancy_per_room
      
      translate "RateInfos.RateInfo.@promo", :into => :promotional_rate
      translate "RateInfos.RateInfo.ChargeableRateInfo.@total", :into => :total
      translate "RateInfos.RateInfo.ChargeableRateInfo.@surchargeTotal", :into => :surcharge_total
      translate "RateInfos.RateInfo.ChargeableRateInfo.@nightlyRateTotal", :into => :nightly_rate_total
      translate "RateInfos.RateInfo.ChargeableRateInfo.@maxNightlyRate", :into => :max_nightly_rate
      translate "RateInfos.RateInfo.ChargeableRateInfo.@currencyCode", :into => :currency_code
      translate "RateInfos.RateInfo.ChargeableRateInfo.@commissionableUsdTotal", :into => :commissionable_usd_total
      translate "RateInfos.RateInfo.ChargeableRateInfo.@averageRate", :into => :average_rate
      translate "RateInfos.RateInfo.ChargeableRateInfo.@averageBaseRate", :into => :average_base_rate
      translate "RateInfos.RateInfo.ChargeableRateInfo.@averageBaseRate", :into => :average_base_rate
      translate "RateInfos.RateInfo.ChargeableRateInfo.Surcharges", :into => :raw_surcharges
      translate "RateInfos.RateInfo.HotelFees", :into => :raw_hotel_fees
      
      # Internal: Create a new Reservation from the API response.
      #
      # info - The Hash of information returned from the API.
      def initialize(info)
        super(info)
        @surcharges = parse_surcharges
        @hotel_fees = parse_hotel_fees
      end
      
      def parse_surcharges
        if self.raw_surcharges 
          surcharges = [ self.raw_surcharges["Surcharge"] ].flatten
          surcharges.map { |raw_surcharge| Surcharge.parse(raw_surcharge) }
        else
          []
        end
      end
      
      def parse_hotel_fees
        if self.raw_hotel_fees
          fees = [ self.raw_hotel_fees["HotelFee"] ].flatten
          fees.map { |raw_fee| HotelFee.parse(raw_fee) }
        else
          []
        end
      end
    end
  end
end
