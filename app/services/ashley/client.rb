module Ashley
  class Client
    # Ashley credentials from ENV
    BASE_URL = ENV.fetch('ASHLEY_API_BASE_URL', 'https://api.ashleyfurniture.com').freeze
    CREDENTIAL = ENV.fetch('ASHLEY_API_CREDENTIAL', 'jebris').freeze

    class Error < StandardError; end
    class RecordNotFoundError < Error; end

    def get_product(sku)
      response = connection.get("/api/v1/products/#{sku}")

      if response.success?
        JSON.parse(response.body)
      elsif response.status == 404
        raise RecordNotFoundError, "Product not found for SKU: #{sku}"
      else
        raise Error, "Ashley API error: #{response.status} - #{response.body}"
      end
    rescue Faraday::Error => e
      raise Error, "Faraday connection error: #{e.message}"
    rescue JSON::ParserError => e
      raise Error, "JSON parse error: #{e.message}"
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |conn|
        conn.request :json
        conn.response :logger if Rails.env.development?
        conn.adapter Faraday.default_adapter
        # Typical header setup
        conn.headers['Authorization'] = "Bearer #{CREDENTIAL}"
        conn.headers['Accept'] = 'application/json'
        conn.headers['Content-Type'] = 'application/json'
      end
    end
  end
end
