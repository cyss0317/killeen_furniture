module Admin
  class StockAdjustmentsController < BaseController
    def create
      @product = Product.friendly.find(params[:product_id])
      adjustment = @product.stock_adjustments.build(
        quantity_change: params[:stock_adjustment][:quantity_change].to_i,
        reason:          params[:stock_adjustment][:reason],
        admin_user:      current_user
      )

      if adjustment.save
        redirect_to admin_product_path(@product), notice: "Stock adjusted by #{adjustment.quantity_change}."
      else
        redirect_to admin_product_path(@product), alert: adjustment.errors.full_messages.to_sentence
      end
    end
  end
end
