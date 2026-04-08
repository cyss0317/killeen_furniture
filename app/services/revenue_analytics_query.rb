class RevenueAnalyticsQuery
  REVENUE_STATUSES = %i[paid scheduled_for_delivery out_for_delivery delivered].freeze

  Result = Struct.new(
    :current_sales, :current_cost, :current_profit, :current_margin, :current_count,
    :current_tax,
    :prev_sales, :prev_cost, :prev_profit, :prev_margin, :prev_count,
    :prev_tax,
    :sales_change, :profit_change, :margin_change,
    :chart_labels, :chart_revenue, :chart_cost,
    :current_labor_cost, :prev_labor_cost, :current_net_profit, :prev_net_profit,
    keyword_init: true
  )

  def self.call(period: nil, offset: 0, start_date: nil, end_date: nil)
    new(period: period, offset: offset, start_date: start_date, end_date: end_date).call
  end

  def initialize(period: nil, offset: 0, start_date: nil, end_date: nil)
    @period     = period.to_s.presence_in(%w[week month year custom]) || "month"
    @offset     = offset.to_i
    
    if start_date.present? && end_date.present?
      @period = "custom"
      @start_date = Date.parse(start_date.to_s) rescue nil
      @end_date   = Date.parse(end_date.to_s) rescue nil
    end
    
    @current_range, @previous_range = compute_ranges
  end

  def call
    current = aggregate(@current_range)
    prev    = aggregate(@previous_range)
    chart   = build_chart_data(@current_range)

    current_labor = labor_cost(@current_range)
    prev_labor    = labor_cost(@previous_range)

    Result.new(
      current_sales:      current[:sales],
      current_cost:       current[:cost],
      current_profit:     current[:profit],
      current_margin:     current[:margin],
      current_count:      current[:count],
      current_tax:        current[:tax],
      prev_sales:         prev[:sales],
      prev_cost:          prev[:cost],
      prev_profit:        prev[:profit],
      prev_margin:        prev[:margin],
      prev_count:         prev[:count],
      prev_tax:           prev[:tax],
      sales_change:       pct_change(prev[:sales], current[:sales]),
      profit_change:      pct_change(prev[:profit], current[:profit]),
      margin_change:      (current[:margin] - prev[:margin]).round(1),
      chart_labels:       chart[:labels],
      chart_revenue:      chart[:revenue],
      chart_cost:         chart[:cost],
      current_labor_cost: current_labor,
      prev_labor_cost:    prev_labor,
      current_net_profit: current[:profit] - current_labor,
      prev_net_profit:    prev[:profit] - prev_labor
    )
  end

  private

  def compute_ranges
    now = Time.current
    case @period
    when "custom"
      if @start_date && @end_date
        current  = @start_date.beginning_of_day..@end_date.end_of_day
        duration = (@end_date - @start_date).to_i + 1
        previous = (@start_date - duration.days).beginning_of_day..(@end_date - duration.days).end_of_day
      else
        anchor   = now + @offset.months
        current  = anchor.beginning_of_month..anchor.end_of_month
        previous = (anchor - 1.month).beginning_of_month..(anchor - 1.month).end_of_month
      end
    when "week"
      anchor   = now + @offset.weeks
      current  = anchor.beginning_of_week..anchor.end_of_week
      previous = (anchor - 1.week).beginning_of_week..(anchor - 1.week).end_of_week
    when "year"
      anchor   = now + @offset.years
      current  = anchor.beginning_of_year..anchor.end_of_year
      previous = (anchor - 1.year).beginning_of_year..(anchor - 1.year).end_of_year
    else
      anchor   = now + @offset.months
      current  = anchor.beginning_of_month..anchor.end_of_month
      previous = (anchor - 1.month).beginning_of_month..(anchor - 1.month).end_of_month
    end
    [current, previous]
  end

  def aggregate(range)
    orders = base_scope.where(created_at: range)
    sales  = orders.sum(:grand_total).to_f
    tax    = orders.sum(:tax_amount).to_f
    cost   = OrderItem.joins(:order)
                      .merge(orders)
                      .where.not(unit_cost: nil)
                      .sum("order_items.unit_cost * order_items.quantity").to_f
    profit = sales - cost
    margin = sales > 0 ? (profit / sales * 100).round(1) : 0.0
    { sales: sales, cost: cost, profit: profit, margin: margin, count: orders.count, tax: tax }
  end

  def labor_cost(range)
    date_range = range.first.to_date..range.last.to_date
    EmployeePayEntry.where(paid_on: date_range).sum(:amount).to_f
  end

  def build_chart_data(_range)
    case @period
    when "year"   then build_yearly_chart
    when "week"   then build_weekly_chart
    when "custom" then build_custom_chart
    else               build_monthly_chart
    end
  end

  # Last 5 years (including the offset year)
  def build_yearly_chart
    anchor       = Time.current + @offset.years
    current_year = anchor.year
    years        = ((current_year - 4)..current_year).to_a
    chart_start  = Time.zone.local(years.first).beginning_of_year
    chart_end    = Time.zone.local(years.last).end_of_year

    rev_map  = revenue_by_extract("year", chart_start..chart_end)
    cost_map = cost_by_extract("year", chart_start..chart_end)

    {
      labels:  years.map(&:to_s),
      revenue: years.map { |y| rev_map[y].to_f.round(2) },
      cost:    years.map { |y| cost_map[y].to_f.round(2) }
    }
  end

  # All 12 months of the selected year
  def build_monthly_chart
    anchor      = Time.current + @offset.months
    year        = anchor.year
    year_start  = anchor.beginning_of_year
    year_end    = anchor.end_of_year

    rev_map  = revenue_by_extract("month", year_start..year_end)
    cost_map = cost_by_extract("month", year_start..year_end)

    {
      labels:  Date::ABBR_MONTHNAMES[1..],
      revenue: (1..12).map { |m| rev_map[m].to_f.round(2) },
      cost:    (1..12).map { |m| cost_map[m].to_f.round(2) }
    }
  end

  # All weeks (Mon–Sun) that overlap with the selected month
  def build_weekly_chart
    anchor      = Time.current + @offset.weeks
    month_start = anchor.beginning_of_month
    month_end   = anchor.end_of_month

    weeks = []
    w = month_start.to_date.beginning_of_week(:monday)
    while w <= month_end.to_date
      weeks << w
      w += 1.week
    end

    orders = base_scope.where(created_at: month_start..month_end)
    rev_raw = orders.group("date_trunc('week', created_at)").sum(:grand_total)
                    .transform_keys { |k| k.to_date }
    cost_raw = OrderItem.joins(:order)
                        .merge(base_scope.where(created_at: month_start..month_end))
                        .where.not(unit_cost: nil)
                        .group("date_trunc('week', orders.created_at)")
                        .sum("order_items.unit_cost * order_items.quantity")
                        .transform_keys { |k| k.to_date }

    {
      labels:  weeks.map { |w| "#{w.strftime('%b %-d')}–#{[w + 6.days, month_end.to_date].min.strftime('%-d')}" },
      revenue: weeks.map { |w| rev_raw[w].to_f.round(2) },
      cost:    weeks.map { |w| cost_raw[w].to_f.round(2) }
    }
  end

  # Custom date range — daily or monthly depending on span
  def build_custom_chart
    return { labels: [], revenue: [], cost: [] } unless @start_date && @end_date

    range    = @start_date.beginning_of_day..@end_date.end_of_day
    duration = (@end_date - @start_date).to_i
    trunc    = duration > 90 ? "month" : "day"
    fmt      = trunc == "month" ? "%b %Y" : "%b %-d"

    orders = base_scope.where(created_at: range)
    rev_rows  = orders.group("date_trunc('#{trunc}', created_at)").order("1").sum(:grand_total)
    cost_rows = OrderItem.joins(:order)
                         .merge(base_scope.where(created_at: range))
                         .where.not(unit_cost: nil)
                         .group("date_trunc('#{trunc}', orders.created_at)").order("1")
                         .sum("order_items.unit_cost * order_items.quantity")

    all_keys = (rev_rows.keys | cost_rows.keys).compact.sort
    {
      labels:  all_keys.map { |k| k.to_date.strftime(fmt) },
      revenue: all_keys.map { |k| rev_rows[k].to_f.round(2) },
      cost:    all_keys.map { |k| cost_rows[k].to_f.round(2) }
    }
  end

  def revenue_by_extract(part, range)
    base_scope.where(created_at: range)
              .group("EXTRACT(#{part} FROM created_at)")
              .sum(:grand_total)
              .transform_keys(&:to_i)
  end

  def cost_by_extract(part, range)
    OrderItem.joins(:order)
             .merge(base_scope.where(created_at: range))
             .where.not(unit_cost: nil)
             .group("EXTRACT(#{part} FROM orders.created_at)")
             .sum("order_items.unit_cost * order_items.quantity")
             .transform_keys(&:to_i)
  end

  def pct_change(old_val, new_val)
    return nil if old_val.nil? || old_val.zero?
    ((new_val - old_val) / old_val * 100).round(1)
  end

  def base_scope
    Order.where(status: REVENUE_STATUSES)
  end
end
