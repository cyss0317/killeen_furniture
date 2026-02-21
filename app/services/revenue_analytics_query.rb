class RevenueAnalyticsQuery
  REVENUE_STATUSES = %i[paid scheduled_for_delivery out_for_delivery delivered].freeze

  Result = Struct.new(
    :current_sales, :current_cost, :current_profit, :current_margin, :current_count,
    :prev_sales, :prev_cost, :prev_profit, :prev_margin, :prev_count,
    :sales_change, :profit_change, :margin_change,
    :chart_labels, :chart_revenue, :chart_cost,
    keyword_init: true
  )

  def self.call(period:)
    new(period: period).call
  end

  def initialize(period:)
    @period = period.to_s.presence_in(%w[week month year]) || "month"
    @current_range, @previous_range = compute_ranges
  end

  def call
    current = aggregate(@current_range)
    prev    = aggregate(@previous_range)
    chart   = build_chart_data(@current_range)

    Result.new(
      current_sales:  current[:sales],
      current_cost:   current[:cost],
      current_profit: current[:profit],
      current_margin: current[:margin],
      current_count:  current[:count],
      prev_sales:     prev[:sales],
      prev_cost:      prev[:cost],
      prev_profit:    prev[:profit],
      prev_margin:    prev[:margin],
      prev_count:     prev[:count],
      sales_change:   pct_change(prev[:sales], current[:sales]),
      profit_change:  pct_change(prev[:profit], current[:profit]),
      margin_change:  (current[:margin] - prev[:margin]).round(1),
      chart_labels:   chart[:labels],
      chart_revenue:  chart[:revenue],
      chart_cost:     chart[:cost]
    )
  end

  private

  def compute_ranges
    now = Time.current
    case @period
    when "week"
      current  = now.beginning_of_week..now.end_of_week
      previous = (now - 1.week).beginning_of_week..(now - 1.week).end_of_week
    when "year"
      current  = now.beginning_of_year..now.end_of_year
      previous = (now - 1.year).beginning_of_year..(now - 1.year).end_of_year
    else
      current  = now.beginning_of_month..now.end_of_month
      previous = (now - 1.month).beginning_of_month..(now - 1.month).end_of_month
    end
    [current, previous]
  end

  def aggregate(range)
    orders = base_scope.where(created_at: range)
    sales  = orders.sum(:grand_total).to_f
    cost   = OrderItem.joins(:order)
                      .merge(orders)
                      .where.not(unit_cost: nil)
                      .sum("order_items.unit_cost * order_items.quantity").to_f
    profit = sales - cost
    margin = sales > 0 ? (profit / sales * 100).round(1) : 0.0
    { sales: sales, cost: cost, profit: profit, margin: margin, count: orders.count }
  end

  def build_chart_data(range)
    trunc  = @period == "year" ? "month" : "day"
    orders = base_scope.where(created_at: range)

    revenue_rows = orders
      .group("date_trunc('#{trunc}', created_at)")
      .order("1")
      .sum(:grand_total)

    cost_rows = OrderItem.joins(:order)
      .merge(base_scope.where(created_at: range))
      .where.not(unit_cost: nil)
      .group("date_trunc('#{trunc}', orders.created_at)")
      .order("1")
      .sum("order_items.unit_cost * order_items.quantity")

    all_keys = (revenue_rows.keys | cost_rows.keys).compact.sort
    fmt      = @period == "year" ? "%b %Y" : "%b %-d"

    {
      labels:  all_keys.map { |k| k.to_date.strftime(fmt) },
      revenue: all_keys.map { |k| revenue_rows[k].to_f.round(2) },
      cost:    all_keys.map { |k| cost_rows[k].to_f.round(2) }
    }
  end

  def pct_change(old_val, new_val)
    return nil if old_val.nil? || old_val.zero?
    ((new_val - old_val) / old_val * 100).round(1)
  end

  def base_scope
    Order.where(status: REVENUE_STATUSES)
  end
end
