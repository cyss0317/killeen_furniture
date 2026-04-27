module Admin
  class CustomersController < BaseController
    SORTABLE_COLUMNS = %w[first_name email orders_count total_spent created_at].freeze

    before_action :set_customer, only: [ :edit, :update, :destroy ]

    def index
      scope = User.customer
                  .left_joins(:orders)
                  .where("orders.id IS NULL OR orders.status IN (?)",
                         Order.statuses.values_at("paid", "scheduled_for_delivery", "out_for_delivery", "delivered"))
                  .select(
                    "users.*",
                    "COUNT(DISTINCT orders.id) AS orders_count",
                    "COALESCE(SUM(orders.grand_total), 0) AS total_spent"
                  )
                  .group("users.id")

      case params[:confirmed]
      when "confirmed"   then scope = scope.where.not(confirmed_at: nil)
      when "unconfirmed" then scope = scope.where(confirmed_at: nil)
      end

      if params[:q].present?
        q = "%#{params[:q].strip}%"
        scope = scope.where(
          "(users.first_name || ' ' || users.last_name) ILIKE :q OR " \
          "users.email ILIKE :q OR " \
          "users.phone ILIKE :q",
          q: q
        )
      end

      @sort      = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "created_at"
      @direction = params[:direction] == "asc" ? "asc" : "desc"

      order_clause = case @sort
                     when "orders_count" then "orders_count #{@direction}"
                     when "total_spent"  then "total_spent #{@direction}"
                     else                     "users.#{@sort} #{@direction}"
                     end
      scope = scope.reorder(Arel.sql(order_clause))

      @pagy, @customers = pagy(:offset, scope, limit: 25)
      @stale_unconfirmed_count = User.customer.where(confirmed_at: nil).where("created_at < ?", 1.week.ago).count
    end

    def purge_unconfirmed
      count = User.customer.where(confirmed_at: nil).where("created_at < ?", 1.week.ago).delete_all
      redirect_to admin_customers_path, notice: "#{count} unconfirmed #{"account".pluralize(count)} deleted."
    end

    def edit
    end

    def update
      if @customer.update(customer_params)
        redirect_to admin_customers_path, notice: "Customer updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @customer.destroy
      redirect_to admin_customers_path, notice: "Customer deleted."
    end

    private

    def set_customer
      @customer = User.customer.find(params[:id])
    end

    def customer_params
      params.require(:user).permit(:first_name, :last_name, :email, :phone)
    end
  end
end
