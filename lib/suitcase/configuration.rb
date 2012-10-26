module Suitcase
  def self.configure(&block)
    block.call(Configuration)
  end

  class Configuration
    class << self
      attr_accessor :hotel_api_key, :hotel_cid, :hotel_shared_secret,
                    :hotwire_api_key, :hotwire_linkshare_id, :use_signature_auth

      attr_writer :ean_revision
      attr_reader :cache

      def ean_revision
        @ean_revision || 15
      end

      def cache=(mechanism)
        @cache = Suitcase::Hotel::Cache.new(mechanism)
      end

      def use_signature_auth?
        @use_signature_auth
      end

      def method_missing(method, *args, &blk)
        if method.to_s =~ /(.+)\?/
          send($1.to_sym)
        end
      end
    end
  end
end
