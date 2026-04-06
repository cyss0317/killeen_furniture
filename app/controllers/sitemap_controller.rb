class SitemapController < ApplicationController
  def index
    @products   = Product.published.select(:slug, :updated_at).order(updated_at: :desc)
    @categories = Category.select(:slug, :updated_at).order(updated_at: :desc)

    respond_to do |format|
      format.xml { render layout: false }
    end
  end
end
