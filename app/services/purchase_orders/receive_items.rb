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
          qty  = attrs[:qty_to_receive].to_i
          cost = attrs[:unit_cost].to_d
          next if qty <= 0

          item = @purchase_order.purchase_order_items.find(item_id)

          item.update!(
            quantity_received: item.quantity_received + qty,
            unit_cost:         cost
          )

          # Sync base_cost → before_save :calculate_selling_price recalculates selling_price
          item.product.update!(
            base_cost:      cost,
            stock_quantity: item.product.stock_quantity + qty
          )
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
