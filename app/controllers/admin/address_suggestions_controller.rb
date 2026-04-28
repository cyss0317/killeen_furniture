module Admin
  class AddressSuggestionsController < BaseController
    require "net/http"

    def index
      q = params[:q].to_s.strip
      return render json: [] if q.length < 4

      uri = URI("https://nominatim.openstreetmap.org/search")
      uri.query = URI.encode_www_form(
        q:              q,
        format:         "json",
        countrycodes:   "us",
        limit:          6,
        addressdetails: 1
      )

      http          = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl  = true
      http.open_timeout = 3
      http.read_timeout = 5

      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "WarehouseFurniture/1.0 (#{ENV.fetch('MAIL_FROM', 'info@warehousefurnituretx.com')})"
      request["Accept-Language"] = "en-US,en"

      response = http.request(request)
      render json: JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error "[AddressSuggestions] #{e.message}"
      render json: []
    end
  end
end
