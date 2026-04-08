module SuperAdmin
  class AshleySyncsController < BaseController
    def new
      @results = []
    end

    def create
      raw = params[:sku].to_s
      skus = raw.split(/[\n,]+/).map(&:strip).reject(&:blank?).uniq

      if skus.empty?
        flash.now[:alert] = "Please enter at least one SKU."
        @results = []
        render :new, status: :unprocessable_entity
        return
      end

      @results = skus.map do |sku|
        begin
          product = Ashley::ProductSyncService.new(sku).call
          { sku: sku, product: product, error: nil }
        rescue Ashley::Client::RecordNotFoundError
          { sku: sku, product: nil, error: "Not found on Ashley API" }
        rescue => e
          { sku: sku, product: nil, error: e.message }
        end
      end

      succeeded = @results.count { |r| r[:error].nil? }
      failed    = @results.count { |r| r[:error].present? }

      if failed.zero?
        flash.now[:notice] = "#{succeeded} #{succeeded == 1 ? 'product' : 'products'} synced successfully."
      elsif succeeded.zero?
        flash.now[:alert] = "All #{failed} SKUs failed to sync."
      else
        flash.now[:notice] = "#{succeeded} synced, #{failed} failed."
      end

      render :new
    end
  end
end
