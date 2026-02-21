module AdminHelper
  # Generates a sortable column header link with ASC/DESC indicators.
  # Preserves existing query params (q, status, etc.) while toggling sort.
  def sort_link(label, column, current_sort: nil, current_direction: nil, **url_opts)
    col = column.to_s
    if current_sort == col
      next_direction = current_direction == "asc" ? "desc" : "asc"
      indicator = current_direction == "asc" ? " ↑" : " ↓"
    else
      next_direction = "asc"
      indicator = ""
    end

    new_params = request.query_parameters.merge(
      sort: col,
      direction: next_direction
    ).merge(url_opts)

    link_to(
      safe_join([label, content_tag(:span, indicator, class: "text-amber-600 font-bold")]),
      url_for(new_params),
      class: "inline-flex items-center gap-0.5 hover:text-gray-900 transition-colors #{current_sort == col ? 'text-gray-900' : 'text-gray-500'}"
    )
  end

  def admin_nav_link_class(section)
    base     = "flex items-center px-4 md:px-6 py-3 text-sm font-medium transition-colors whitespace-nowrap flex-shrink-0"
    active   = "#{base} bg-gray-800 text-white"
    inactive = "#{base} text-gray-300 hover:bg-gray-700 hover:text-white"

    controller_path.start_with?("admin/#{section}") ? active : inactive
  end

  def status_badge_class(status)
    {
      "pending"                => "bg-yellow-100 text-yellow-800",
      "paid"                   => "bg-green-100 text-green-800",
      "scheduled_for_delivery" => "bg-blue-100 text-blue-800",
      "out_for_delivery"       => "bg-indigo-100 text-indigo-800",
      "delivered"              => "bg-gray-100 text-gray-700",
      "canceled"               => "bg-red-100 text-red-800",
      "refunded"               => "bg-orange-100 text-orange-800"
    }.fetch(status.to_s, "bg-gray-100 text-gray-700")
  end
end
