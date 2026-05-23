# Bot scanners routinely probe for WordPress paths (/wp-includes/, /wp-content/),
# PHP files (/403.php, /gecko.php), etc. Rails logs each miss as a fatal
# ActionController::RoutingError via ActionDispatch::DebugExceptions, cluttering
# production logs with noise that has no operational value.
#
# This middleware intercepts RoutingErrors before DebugExceptions sees them,
# returning a silent 404 so nothing gets logged.
Rails.application.config.middleware.insert_before(
  ActionDispatch::DebugExceptions,
  Class.new {
    def initialize(app) = (@app = app)

    def call(env)
      @app.call(env)
    rescue ActionController::RoutingError
      [ 404, { "Content-Type" => "text/plain", "X-Content-Type-Options" => "nosniff" }, [ "Not Found" ] ]
    end
  }
)
