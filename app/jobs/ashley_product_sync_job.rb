class AshleyProductSyncJob < ApplicationJob
  queue_as :default

  def perform(sku)
    Ashley::ProductSyncService.new(sku).call
  rescue StandardError => e
    Rails.logger.error("[AshleyProductSyncJob] Failed to sync SKU #{sku}: #{e.message}")
    # Could re-raise to trigger job retries or keep caught to fail silently
    raise e
  end
end
