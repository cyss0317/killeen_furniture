module Admin
  class LayawayPaymentsController < BaseController
    before_action :set_order

    def create
      @payment = @order.layaway_payments.build(layaway_payment_params)
      @payment.collected_by = current_user

      if @payment.save
        redirect_to admin_order_path(@order),
                    notice: "Payment of #{helpers.number_to_currency(@payment.amount)} recorded."
      else
        redirect_to admin_order_path(@order),
                    alert: @payment.errors.full_messages.join(", ")
      end
    end

    def destroy
      payment = @order.layaway_payments.find(params[:id])
      payment.destroy!
      redirect_to admin_order_path(@order), notice: "Payment removed."
    end

    private

    def set_order
      @order = Order.find(params[:order_id])
    end

    def layaway_payment_params
      params.require(:layaway_payment).permit(:amount, :note, :paid_at)
    end
  end
end
