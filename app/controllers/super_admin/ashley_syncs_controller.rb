module SuperAdmin
  class AshleySyncsController < BaseController
    def new
      @product = nil
    end

    def create
      sku = params[:sku]

      if sku.blank?
        flash.now[:alert] = "SKU cannot be blank."
        render :new, status: :unprocessable_entity
        return
      end

      begin
        @product = Ashley::ProductSyncService.new(sku).call
        flash.now[:notice] = "Successfully synced details for SKU: #{sku}"
      rescue Ashley::Client::RecordNotFoundError => e
        flash.now[:alert] = "Product not found on Ashley API for SKU: #{sku}"
      rescue => e
        flash.now[:alert] = "Failed to sync SKU #{sku}: #{e.message}"
      end

      render :new, status: flash.now[:alert] ? :unprocessable_entity : :ok
    end
  end
end
