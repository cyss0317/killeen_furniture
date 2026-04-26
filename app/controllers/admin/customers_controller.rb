module Admin
  class CustomersController < BaseController
    SORTABLE_COLUMNS = %w[first_name email orders_count total_spent created_at].freeze

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
                     else "users.#{@sort} #{@direction}"
                     end
      scope = scope.reorder(Arel.sql(order_clause))

      @pagy, @customers = pagy(:offset, scope, limit: 25)
    end
  end
end
