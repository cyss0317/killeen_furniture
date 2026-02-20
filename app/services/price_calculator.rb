class PriceCalculator
  def self.call(base_cost:, markup_percentage: nil)
    markup = markup_percentage.presence || GlobalSetting.global_markup
    markup = markup.to_f
    ((base_cost.to_f) * (1 + markup / 100.0)).round(2)
  end
end
