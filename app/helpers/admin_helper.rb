module AdminHelper
  def admin_nav_link_class(section)
    base = "flex items-center px-6 py-3 text-sm font-medium transition-colors"
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
