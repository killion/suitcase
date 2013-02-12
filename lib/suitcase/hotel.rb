require "suitcase/hotel/amenity"
require "suitcase/hotel/session"
require "suitcase/hotel/bed_type"
require "suitcase/hotel/cache"
require "suitcase/hotel/ean_exception"
require "suitcase/hotel/helpers"
require "suitcase/hotel/image"
require "suitcase/hotel/location"
require "suitcase/hotel/nightly_rate"
require "suitcase/hotel/payment_option"
require "suitcase/hotel/reservation"
require "suitcase/hotel/room"
require "suitcase/hotel/room_amenity"
require "suitcase/hotel/room_type"
require "suitcase/hotel/surcharge"
require "suitcase/hotel/supplier"
require "suitcase/hotel/cancellation"

module Suitcase
  # Public: A Class representing a single Hotel. It provides methods for
  #         all Hotel EAN-related queries in the gem.
  class Hotel < TranslatedHash
    extend Helpers
    
    # Public: The Amenities that can be passed in to searches, and are returned
    #         from many queries.
    AMENITIES = { 
      pool: 1,
      fitness_center: 2,
      restaurant: 3,
      children_activities: 4,
      breakfast: 5,
      meeting_facilities: 6,
      pets: 7,
      wheelchair_accessible: 8,
      kitchen: 9
    }
    
    attr_accessor :images, :nightly_rate_total, :raw

    # Internal: Initialize a new Hotel.
    #
    # info - A Hash of the options listed in attr_accessor.
    #
    # Returns a new Hotel object with the passed-in attributes.
    def initialize(info)
      super(info)
      self.images = self.class.parse_images(info)
    end

    def proximity_distance
      proximity_distance_original.to_s + proximity_unit_original.to_s
    end

    # Public: Find a Hotel based on ID, IDs, or location (and other options).
    #
    # info  - A Hash of known information about the query. Depending on the
    #         type of query being done, you can pass in three possible keys:
    #         :ids  - An Array of unique IDs as assigned by the EAN API.
    #         :id   - A single ID as assigned by the EAN API.
    #         other - Any other Hash keys will be sent to the generic
    #                 find_by_info method.
    #
    # Returns a single Hotel if an ID is passed in, or an Array of Hotels.
    def self.find(info)
      if info[:ids]
        find_by_ids(info[:ids], info[:session])
      elsif info[:id]
        find_by_id(info[:id], info[:session])
      else
        find_by_info(info)
      end
    end

    # Interal: Find a Hotel by its ID.
    #
    # id      - The Integer or String Hotel ID.
    # session - A Session with session data.
    #
    # Returns a single Hotel.
    def self.find_by_id(id, session)
      params = { hotelId: id }

      if Configuration.cache? and Configuration.cache.cached?(:info, params)
        raw = Configuration.cache.get_query(:info, params)
      else
        url = url(method: "info", params: params, session: session)
        raw = parse_response(url)
        handle_errors(raw)
        if Configuration.cache?
          Configuration.cache.save_query(:info, params, raw)
        end
      end
      update_session(raw, session)

      h = HotelWithDetails.new(raw)
      h.raw = raw
      h
    end

    # Internal: Find multiple Hotels based on multiple IDs.
    #
    # ids     - An Array of String or Integer Hotel IDs to be found.
    # session - A Session with session data stored in it.
    #
    # Returns an Array of Hotels.
    def self.find_by_ids(ids, session)
      params = { hotelIdList: ids.join(",") }

      if Configuration.cache? and Configuration.cache.cached?(:list, params)
        raw = Configuration.cache.get_query(:list, params)
      else
        url = url(method: "list", params: params, session: session)
        raw = parse_response(url)
        handle_errors(raw)
        if Configuration.cache?
          Configuration.cache.save_query(:list, params, raw)
        end
      end
      update_session(raw, session)

      hotels = [split(raw)].flatten.map do |hotel_data|
        h = HotelFromList.new("HotelSummary" => hotel_data)
        h
      end;hotels.first.raw = raw
      hotels
    end

    # Public: Find a hotel by info other than it's id.
    #
    # info - a Hash of options described in the Hotel
    #        accessors, excluding the id.
    #
    # Returns an Array of Hotels.
    def self.find_by_info(info)
      params = info.dup

      # Don't parse any params if using EAN's pagination
      unless params.keys.any?{ |k| [:cache_key, :cacheKey].include?(k.to_sym) }
        params["numberOfResults"] = params[:results] ? params[:results] : 10
        params.delete(:results)
        if params[:destination_id]
          params["destinationId"] = params[:destination_id]
          params.delete(:destination_id)
        elsif params[:location]
          params["destinationString"] = params[:location]
          params.delete(:location)
        end
      end

      if info[:arrival] && info[:departure]
        params["arrivalDate"] = info[:arrival]
        params["departureDate"] = info[:departure]
        params.delete(:arrival)
        params.delete(:departure)

        params.merge!(parameterize_rooms(info[:rooms] || [{ adults: 1 }]))
        params.delete(:rooms)
      end

      amenities = params[:amenities] ? params[:amenities].map {|amenity| 
        AMENITIES[amenity] 
      }.join(",") : nil
      params[:amenities] = amenities if amenities

      params["minRate"] = params[:min_rate] if params[:min_rate]
      params["maxRate"] = params[:max_rate] if params[:max_rate]

      if Configuration.cache? and Configuration.cache.cached?(:list, params)
        parsed = Configuration.cache.get_query(:list, params)
      else
        # Handle large queries as post request
        if info[:large_query]
          url = url(as_form: true, method: "list", params: params, session: info[:session])
        else
          url = url(method: "list", params: params, session: info[:session])
        end
        parsed = parse_response(url, params, info)
        handle_errors(parsed)
        if Configuration.cache?
          Configuration.cache.save_query(:list, params, parsed)
        end
      end
      
      hotels = [split(parsed)].flatten.map do |hotel_data|
        h = HotelFromList.new("HotelSummary" => hotel_data)
      end;hotels.first.raw = parsed
      
      update_session(parsed, info[:session])

      info[:results] ? hotels[0..(info[:results]-1)] : hotels
    end

    # Public: Parse the information returned by a search request.
    #
    # parsed - A Hash representing the parsed JSON.
    #
    # Returns a reformatted Hash with the specified accessors.
    def self.parse_information(parsed)
      handle_errors(parsed)
      
      if parsed["hotelId"]
        summary = parsed
        parsed_info = {}
      else
        res = parsed["HotelInformationResponse"]
        summary = res["HotelSummary"]
        parsed_info = {
          general_policies: res["HotelDetails"]["hotelPolicy"],
          checkin_instructions: res["HotelDetails"]["checkInInstructions"]
        }
      end
      proximity_distance = summary["proximityDistance"].to_s
      proximity_distance << summary["proximityUnit"].to_s
      parsed_info.merge!(
        id: summary["hotelId"],
        name: summary["name"],
        address: summary["address1"],
        city: summary["city"],
        postal_code: summary["postalCode"],
        country_code: summary["countryCode"],
        rating: summary["hotelRating"],
        high_rate: summary["highRate"],
        low_rate: summary["lowRate"],
        latitude: summary["latitude"].to_f,
        longitude: summary["longitude"].to_f,
        province: summary["stateProvinceCode"],
        airport_code: summary["airportCode"],
        property_category: summary["propertyCategory"].to_i,
        proximity_distance: proximity_distance,
        tripadvisor_rating: summary["tripAdvisorRating"],
        tripadvisor_rating_url: summary["tripAdvisorRatingUrl"],
        tripadvisor_review_count: summary["tripAdvisorReviewCount"],
        deep_link: summary["deepLink"]
      )
      parsed_info[:amenities] = parsed["HotelInformationResponse"]["PropertyAmenities"]["PropertyAmenity"].map do |x|
        Amenity.new(id: x["amenityId"], description: x["amenity"])
      end if parsed["HotelInformationResponse"]
      parsed_info[:images] = parse_images(parsed) if parse_images(parsed)
      if parsed["HotelInformationResponse"]
        parsed_info[:property_description] = parsed["HotelInformationResponse"]["HotelDetails"]["propertyDescription"]
        parsed_info[:number_of_rooms] = parsed["HotelInformationResponse"]["HotelDetails"]["numberOfRooms"]
        parsed_info[:number_of_floors] = parsed["HotelInformationResponse"]["HotelDetails"]["numberOfFloors"]
      end
      if summary["locationDescription"]
        parsed_info[:location_description] = summary["locationDescription"]
      end
      parsed_info[:short_description] = summary["shortDescription"]
      parsed_info[:amenity_mask] = summary["amenityMask"]
      parsed_info[:masked_amenities] = Amenity.parse_mask(parsed_info[:amenity_mask])

      parsed_info
    end

    # Internal: Get images from the parsed JSON.
    #
    # parsed - A Hash representing the parsed JSON.
    #
    # Returns an Array of Image.
    def self.parse_images(parsed)
      images = parsed["HotelInformationResponse"]["HotelImages"]["HotelImage"].map do |image_data|
        Suitcase::Image.new(image_data)
      end if parsed["HotelInformationResponse"] && parsed["HotelInformationResponse"]["HotelImages"] && parsed["HotelInformationResponse"]["HotelImages"]["HotelImage"]
      
      unless parsed["HotelSummary"].nil? or parsed["HotelSummary"]["thumbNailUrl"].nil? or parsed["HotelSummary"]["thumbNailUrl"].empty?
        images = [Suitcase::Image.new("thumbnailURL" => "http://images.travelnow.com" + parsed["HotelSummary"]["thumbNailUrl"])]
      end

      images || []
    end

    # Internal: Split an Array of multiple Hotels.
    #
    # parsed - The parsed JSON of the Hotels.
    #
    # Returns an Array of Hashes representing Hotels.
    def self.split(parsed)
      hotels = parsed["HotelListResponse"]["HotelList"]
      hotels["HotelSummary"]
    end

    # Public: Get the thumbnail URL of the image.
    #
    # Returns a String URL to the image thumbnail.
    def thumbnail_url
      first_image = images.find { |img| img.thumbnail_url != nil }
      first_image.thumbnail_url if first_image
    end

    # Public: Fetch possible rooms from a Hotel.
    #
    # info - A Hash of options that are the accessors in Rooms.
    #
    # Returns an Array of Rooms.
    def rooms(info)
      params = { rooms: [{adults: 1, children_ages: []}] }.merge(info)
      params.merge!(Hotel.parameterize_rooms(params[:rooms]))
      params["arrivalDate"] = info[:arrival]
      params["departureDate"] = info[:departure]
      params["includeDetails"] = true
      params.delete(:arrival)
      params.delete(:departure)
      params["hotelId"] = self.id

      if Configuration.cache? and Configuration.cache.cached?(:avail, params)
        parsed = Configuration.cache.get_query(:avail, params)
      else
        parsed = Hotel.parse_response(Hotel.url(method: "avail", params: params, session: info[:session]))
        Hotel.handle_errors(parsed)
        if Configuration.cache?
          Configuration.cache.save_query(:avail, params, parsed)
        end
      end
      res = parsed["HotelRoomAvailabilityResponse"]
      hotel_room_res = [res["HotelRoomResponse"]].flatten
      hotel_id = res["hotelId"]
      rate_key = res["rateKey"]
      supplier_type = hotel_room_res[0]["supplierType"]
      Hotel.update_session(parsed, info[:session])

      hotel_room_res.map do |raw_data|
        room_data = {}
        room_data[:non_refundable] = raw_data["nonRefundable"]
        room_data[:deposit_required] = raw_data["depositRequired"]
        room_data[:guarantee_only] = raw_data["guaranteeRequired"]
        room_data[:cancellation_policy] = raw_data["cancellationPolicy"]
        room_data[:rate_code] = raw_data["rateCode"]
        room_data[:room_type_code] = raw_data["roomTypeCode"]
        room_data[:room_type_description] = raw_data["roomTypeDescription"]
        room_data[:rate_description] = raw_data["rateDescription"]

        rate_info = raw_data["RateInfos"]["RateInfo"]
        room_data[:promo] = rate_info["@promo"].to_b
        if rate_info["ChargeableRateInfo"] &&
           rate_info["ChargeableRateInfo"]["NightlyRatesPerRoom"] &&
           rate_info["ChargeableRateInfo"]["NightlyRatesPerRoom"]["NightlyRate"]
          nightly_rates = rate_info["ChargeableRateInfo"]["NightlyRatesPerRoom"]["NightlyRate"]
          nightly_rates = [ nightly_rates ].flatten # convert 1-night stays to arrays
          room_data[:price_breakdown] = nightly_rates.map do |raw_nightly_rate| 
            NightlyRate.new(raw_nightly_rate)
          end
        end
        room_data[:total_price] = rate_info["ChargeableRateInfo"]["@total"]
        room_data[:max_nightly_rate] = rate_info["ChargeableRateInfo"]["@maxNightlyRate"]
        room_data[:nightly_rate_total] = rate_info["ChargeableRateInfo"]["@nightlyRateTotal"]
        room_data[:average_nightly_rate] = rate_info["ChargeableRateInfo"]["@averageRate"]
        room_data[:average_nightly_base_rate] = rate_info["ChargeableRateInfo"]["@averageBaseRate"]
        room_data[:surcharges] = rate_info["ChargeableRateInfo"] &&
          rate_info["ChargeableRateInfo"]["Surcharges"] &&
          [rate_info["ChargeableRateInfo"]["Surcharges"]["Surcharge"]].
            flatten.map { |s| Surcharge.parse(s) }

        room_data[:rate_change] = raw_data["rateChange"]
        room_data[:arrival] = info[:arrival]
        room_data[:departure] = info[:departure]
        room_data[:rate_key] = rate_key
        room_data[:hotel_id] = hotel_id
        room_data[:supplier_type] = supplier_type
        room_data[:rooms] = params[:rooms]
                room_data[:bed_types] = [raw_data["BedTypes"]["BedType"]].flatten.map do |x|
          BedType.new(id: x["@id"], description: x["description"])
        end if raw_data["BedTypes"] && raw_data["BedTypes"]["BedType"]

        r = Room.new(room_data)
        r.raw = parsed
        r
      end
    end
  end
  
  module HotelTranslations
    def self.included(base)
      base.translate "HotelDetails.areaInformation", :into => :area_information
      base.translate "HotelDetails.checkInInstructions", :into => :checkin_instructions
      base.translate "HotelDetails.checkInTime", :into => :check_in_time
      base.translate "HotelDetails.checkOutTime", :into => :check_out_time
      base.translate "HotelDetails.drivingDirections", :into => :driving_directions
      base.translate "HotelDetails.hotelPolicy", :into => :general_policies
      base.translate "HotelDetails.numberOfFloors", :into => :number_of_floors
      base.translate "HotelDetails.numberOfRooms", :into => :number_of_rooms
      base.translate "HotelDetails.propertyDescription", :into => :property_description
      base.translate "HotelDetails.propertyInformation", :into => :property_information
      base.translate "HotelDetails.roomInformation", :into => :room_information
      
      base.translate "HotelSummary.address1", :into => :address
      base.translate "HotelSummary.airportCode", :into => :airport_code
      base.translate "HotelSummary.amenityMask", :into => :amenity_mask
      base.translate "HotelSummary.amenityMask", :into => :masked_amenities, :using => lambda { |amenityMask| 
        Suitcase::Hotel::Amenity.parse_mask(amenityMask) 
      }
      base.translate "HotelSummary.city", :into => :city
      base.translate "HotelSummary.confidenceRating", :into => :confidence_rating
      base.translate "HotelSummary.countryCode", :into => :country_code
      base.translate "HotelSummary.deepLink", :into => :deep_link
      base.translate "HotelSummary.highRate", :into => :high_rate
      base.translate "HotelSummary.hotelId", :into => :id
      base.translate "HotelSummary.hotelInDestination", :into => :hotel_in_destination
      base.translate "HotelSummary.hotelRating", :into => :rating
      base.translate "HotelSummary.latitude", :into => :latitude, :using => lambda { |latitude| latitude.to_f }
      base.translate "HotelSummary.locationDescription", :into => :location_description
      base.translate "HotelSummary.longitude", :into => :longitude, :using => lambda { |longitude| longitude.to_f }
      base.translate "HotelSummary.lowRate", :into => :low_rate
      base.translate "HotelSummary.name", :into => :name
      base.translate "HotelSummary.postalCode", :into => :postal_code
      base.translate "HotelSummary.propertyCategory", :into => :property_category, :using => lambda { |property_category| property_category.to_i }
      base.translate "HotelSummary.proximityDistance", :into => :proximity_distance_original
      base.translate "HotelSummary.proximityUnit", :into => :proximity_unit_original
      base.translate "HotelSummary.rateCurrencyCode", :into => :rate_currency_code
      base.translate "HotelSummary.shortDescription", :into => :short_description
      base.translate "HotelSummary.stateProvinceCode", :into => :province
      base.translate "HotelSummary.supplierType", :into => :supplier_type
      base.translate "HotelSummary.tripAdvisorRating", :into => :tripadvisor_rating
      base.translate "HotelSummary.tripAdvisorRatingUrl", :into => :tripadvisor_rating_url
      base.translate "HotelSummary.tripAdvisorReviewCount", :into => :tripadvisor_review_count
      base.translate "HotelSummary.RoomRateDetailsList.RoomRateDetails.RateInfos.RateInfo.@promo", :into => :promo?, :using => lambda { |promo| promo == "true" }
      base.translate "HotelSummary.RoomRateDetailsList.RoomRateDetails.promoDescription", :into => :promo_description
      base.translate "HotelSummary.RoomRateDetailsList.RoomRateDetails.RateInfos.RateInfo.ChargeableRateInfo.@averageRate", :into => :average_rate, :using => lambda { |rate| rate.to_f }
      base.translate "HotelSummary.RoomRateDetailsList.RoomRateDetails.RateInfos.RateInfo.ChargeableRateInfo.@averageBaseRate", :into => :average_base_rate, :using => lambda { |rate| rate.to_f }
      
      base.translate "PropertyAmenities.PropertyAmenity", :into => :amenities, :using => lambda { |amenities|
        amenities.map do |property_amenity|
          Suitcase::Hotel::Amenity.new(id: property_amenity["amenityId"], description: property_amenity["amenity"])
        end
      }
      base.translate "RoomTypes.RoomType", :into => :room_types, :using => lambda { |room_types| 
        room_types.map do |room_type|
          Suitcase::Hotel::RoomType.new(:description => room_type["description"],
            :description_long => room_type["descriptionLong"],
            :room_amenities => room_type["roomAmenities"]["RoomAmenity"],
            :room_code => room_type["@roomCode"], 
            :room_type_id => room_type["@roomTypeId"])
        end
      }
      base.translate "Suppliers.Supplier", :into => :suppliers, :using => lambda { |suppliers| 
        suppliers.map do |supplier|
          Suitcase::Hotel::Supplier.new(id: supplier["@id"], chain_code: supplier["@chainCode"])
        end
      }
    end
  end
  
  class HotelWithDetails < Hotel
    translation_root "HotelInformationResponse"
    include HotelTranslations
  end
  
  class HotelFromList < Hotel
    include HotelTranslations
  end
end
