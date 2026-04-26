OmniAuth.config.full_host = Rails.env.production? ? "https://#{ENV.fetch('APP_HOST', 'warehouse-furniture.com')}" : nil
