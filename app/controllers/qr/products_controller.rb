module Qr
  class ProductsController < ApplicationController
    def show
      @product = Product.find_by!(qr_token: params[:token])

      if current_user&.admin_or_above?
        render :show_admin
      else
        render :restricted
      end
    rescue ActiveRecord::RecordNotFound
      render :not_found, status: :not_found
    end
  end
end
