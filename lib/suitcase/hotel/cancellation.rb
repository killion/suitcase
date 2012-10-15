module Suitcase
  class Hotel < TranslatedHash
    class Cancellation
      extend Helpers
      include Helpers

      attr_accessor :itinerary_id, :email,
                    :confirmation_number,
                    :reason, :cancellation_number

      # Accepts a hash with the itinerary_id, confirmation_number, email
      # and optional reason code (COP ILL DEA OTH)
      def initialize(info)
        info.each do |k, v|
          instance_variable_set("@" + k.to_s, v)
        end
      end

      # Makes the call to EAN and if successful sets the
      # cancellation_number attribute
      def cancel_reservation!
        params = {}
        params["itineraryId"]        = itinerary_id
        params["email"]              = email
        params["confirmationNumber"] = confirmation_number
        params["reason"]             = reason if valid_reason?

        uri = Cancellation.url(
          method: 'cancel',
          params: params,
          include_key: true,
          include_cid: true,
          secure: true
        )

        session = Patron::Session.new
        session.timeout = 30000
        session.base_url = "https://" + uri.host
        res = session.post uri.request_uri, {}
        parsed = JSON.parse res.body
        handle_errors(parsed)
        @cancellation_number = parsed["HotelRoomCancellationResponse"]["cancellationNumber"]
      end

      def reservation_canceled?
        !cancellation_number.nil?
      end

      def valid_reason?
        %w(COP ILL DEA OTH).include?(reason)
      end

    end
  end
end
