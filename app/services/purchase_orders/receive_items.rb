module PurchaseOrders
  class ReceiveItems
    Result = Struct.new(:purchase_order, :error, keyword_init: true) do
      def success? = error.nil?
    end

    def self.call(...) = new(...).call

    # receive_params: { item_id => { qty_to_receive: N, unit_cost: X } }
    def initialize(purchase_order:, receive_params:)
      @purchase_order = purchase_order
      @receive_params = receive_params
    end

    def call
      ActiveRecord::Base.transaction do
        @receive_params.each do |item_id, attrs|
          qty           = attrs[:qty_to_receive].to_i
          selling_price = attrs[:selling_price].to_d
          next if qty <= 0

          item = @purchase_order.purchase_order_items.find(item_id)
          cost = item.unit_cost # Use the PO's fixed unit cost

          item.update!(
            quantity_received: item.quantity_received + qty
          )

          # Update stock quantity and sync base_cost from PO unit_cost
          # Then update selling price (which also updates markup_percentage)
          product = item.product
          product.update!(
            base_cost:      cost,
            stock_quantity: product.stock_quantity + qty
          )
          product.update_selling_price(selling_price) if selling_price > 0
        end

        @purchase_order.reload
        new_status = @purchase_order.fully_received? ? :received : :partially_received
        @purchase_order.update!(status: new_status)
      end

      Result.new(purchase_order: @purchase_order)
    rescue => e
      Result.new(error: e.message)
    end
  end
end
