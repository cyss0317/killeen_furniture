module Admin
  class DeliveryZonesController < BaseController
    before_action :set_zone, only: [:show, :edit, :update, :destroy]

    def index
      @zones = DeliveryZone.order(:name)
    end

    def new
      @zone = DeliveryZone.new
    end

    def create
      @zone = DeliveryZone.new(zone_params)
      if @zone.save
        redirect_to admin_delivery_zones_path, notice: "Delivery zone created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @zone.update(zone_params)
        redirect_to admin_delivery_zones_path, notice: "Delivery zone updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @zone.destroy
      redirect_to admin_delivery_zones_path, notice: "Delivery zone deleted."
    end

    private

    def set_zone
      @zone = DeliveryZone.find(params[:id])
    end

    def zone_params
      p = params.require(:delivery_zone).permit(
        :name, :base_rate, :per_item_fee, :large_item_surcharge, :active, :zip_codes_text
      )
      # Convert zip_codes_text to zip_codes array via the virtual attribute
      p
    end
  end
end
