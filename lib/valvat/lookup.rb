class Valvat
  class Lookup
    REMOVE_KEYS = [:valid, :@xmlns]

    attr_reader :vat, :options

    def initialize(vat, options={})
      @vat = Valvat(vat)
      @options = options || {}
    end

    def validate
      return false unless vat.european?

      valid? && show_details? ? response_details : valid?
    rescue => error
      return false if invalid_input?(error)
      raise error  if options[:raise_error]
      nil
    end

    class << self
      def validate(vat, options={})
        new(vat, options).validate
      end
    end

    private

    def valid?
      response[:valid]
    end

    def response
      @response ||= Request.new(vat, options).perform
    end

    def invalid_input?(err)
      return if !err.respond_to?(:to_hash) || !err.to_hash[:fault]
      (err.to_hash[:fault][:faultstring] || "").upcase =~ /INVALID_INPUT/
    end

    def show_details?
      options[:requester_vat] || options[:detail]
    end

    def response_details
      response.inject({}) do |hash, kv|
        key, value = kv
        unless REMOVE_KEYS.include?(key)
          hash[key.to_s.sub(/^trader_/, "").to_sym] = (value == "---" ? nil : value)
        end
        hash
      end
    end
  end
end
