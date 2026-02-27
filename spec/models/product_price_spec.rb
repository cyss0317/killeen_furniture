require "rails_helper"

RSpec.describe Product, type: :model do
  describe "#update_selling_price" do
    let(:category) { Category.create!(name: "Test Cat") }
    let(:product) do
      Product.create!(
        name: "Test Product",
        sku: "TEST-SKU",
        base_cost: 100.0,
        markup_percentage: 20.0,
        category: category,
        status: :published
      )
    end

    it "updates the selling price and projects the new markup percentage" do
      # Initial state: base_cost 100, markup 20% -> selling_price should be 120
      expect(product.selling_price.to_f).to eq(120.0)

      # Update price to 150
      product.update_selling_price(150.0)

      product.reload
      expect(product.selling_price.to_f).to eq(150.0)
      # Markup should be ((150/100) - 1) * 100 = 50%
      expect(product.markup_percentage.to_f).to eq(50.0)
    end

    it "rounds the markup to 2 decimal places" do
      # base_cost 100, price 133.33 -> markup 33.33%
      product.update_selling_price(133.33)
      product.reload
      expect(product.markup_percentage.to_f).to eq(33.33)
    end

    it "returns false for invalid prices" do
      expect(product.update_selling_price(0)).to be false
      expect(product.update_selling_price(-10)).to be false
    end
  end
end
