require "net/http"
require "uri"
require "nokogiri"

module Ashley
  # Authenticates with the classic Ashley Direct ASP.NET portal via plain HTTP
  # (no headless browser — avoids PerimeterX entirely), scrapes the YTD invoices
  # page, and creates stub POs for any invoices not yet in the database.
  class InvoiceSyncer
    Result = Struct.new(:created, :skipped, :errors, keyword_init: true)

    BASE         = "https://www.ashleydirect.com"
    LOGIN_PATH   = "/SiteLogin/Forms/Login.aspx"
    INVOICE_PATH = "/InvoiceReporting/YTDInvoices.aspx"

    HEADERS = {
      "User-Agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
      "Accept"          => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language" => "en-US,en;q=0.9",
      "Accept-Encoding" => "gzip, deflate, br",
      "Connection"      => "keep-alive"
    }.freeze

    def self.call(created_by: nil)
      new(created_by: created_by).call
    end

    def initialize(created_by: nil)
      @created_by = created_by
      @cookie_jar = {}
    end

    def call
      # 1) Try pre-exported classic portal cookies first (fastest, no login needed)
      if ENV["ASHLEY_CLASSIC_COOKIES"].present?
        load_classic_cookies
        if session_valid?
          Rails.logger.info "[InvoiceSyncer] Classic portal cookies valid — skipping login"
        else
          Rails.logger.warn "[InvoiceSyncer] Classic portal cookies expired — falling back to Selenium login"
          return Result.new(created: [], skipped: [], errors: [
            "ASHLEY_CLASSIC_COOKIES are expired. Please refresh them: log into " \
            "www.ashleydirect.com in Chrome, open DevTools → Application → Cookies → " \
            "export all cookies for www.ashleydirect.com as JSON, and update ASHLEY_CLASSIC_COOKIES."
          ])
        end
      else
        # 2) HTTP form login (blocked by PerimeterX on server IPs — may still work
        #    on first attempt or if IP reputation is clean)
        Rails.logger.info "[InvoiceSyncer] Attempting HTTP form authentication"
        session_ok = authenticate
        unless session_ok
          return Result.new(created: [], skipped: [], errors: [
            "Authentication failed — PerimeterX is blocking server login attempts. " \
            "Set ASHLEY_CLASSIC_COOKIES: log into www.ashleydirect.com, export cookies as JSON."
          ])
        end
      end

      Rails.logger.info "[InvoiceSyncer] Fetching invoice list"
      rows = fetch_invoices
      Rails.logger.info "[InvoiceSyncer] Found #{rows.size} invoice rows"

      created = []
      skipped = []
      errors  = []

      rows.each do |row|
        invoice_num = row[:invoice_number]
        next if invoice_num.blank?

        if PurchaseOrder.exists?(reference_number: invoice_num)
          skipped << invoice_num
          next
        end

        begin
          po = PurchaseOrder.create!(
            reference_number: invoice_num,
            status:           :submitted,
            brand:            "Ashley Furniture",
            invoice_date:     row[:invoice_date],
            ordered_at:       row[:order_date] || row[:invoice_date],
            notes:            build_notes(row),
            created_by:       @created_by
          )
          created << po
        rescue => e
          errors << "#{invoice_num}: #{e.message}"
          Rails.logger.error "[InvoiceSyncer] Failed #{invoice_num}: #{e.message}"
        end
      end

      latest = rows.filter_map { |r| r[:invoice_date] || r[:order_date] }.max
      GlobalSetting.set("ashley_last_synced_invoice_date", latest.to_s) if latest

      Rails.logger.info "[InvoiceSyncer] created=#{created.size} skipped=#{skipped.size} errors=#{errors.size}"
      Result.new(created: created, skipped: skipped, errors: errors)
    rescue => e
      Rails.logger.error "[InvoiceSyncer] Fatal: #{e.class} — #{e.message}"
      Result.new(created: [], skipped: [], errors: [e.message])
    end

    private

    # ── Authentication ────────────────────────────────────────────────────────

    def session_valid?
      # Quick test request — if we're redirected to login, the session is expired
      req = Net::HTTP::Get.new(INVOICE_PATH)
      HEADERS.each { |k, v| req[k] = v }
      req["Cookie"] = cookie_header
      res = http.request(req)
      store_cookies(res)

      valid = res.code.to_i == 200 && !res.body.to_s.include?("SiteLogin")
      Rails.logger.info "[InvoiceSyncer] Session check: #{res.code} — #{valid ? 'valid' : 'expired'}"
      valid
    rescue => e
      Rails.logger.warn "[InvoiceSyncer] Session check failed: #{e.message}"
      false
    end

    def load_classic_cookies
      JSON.parse(ENV["ASHLEY_CLASSIC_COOKIES"]).each do |c|
        name = c["name"].to_s.strip
        @cookie_jar[name] = c["value"].to_s.strip if name.present?
      end
      Rails.logger.info "[InvoiceSyncer] Loaded #{@cookie_jar.size} classic portal cookies"
    rescue => e
      Rails.logger.error "[InvoiceSyncer] Cookie parse error: #{e.message}"
    end

    def self.cookies_configured? = ENV["ASHLEY_CLASSIC_COOKIES"].present?

    def authenticate
      # Step 1: GET login page — collect ViewState + cookies
      login_html = get(LOGIN_PATH)
      return false unless login_html

      doc = Nokogiri::HTML(login_html)
      viewstate        = doc.at_css("input[name='__VIEWSTATE']")&.[]("value").to_s
      event_validation = doc.at_css("input[name='__EVENTVALIDATION']")&.[]("value").to_s
      viewstate_gen    = doc.at_css("input[name='__VIEWSTATEGENERATOR']")&.[]("value").to_s

      # Step 2: POST credentials
      form_data = URI.encode_www_form(
        "__VIEWSTATE"          => viewstate,
        "__VIEWSTATEGENERATOR" => viewstate_gen,
        "__EVENTVALIDATION"    => event_validation,
        "txtUserID"            => ENV["ASHLEY_DIRECT_EMAIL"].to_s,
        "txtPassword"          => ENV["ASHLEY_DIRECT_PASSWORD"].to_s,
        "cmdLogin"             => "Sign In"
      )

      response = post(LOGIN_PATH, form_data, referer: "#{BASE}#{LOGIN_PATH}")
      # Successful login → 302 redirect away from the login page
      location = response["location"].to_s
      Rails.logger.info "[InvoiceSyncer] Login response: #{response.code} → #{location.first(80)}"

      response.code.to_i == 302 && !location.include?("Login")
    end

    # ── Invoice scraping ──────────────────────────────────────────────────────

    def fetch_invoices
      html = get(INVOICE_PATH)
      return [] unless html

      doc = Nokogiri::HTML(html)

      # Find data rows — rows with 10+ td cells containing a numeric invoice #
      rows = []
      doc.css("tr").each do |tr|
        cells = tr.css("td").map { |td| td.text.strip }
        next if cells.size < 10
        next unless cells[1]&.match?(/\A\d{6,}\z/)

        rows << {
          invoice_number: cells[1],
          invoice_date:   parse_date(cells[4]),
          order_number:   cells[5].presence,
          order_date:     parse_date(cells[6]),
          po_number:      cells[9].presence,
          invoice_amount: cells[10].gsub(/[^0-9.]/, "").to_f
        }
      end
      rows
    end

    # ── HTTP helpers ──────────────────────────────────────────────────────────

    def http
      @http ||= begin
        uri  = URI.parse(BASE)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl     = true
        http.open_timeout = 15
        http.read_timeout = 30
        http
      end
    end

    def cookie_header
      @cookie_jar.map { |k, v| "#{k}=#{v}" }.join("; ")
    end

    def store_cookies(response)
      Array(response.get_fields("set-cookie")).each do |line|
        name, value = line.split(";").first.to_s.split("=", 2)
        @cookie_jar[name.strip] = value.to_s.strip if name.present?
      end
    end

    def get(path, referer: nil)
      req = Net::HTTP::Get.new(path)
      HEADERS.each { |k, v| req[k] = v }
      req["Cookie"]  = cookie_header
      req["Referer"] = referer if referer

      res = http.request(req)
      store_cookies(res)

      # Handle gzip
      body = res.body.to_s
      if res["content-encoding"] == "gzip"
        require "zlib"
        body = Zlib::GzipReader.new(StringIO.new(body)).read
      end

      res.code.to_i == 200 ? body : nil
    end

    def post(path, form_data, referer: nil)
      req = Net::HTTP::Post.new(path)
      HEADERS.each { |k, v| req[k] = v }
      req["Cookie"]       = cookie_header
      req["Referer"]      = referer if referer
      req["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = form_data

      res = http.request(req)
      store_cookies(res)
      res
    end

    # ── Helpers ───────────────────────────────────────────────────────────────

    def build_notes(row)
      parts = []
      parts << "Order #: #{row[:order_number]}"   if row[:order_number].present?
      parts << "PO Ref: #{row[:po_number]}"        if row[:po_number].present?
      parts << "Inv Amt: $#{'%.2f' % row[:invoice_amount]}" if row[:invoice_amount].to_f > 0
      parts << "Synced from Ashley Direct — import PDF to add line items"
      parts.join(" | ")
    end

    def parse_date(str)
      return nil if str.blank?
      Date.strptime(str.strip, "%m/%d/%Y")
    rescue ArgumentError
      nil
    end
  end
end
