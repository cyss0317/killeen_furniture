module PurchaseOrders
  class ImportScreenshot
    Result = Struct.new(:purchase_order, :created_products, :updated_products, :skipped_rows, :error, keyword_init: true) do
      def success? = error.nil?
    end

    SUPPORTED_MEDIA_TYPES = {
      "image/jpeg" => "image/jpeg",
      "image/jpg"  => "image/jpeg",
      "image/png"  => "image/png",
      "image/gif"  => "image/gif",
      "image/webp" => "image/webp"
    }.freeze

    ASHLEY_PROMPT = <<~PROMPT.freeze
      This is an Ashley Furniture order document (order confirmation, invoice, or dealer portal screenshot).
      Extract the invoice/order number and all product line items. Return ONLY valid JSON — no markdown, no explanation:

      {
        "invoice_number": "ASH-2026-001",
        "items": [
          {
            "item_code": "B1190-31",
            "description": "Six Drawer Dresser",
            "series": "Gerridan",
            "color": "White/Gray",
            "qty": 1,
            "price": 189.50
          }
        ]
      }

      Rules:
      - invoice_number: the order/invoice/PO number shown on the document (empty string "" if not visible)
      - item_code: Ashley SKU / item code (e.g. "B1190-31", "8376-92")
      - description: product name or description text
      - series: furniture collection or series name (empty string "" if not shown)
      - color: color or finish name (empty string "" if not shown)
      - qty: integer quantity from the Qty or Ordered column
      - price: unit wholesale price as a decimal (use the "Price" column, NOT "Ext. Price")
      - Skip rows that are section headers, subtotals, shipping lines, or blank
      - items must be an empty array [] if no valid line items are found
    PROMPT

    GENERATION_TRADE_PROMPT = <<~PROMPT.freeze
      This is a Generation Trade order document (order confirmation, invoice, or portal screenshot).
      Extract the invoice/order number and all product line items. Return ONLY valid JSON — no markdown, no explanation:

      {
        "invoice_number": "GT-2026-001",
        "items": [
          {
            "item_code": "GT-1234",
            "description": "Accent Chair",
            "series": "",
            "color": "Gray",
            "qty": 2,
            "price": 245.00
          }
        ]
      }

      Rules:
      - invoice_number: the order/invoice/PO number shown on the document (empty string "" if not visible)
      - item_code: Generation Trade SKU / item code
      - description: product name or description text
      - series: collection or series name (empty string "" if not shown)
      - color: color or finish name (empty string "" if not shown)
      - qty: integer quantity
      - price: unit wholesale price as a decimal (unit price, NOT extended/total)
      - Skip rows that are section headers, subtotals, shipping lines, or blank
      - items must be an empty array [] if no valid line items are found
    PROMPT

    SUPPLIER_PROMPTS = {
      "ashley"           => ASHLEY_PROMPT,
      "generation_trade" => GENERATION_TRADE_PROMPT
    }.freeze

    def self.call(...) = new(...).call

    def initialize(file:, reference_number: nil, ordered_at: nil, notes: nil, created_by: nil, supplier: "ashley")
      @file             = file
      @reference_number = reference_number.to_s.strip.presence
      @ordered_at       = ordered_at
      @notes            = notes
      @created_by       = created_by
      @supplier         = supplier.to_s.presence || "ashley"
    end

    def call
      image_data, media_type = read_image
      return Result.new(error: "Unsupported file type. Please upload a JPEG, PNG, WebP, or GIF image.") unless media_type

      extracted = extract_via_claude(image_data, media_type)
      return Result.new(error: extracted) if extracted.is_a?(String)  # error message

      invoice_number = extracted["invoice_number"].to_s.strip.presence
      raw_items      = Array(extracted["items"])

      # Resolve reference number: use manually entered one, fall back to extracted
      ref = @reference_number || invoice_number
      return Result.new(error: "Could not determine invoice number. Please enter it manually or ensure it is visible in the image.") if ref.blank?

      return Result.new(error: "No order items could be found in the image.") if raw_items.empty?

      created_products = []
      updated_products = []
      skipped_rows     = []
      po               = nil
      supplier_category = nil

      ActiveRecord::Base.transaction do
        line_items = []

        raw_items.each_with_index do |item, i|
          sku   = item["item_code"].to_s.strip.upcase
          qty   = item["qty"].to_i
          price = item["price"].to_d

          if sku.blank?
            skipped_rows << "Item #{i + 1}: missing item code"
            next
          end

          if qty <= 0 || price <= 0
            skipped_rows << "#{sku}: skipped (qty=#{qty}, price=#{price})"
            next
          end

          description = item["description"].to_s.strip
          series      = item["series"].to_s.strip
          color       = item["color"].to_s.strip

          product = Product.find_by(sku: sku)

          if product
            updates = {}
            updates[:name]  = description if description.present? && product.name != description
            updates[:brand] = series       if series.present? && product.brand != series
            updates[:color] = color        if color.present? && product.color != color
            product.update!(updates) if updates.any?
            product.increment!(:stock_quantity, qty)
            updated_products << product unless updated_products.include?(product)
          else
            supplier_category ||= Category.find_or_create_by!(name: supplier_category_name)
            product = Product.create!(
              sku:            sku,
              name:           description.presence || sku,
              brand:          series.presence,
              color:          color.presence,
              base_cost:      price,
              stock_quantity: qty,
              status:         :draft,
              category:       supplier_category
            )
            created_products << product
          end

          # Best-effort: enrich product details from supplier website
          enrich_product!(product, series: series, description: description)

          line_items << {
            product:          product,
            quantity_ordered: qty,
            unit_cost:        price,
            product_name:     product.reload.name,
            product_sku:      product.sku
          }
        end

        raise "No valid line items found in the image." if line_items.empty?

        po = PurchaseOrder.create!(
          reference_number: ref,
          status:           :submitted,
          ordered_at:       @ordered_at,
          notes:            @notes,
          created_by:       @created_by
        )

        line_items.each { |attrs| po.purchase_order_items.create!(attrs) }
      end

      Result.new(
        purchase_order:   po,
        created_products: created_products,
        updated_products: updated_products,
        skipped_rows:     skipped_rows
      )
    rescue ActiveRecord::RecordInvalid => e
      Result.new(error: e.message)
    rescue => e
      Result.new(error: e.message)
    end

    private

    def supplier_category_name
      case @supplier
      when "generation_trade" then "Generation Trade"
      else "Ashley Furniture"
      end
    end

    def enrich_product!(product, series:, description:)
      case @supplier
      when "generation_trade"
        Products::FetchFromGenerationTrade.enrich!(product, series: series, description: description)
      else
        Products::FetchFromAshley.enrich!(product, series: series, description: description)
      end
    end

    def read_image
      data       = @file.read
      raw_type   = @file.content_type.to_s.split(";").first.strip.downcase
      media_type = SUPPORTED_MEDIA_TYPES[raw_type]
      [Base64.strict_encode64(data), media_type]
    end

    def extraction_prompt
      SUPPLIER_PROMPTS[@supplier] || ASHLEY_PROMPT
    end

    def extract_via_claude(image_data, media_type)
      api_key = ENV["ANTHROPIC_API_KEY"] || Rails.application.credentials.anthropic_api_key || "empty"
      return "Anthropic API key is not configured. Set ANTHROPIC_API_KEY in your environment." if api_key.blank?

      client = Anthropic::Client.new(api_key: api_key)

      message = client.messages.create(
        model:      "claude-haiku-4-5-20251001",
        max_tokens: 2048,
        messages: [{
          role:    "user",
          content: [
            {
              type:   "image",
              source: { type: "base64", media_type: media_type, data: image_data }
            },
            { type: "text", text: extraction_prompt }
          ]
        }]
      )

      text = message.content[0].text.strip
             .gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "").strip

      JSON.parse(text)
    rescue JSON::ParserError
      "Claude returned data in an unexpected format. Please try again."
    rescue Anthropic::Errors::AuthenticationError
      "Anthropic API key is invalid."
    rescue Anthropic::Errors::APIStatusError => e
      "Anthropic API error (#{e.status}): #{e.message}"
    rescue => e
      Rails.logger.error "[ImportScreenshot] Claude error: #{e.class} — #{e.message}"
      "Could not connect to the AI service. Please try again."
    end
  end
end
