module PurchaseOrders
  class ImportScreenshot
    Result = Struct.new(:purchase_order, :purchase_orders, :created_products, :updated_products, :skipped_rows, :supplier_name, :error, keyword_init: true) do
      def success? = error.nil?
    end

    SUPPORTED_MEDIA_TYPES = {
      "image/jpeg"      => "image/jpeg",
      "image/jpg"       => "image/jpeg",
      "image/png"       => "image/png",
      "image/gif"       => "image/gif",
      "image/webp"      => "image/webp",
      "application/pdf" => "application/pdf"
    }.freeze

    EXTRACTION_PROMPT = <<~PROMPT.freeze
      This is a furniture order document (order confirmation, invoice, or dealer portal screenshot) from a supplier (e.g., Ashley Furniture or Generation Trade).
      Extract the supplier name, invoice/order number, and ALL product line items from EVERY page. Do not skip or stop early — capture every single line item. Return ONLY valid JSON — no markdown, no explanation:

      {
        "supplier": "ashley",
        "invoice_number": "ASH-2026-001",
        "freight_cost": 125.00,
        "discount": 50.00,
        "items": [
          {
            "item_code": "B1190-31",
            "description": "Six Drawer Dresser",
            "category": "Dresser",
            "series": "Gerridan",
            "color": "White/Gray",
            "qty": 1,
            "price": 189.50
          }
        ]
      }

      Rules:
      - supplier: string identifying the supplier (e.g., "ashley", "generation_trade", etc.) based on logos or text. Use "ashley" for Ashley Furniture, "generation_trade" for Generation Trade.
      - invoice_number: the order/invoice/PO number shown on the document (empty string "" if not visible)
      - freight_cost: the freight, shipping, or delivery charge as a decimal (0 if not shown)
      - discount: any discount, rebate, or credit applied to the order as a decimal (0 if not shown)
      - item_code: The SKU / item code (e.g. "B1190-31" for Ashley, "GT-1234" for Generation Trade)
      - description: product name or description text
      - category: a 1-2 word category name (e.g. "Sofa", "Dresser", "Dining Table", "Bed"). Guess based on the description if not explicitly labeled and it shouldnt't be the same as brand.
      - series: furniture collection or series name (empty string "" if not shown)
      - color: color or finish name (empty string "" if not shown)
      - qty: integer quantity from the Qty or Ordered column
      - brand: "Ashley Furniture" or "Generation Trade" based on the supplier
      - price: unit wholesale price as a decimal (use the "Price" or unit price column, NOT extended/total)
      - Skip rows that are section headers, subtotals, or blank — but DO capture freight/shipping charges in freight_cost
      - items must be an empty array [] if no valid line items are found
    PROMPT

    # PDF variant — always returns a JSON ARRAY so multiple invoices in one PDF
    # each become their own element (and thus their own PurchaseOrder).
    PDF_EXTRACTION_PROMPT = <<~PROMPT.freeze
      This PDF may contain one or more furniture invoices/orders from a supplier (e.g., Ashley Furniture or Generation Trade).
      Extract ALL invoices separately. Return a JSON ARRAY — one element per distinct invoice/order number. Do not merge invoices. Do not skip pages. Return ONLY valid JSON — no markdown, no explanation:

      [
        {
          "supplier": "ashley",
          "invoice_number": "ASH-2026-001",
          "freight_cost": 125.00,
          "discount": 50.00,
          "items": [
            {
              "item_code": "B1190-31",
              "description": "Six Drawer Dresser",
              "category": "Dresser",
              "series": "Gerridan",
              "color": "White/Gray",
              "qty": 1,
              "price": 189.50
            }
          ]
        }
      ]

      Rules:
      - Each unique invoice/order number is a SEPARATE element in the array
      - If only one invoice is present, still return a single-element array: [{ ... }]
      - supplier: "ashley" or "generation_trade" based on logos or text
      - invoice_number: the order/invoice/PO number (empty string "" if not visible)
      - item_code: The SKU / item code
      - description: product name or description text
      - category: a 1-2 word category name (e.g. "Sofa", "Dresser"). Guess from description if not labeled.
      - series: furniture collection/series name (empty string "" if not shown)
      - color: color or finish name (empty string "" if not shown)
      - qty: integer quantity from the Qty or Ordered column
      - freight_cost: freight, shipping, or delivery charge as a decimal (0 if not shown)
      - discount: any discount, rebate, or credit applied to the order as a decimal (0 if not shown)
      - price: unit wholesale price as a decimal (NOT extended/total)
      - Skip section headers and subtotals — but DO capture freight/shipping charges in freight_cost
      - items must be an empty array [] if no valid line items are found for that invoice
    PROMPT

    def self.call(...) = new(...).call

    # Extracts supplier + items from a single file via Claude.
    # Returns the parsed hash or a String error message.
    def self.extract(file)
      instance = new(file: file)
      image_data, media_type = instance.send(:read_image)
      return "Unsupported file type." unless media_type
      instance.send(:extract_via_claude, image_data, media_type)
    end

    # Skips Claude extraction — runs creation logic with pre-extracted data.
    # Used by ImportMultipleScreenshots after it merges items from several images.
    def self.call_with_extracted(extracted:, reference_number: nil, ordered_at: nil, notes: nil, created_by: nil)
      instance = new(file: nil, reference_number: reference_number,
                     ordered_at: ordered_at, notes: notes, created_by: created_by)
      instance.send(:process_extracted, extracted)
    end

    def initialize(file:, reference_number: nil, ordered_at: nil, notes: nil, created_by: nil)
      @file             = file
      @reference_number = reference_number.to_s.strip.presence
      @ordered_at       = ordered_at
      @notes            = notes
      @created_by       = created_by
      @supplier         = nil
    end

    def call
      image_data, media_type = read_image
      return Result.new(error: "Unsupported file type. Please upload a JPEG, PNG, WebP, or GIF image.") unless media_type

      extracted = extract_via_claude(image_data, media_type)
      return Result.new(error: extracted) if extracted.is_a?(String)

      # PDFs return a JSON array — one element per invoice.
      # Images return a single object. Normalise to array.
      invoices = extracted.is_a?(Array) ? extracted : [ extracted ]

      return process_extracted(invoices.first) if invoices.size == 1

      process_multiple_invoices(invoices)
    end

    private

    def process_extracted(extracted)
      @supplier      = extracted["supplier"].to_s.strip.downcase
      @supplier      = "ashley" if @supplier.blank?

      invoice_number = extracted["invoice_number"].to_s.strip.presence
      freight_cost   = extracted["freight_cost"].to_d
      discount       = extracted["discount"].to_d
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
      enrich_queue      = []

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

          description   = item["description"].to_s.strip
          category_name = item["category"].to_s.strip
          series        = item["series"].to_s.strip
          color         = item["color"].to_s.strip

          product    = Product.find_by(sku: sku)
          brand_name = supplier_category_name

          if product
            updates = {}
            # Name comes from the API enrichment, not the invoice text
            updates[:brand] = brand_name if product.brand != brand_name
            updates[:color] = color      if color.present? && product.color != color
            product.update!(updates) if updates.any?
            product.increment!(:stock_quantity, qty)
            updated_products << product unless updated_products.include?(product)
          else
            target_category_name = category_name.presence || supplier_category_name
            supplier_category    = Category.find_or_create_by!(name: target_category_name)

            product = Product.create!(
              sku:            sku,
              name:           sku,  # placeholder — API enrichment sets the real name
              brand:          brand_name,
              color:          color.presence,
              base_cost:      price,
              stock_quantity: qty,
              status:         :draft,
              category:       supplier_category
            )
            created_products << product
          end

          enrich_queue << { product: product, series: series, description: description }

          line_items << {
            product:          product,
            quantity_ordered: qty,
            unit_cost:        price,
            product_name:     product.name,
            product_sku:      product.sku
          }
        end

        raise "No valid line items found in the image." if line_items.empty?

        po = PurchaseOrder.create!(
          reference_number: ref,
          status:           :submitted,
          ordered_at:       @ordered_at,
          notes:            @notes,
          created_by:       @created_by,
          brand:            supplier_category_name,
          freight_cost:     freight_cost > 0 ? freight_cost : nil,
          discount:         discount > 0 ? discount : nil
        )

        line_items.each { |attrs| po.purchase_order_items.create!(attrs) }
      end

      # Enrich products after the transaction commits — HTTP calls must not run
      # inside a DB transaction (holds connection open, risks rollback on network error)
      enrich_queue.each { |args| enrich_product!(**args) }

      # Sync PO item product_name snapshots with the real names from the API.
      # Enrichment may have updated product.name; the snapshot captured before
      # enrichment could be the SKU placeholder or a stale invoice description.
      po.purchase_order_items.includes(:product).each do |item|
        real_name = item.product&.name
        item.update_columns(product_name: real_name) if real_name.present? && real_name != item.product_name
      end

      Result.new(
        purchase_order:   po,
        created_products: created_products,
        updated_products: updated_products,
        skipped_rows:     skipped_rows,
        supplier_name:    supplier_category_name
      )
    rescue ActiveRecord::RecordInvalid => e
      Result.new(error: e.message)
    rescue => e
      Result.new(error: e.message)
    end

    def supplier_category_name
      case @supplier
      when "generation_trade" then "Generation Trade"
      else "Ashley Furniture"
      end
    end

    def enrich_product!(product:, series:, description:)
      Rails.logger.info("[ImportScreenshot] enrich_product! sku=#{product.sku} supplier=#{@supplier}")
      case @supplier
      when "generation_trade"
        Products::FetchFromGenerationTrade.enrich!(product, series: series, description: description)
      else
        Products::FetchFromAshley.enrich!(product, series: series, description: description)
      end
    end

    def process_multiple_invoices(invoices)
      all_created  = []
      all_updated  = []
      all_skipped  = []
      all_pos      = []
      supplier_name = nil

      invoices.each do |invoice|
        result = process_extracted(invoice)

        # Accumulate even if one invoice errors — report it in skipped
        if result.success?
          all_pos     << result.purchase_order
          all_created.concat(result.created_products)
          all_updated.concat(result.updated_products)
          all_skipped.concat(result.skipped_rows)
          supplier_name ||= result.supplier_name
        else
          all_skipped << "Invoice #{invoice['invoice_number'].presence || '(unknown)'}: #{result.error}"
        end
      end

      return Result.new(error: all_skipped.join("; ")) if all_pos.empty?

      Result.new(
        purchase_order:   all_pos.first,
        purchase_orders:  all_pos,
        created_products: all_created.uniq,
        updated_products: all_updated.uniq,
        skipped_rows:     all_skipped,
        supplier_name:    supplier_name
      )
    end

    def read_image
      data       = @file.read
      raw_type   = @file.content_type.to_s.split(";").first.strip.downcase
      media_type = SUPPORTED_MEDIA_TYPES[raw_type]
      [Base64.strict_encode64(data), media_type]
    end

    def extraction_prompt(media_type = nil)
      media_type == "application/pdf" ? PDF_EXTRACTION_PROMPT : EXTRACTION_PROMPT
    end

    def extract_via_claude(image_data, media_type)
      api_key = ENV["ANTHROPIC_API_KEY"] || Rails.application.credentials.anthropic_api_key || "empty"
      return "Anthropic API key is not configured. Set ANTHROPIC_API_KEY in your environment." if api_key.blank?

      client = Anthropic::Client.new(api_key: api_key)

      # PDFs use "document" type; images use "image" type
      file_content = if media_type == "application/pdf"
        { type: "document", source: { type: "base64", media_type: "application/pdf", data: image_data } }
      else
        { type: "image",    source: { type: "base64", media_type: media_type, data: image_data } }
      end

      # PDFs may span many pages with many line items — raise max_tokens to
      # avoid JSON truncation. Model stays Haiku for cost efficiency.
      model      = "claude-haiku-4-5-20251001"
      max_tokens = media_type == "application/pdf" ? 8096 : 2048

      message = client.messages.create(
        model:      model,
        max_tokens: max_tokens,
        messages: [{
          role:    "user",
          content: [ file_content, { type: "text", text: extraction_prompt(media_type) } ]
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
