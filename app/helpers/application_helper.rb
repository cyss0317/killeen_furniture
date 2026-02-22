module ApplicationHelper
  def google_maps_url(address_hash)
    parts = [
      address_hash["street_address"],
      address_hash["city"],
      address_hash["state"],
      address_hash["zip_code"]
    ].compact
    "https://www.google.com/maps/search/?api=1&query=#{CGI.escape(parts.join(', '))}"
  end
end
