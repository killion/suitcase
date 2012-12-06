module Suitcase
  class Hotel < TranslatedHash
    # Public: An Exception to be raised from all EAN API-related errors.
    class EANException < Exception
      # Internal: Setter for the recovery information.
      attr_writer :recovery

      # Public: Getter for the recovery information.
      attr_reader :recovery

      # Internal: Setter for the error type.
      attr_writer :type

      # Public: Getter for the error type..
      attr_reader :type

      # Internal: Create a new EAN exception.
      #
      # message - The String error message returned by the API.
      # type    - The Symbol type of the error.
      def initialize(message, type = nil)
        @type = type
        super(message)
      end

      # Public: Check if the error is recoverable. If it is, recovery information
      #         is in the attribute recovery.
      #
      # Returns a Boolean based on whether the error is recoverable.
      def recoverable?
        @recovery.is_a?(Hash)
      end
    end
    
    class EANReservationException < Exception
      attr_accessor :raw, :itinerary_id, :handling, :category, :message, :verbose_message, :error_attributes
      
      def initialize(error)
        @raw = error
        @itinerary_id = error["itineraryId"]
        @handling = error["handling"]
        @category = error["category"]
        @message = error["presentationMessage"]
        @verbose_message = error["verboseMessage"]
        if error["ErrorAttributes"] and
           error["ErrorAttributes"]["errorAttributesMap"] and
           error["ErrorAttributes"]["errorAttributesMap"]["entry"]
          @error_attributes = error["ErrorAttributes"]["errorAttributesMap"]["entry"]
        end
        super(@message)
      end
      
      def itinerary_record_created?
        !@itinerary_id.nil? and @itinerary_id != "" and @itinerary_id != -1
      end
      
      def agent_will_follow_up?
        !itinerary_record_created and @handling == "AGENT_ATTENTION"
      end
    end
    
    class UnknownException < EANReservationException
      def can_resubmit?
        false
      end
    end
    
    class RecoverableException < EANReservationException
      def room_sold_out?
        @message == "The selected room is sold out" or 
        @message == "The room type or rate you selected is no longer available. Please choose another."
      end
      
      def hotel_sold_out?
        @message == "Property not available at booking time" or @message == "Property unavailable"
      end
      
      def sold_out?
        room_sold_out? or hotel_sold_out?
      end
      
      def price_mismatch?
        @category == "PRICE_MISMATCH"
      end
      
      def new_rate
        if price_mismatch?
          @error_attributes.find({ |attr| attr["key"] == "RATE_CHANGE" })["value"]
        else
          nil
        end
      end
      
      def new_rate_key
        if price_mismatch?
          @error_attributes.find({ |attr| attr["key"] == "RATE_KEY" })["value"]
        else
          nil
        end
      end
      
      def already_booked?
        @category == "ITINERARY_ALREADY_BOOKED"
      end
      
      def can_resubmit?
        @category == "DATA_VALIDATION" and @verboseMessage == "error.customer FileError: Customer Add Failed"
      end
    end
    
    class UnrecoverableException < EANReservationException
      def can_resubmit?
        ((@category == "EXCEPTION" or @category == "UNKNOWN") and 
          @verboseMessage == "TravelNow.com was unable to appropriately create back-end information required for this request.") 
        or (@category == "SUPPLIER_COMMUNICATION")
      end
    end
    
    class AgentAttentionException < EANReservationException
      def can_resubmit?
        @category == "DATA_PARSE_RESULT"
      end
    end
  end
end
