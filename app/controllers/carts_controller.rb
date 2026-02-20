class CartsController < ApplicationController
  def show
    @cart_items = current_cart.cart_items.includes(:product)
  end

  def add_item
    product = Product.published.find(params[:product_id])
    quantity = params.fetch(:quantity, 1).to_i
    quantity = [quantity, 1].max

    item = current_cart.cart_items.find_or_initialize_by(product: product)
    new_qty = item.new_record? ? quantity : item.quantity + quantity
    new_qty = [new_qty, product.stock_quantity].min
    item.quantity = new_qty

    if item.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("cart-count", current_cart.reload.total_items.to_s),
            turbo_stream.update("flash-messages",
              partial: "shared/flash_messages",
              locals:  { notice: "#{product.name} added to cart." })
          ]
        end
        format.html { redirect_to product_path(product), notice: "#{product.name} added to cart." }
      end
    else
      message = item.errors.full_messages.to_sentence
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("flash-messages",
            partial: "shared/flash_messages",
            locals:  { alert: message })
        end
        format.html { redirect_to product_path(product), alert: message }
      end
    end
  end

  def update_item
    item = current_cart.cart_items.find(params[:id])

    if item.update(quantity: params[:quantity].to_i)
      redirect_to cart_path
    else
      redirect_to cart_path, alert: item.errors.full_messages.to_sentence
    end
  end

  def remove_item
    current_cart.cart_items.find(params[:id]).destroy
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("cart-item-#{params[:id]}"),
          turbo_stream.update("cart-count", current_cart.reload.total_items.to_s),
          turbo_stream.update("cart-subtotal", helpers.number_to_currency(current_cart.subtotal))
        ]
      end
      format.html { redirect_to cart_path, notice: "Item removed from cart." }
    end
  end
end
