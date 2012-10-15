module Suitcase
  class Hotel < TranslatedHash
    class Supplier
      attr_accessor :id, :chain_code

      def initialize(info)
        @id, @chain_code = info[:id], info[:chain_code]
      end
    end
  end
end
