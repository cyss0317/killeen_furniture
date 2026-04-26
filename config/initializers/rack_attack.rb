class Rack::Attack
  ### Safelists ---------------------------------------------------------------

  # Never throttle requests from localhost in development
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  ### Throttles ----------------------------------------------------------------

  # Sign-up: max 5 account creations per IP per hour
  throttle("registrations/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/users" && req.post?
  end

  # Sign-in: max 10 attempts per IP per 20 seconds (brute-force guard)
  throttle("logins/ip", limit: 10, period: 20.seconds) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # Sign-in: max 5 attempts per email per 20 seconds (credential stuffing guard)
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email").to_s.downcase.strip.presence
    end
  end

  # Password reset: max 5 requests per IP per hour
  throttle("passwords/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/users/password" && req.post?
  end

  ### Response -----------------------------------------------------------------

  # Return 429 with a plain message instead of the default empty body
  self.throttled_responder = lambda do |env|
    match_data = env["rack.attack.match_data"]
    retry_after = match_data ? (match_data[:period] - (Time.now.to_i % match_data[:period])) : 60

    [
      429,
      {
        "Content-Type"  => "text/plain",
        "Retry-After"   => retry_after.to_s
      },
      ["Too many requests. Please try again later."]
    ]
  end
end
