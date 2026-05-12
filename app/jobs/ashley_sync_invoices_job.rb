class AshleySyncInvoicesJob < ApplicationJob
  queue_as :default

  def perform(created_by_id: nil)
    created_by = User.find_by(id: created_by_id)
    result = Ashley::InvoiceSyncer.call(created_by: created_by)

    Rails.logger.info(
      "[AshleySyncInvoicesJob] Done — " \
      "created=#{result.created.size} skipped=#{result.skipped.size} errors=#{result.errors.size}"
    )
  end
end
