class AshleyEnrichProductJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    product = Product.find_by(id: product_id)
    return unless product

    Products::FetchFromAshley.enrich!(product)
  end
end
