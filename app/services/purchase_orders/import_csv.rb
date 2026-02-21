module PurchaseOrders
  class ImportCsv
    Result = Struct.new(:purchase_order, :created_products, :updated_products, :skipped_rows, :error, keyword_init: true) do
      def success? = error.nil?
    end

    def self.call(...) = new(...).call

    def initialize(file:, reference_number:, ordered_at: nil, notes: nil, created_by: nil)
      @file             = file
      @reference_number = reference_number
      @ordered_at       = ordered_at
      @notes            = notes
      @created_by       = created_by
    end

    def call
      rows = parse_file
      return Result.new(error: "Could not parse the file. Make sure it is the tab-separated export from Ashley Furniture.") if rows.nil?
      return Result.new(error: "File is empty or contains no data rows.") if rows.empty?

      created_products = []
      updated_products = []
      skipped_rows     = []
      po               = nil
      ashley_category  = nil

      ActiveRecord::Base.transaction do
        line_items = []

        rows.each_with_index do |row, i|
          line_num = i + 2  # +1 for header row, +1 for 1-based display

          sku   = row["Item Code"].to_s.strip.upcase
          qty   = row["Qty"].to_i
          price = row["Price"].to_d

          if sku.blank?
            skipped_rows << "Row #{line_num}: missing Item Code"
            next
          end

          if qty <= 0 || price <= 0
            skipped_rows << "Row #{line_num} (#{sku}): skipped — qty=#{qty}, price=#{price}"
            next
          end

          description = row["Description"].to_s.strip
          series      = row["Series"].to_s.strip
          color       = row["Color"].to_s.strip

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
            ashley_category ||= Category.find_or_create_by!(name: "Ashley Furniture")

            product = Product.create!(
              sku:            sku,
              name:           description.presence || sku,
              brand:          series.presence,
              color:          color.presence,
              base_cost:      price,
              stock_quantity: qty,
              status:         :draft,
              category:       ashley_category
            )
            created_products << product
          end

          line_items << {
            product:          product,
            quantity_ordered: qty,
            unit_cost:        price,
            product_name:     product.name,
            product_sku:      product.sku
          }
        end

        raise "No valid line items found in the file." if line_items.empty?

        po = PurchaseOrder.create!(
          reference_number: @reference_number,
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

    def parse_file
      content = @file.read
      content = content.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace)

      # Ashley exports are tab-separated; fall back to comma if no tabs detected
      sep = content.lines.first.to_s.include?("\t") ? "\t" : ","

      CSV.parse(content, headers: true, col_sep: sep, skip_blanks: true).map(&:to_h)
    rescue
      nil
    end
  end
end
