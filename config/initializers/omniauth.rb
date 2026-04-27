OmniAuth.config.full_host = if Rails.env.production?
  host = ENV.fetch("APP_HOST", "warehouse-furniture.com").sub(%r{\Ahttps?://}, "")
  "https://#{host}"
end

OmniAuth.config.on_failure = proc { |env|
  error      = env["omniauth.error"]
  error_type = env["omniauth.error.type"]
  strategy   = env["omniauth.error.strategy"]
  Rails.logger.error "[OmniAuth Failure] type=#{error_type} error=#{error&.message} " \
                     "strategy=#{strategy&.name} " \
                     "callback_url=#{strategy&.callback_url rescue 'N/A'}"
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
