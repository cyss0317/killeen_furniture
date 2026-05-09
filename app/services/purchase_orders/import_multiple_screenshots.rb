module PurchaseOrders
  # Processes multiple screenshots of the same order (e.g. multi-page invoices).
  # Extracts items from each image via Claude, merges them (combining quantities
  # for duplicate SKUs), then creates a single PurchaseOrder.
  class ImportMultipleScreenshots
    Result = Struct.new(:purchase_order, :created_products, :updated_products,
                        :skipped_rows, :supplier_name, :processed_files, :error,
                        keyword_init: true) do
      def success? = error.nil?
    end

    def self.call(...) = new(...).call

    def initialize(files:, reference_number: nil, ordered_at: nil, notes: nil, created_by: nil)
      @files            = Array(files).compact
      @reference_number = reference_number.to_s.strip.presence
      @ordered_at       = ordered_at
      @notes            = notes
      @created_by       = created_by
    end

    def call
      return Result.new(error: "Please upload at least one screenshot.") if @files.empty?

      # ── Step 1: extract items from every screenshot ──────────────────────
      all_items      = []
      invoice_number = nil
      supplier       = nil
      errors         = []
      processed      = 0

      @files.each_with_index do |file, idx|
        extracted = ImportScreenshot.extract(file)

        if extracted.is_a?(String)
          errors << "Image #{idx + 1}: #{extracted}"
          next
        end

        processed += 1
        supplier       ||= extracted["supplier"].to_s.strip.downcase.presence || "ashley"
        invoice_number ||= extracted["invoice_number"].to_s.strip.presence

        Array(extracted["items"]).each { |item| all_items << item }
      end

      if processed.zero?
        return Result.new(error: errors.first || "No screenshots could be processed.")
      end

      # ── Step 2: merge duplicate SKUs (sum quantities, keep first price) ──
      merged = all_items.each_with_object({}) do |item, acc|
        sku = item["item_code"].to_s.strip.upcase
        next if sku.blank?

        if acc[sku]
          acc[sku]["qty"] = acc[sku]["qty"].to_i + item["qty"].to_i
        else
          acc[sku] = item.dup
        end
      end

      merged_items = merged.values

      # ── Step 3: delegate to the single-screenshot service with merged data ──
      # Re-use ImportScreenshot but inject already-extracted data instead of
      # re-running Claude, by passing the first valid file and overriding the
      # reference number + pre-merged items.
      ref = @reference_number || invoice_number
      return Result.new(error: "Could not determine invoice number. Please enter it manually.") if ref.blank?
      return Result.new(error: "No valid line items found across the uploaded screenshots.") if merged_items.empty?

      # Build a synthetic extracted hash and feed it into ImportScreenshot's
      # creation logic by calling call_with_extracted:
      result = ImportScreenshot.call_with_extracted(
        extracted:        { "supplier" => supplier, "invoice_number" => ref, "items" => merged_items },
        reference_number: @reference_number,
        ordered_at:       @ordered_at,
        notes:            @notes,
        created_by:       @created_by
      )

      Result.new(
        purchase_order:   result.purchase_order,
        created_products: result.created_products,
        updated_products: result.updated_products,
        skipped_rows:     result.skipped_rows + errors,
        supplier_name:    result.supplier_name,
        processed_files:  processed,
        error:            result.error
      )
    end
  end
end
