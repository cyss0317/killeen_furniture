module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: [:edit, :update, :destroy]

    def index
      @root_categories = Category.root_categories.includes(:products, subcategories: [ :products ])
    end

    def new
      @category  = Category.new(parent_id: params[:parent_id])
      @parents   = Category.root_categories
    end

    def create
      @category = Category.new(category_params)
      if @category.save
        redirect_to admin_categories_path, notice: "Category created."
      else
        @parents = Category.root_categories
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @parents = Category.root_categories.where.not(id: @category.id)
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "Category updated."
      else
        @parents = Category.root_categories.where.not(id: @category.id)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @category.products.any?
        redirect_to admin_categories_path, alert: "Cannot delete category with products. Archive products first."
      else
        @category.destroy
        redirect_to admin_categories_path, notice: "Category deleted."
      end
    end

    private

    def set_category
      @category = Category.friendly.find(params[:id])
    rescue ActiveRecord::RecordNotFound, FriendlyId::SlugNotFoundException
      redirect_to admin_categories_path, alert: "Category not found."
    end

    def category_params
      params.require(:category).permit(:name, :parent_id, :position)
    end
  end
end
