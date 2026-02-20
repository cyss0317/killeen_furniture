Rails.application.routes.draw do
  # === Public storefront ===
  root "pages#home"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions:      "users/sessions"
  }

  # Product catalog
  resources :categories, only: [:show], param: :slug
  resources :products,   only: [:index, :show], param: :slug

  # Shopping cart
  resource :cart, only: [:show] do
    post   :add_item
    patch  :update_item
    delete :remove_item
  end

  # Checkout flow
  resource :checkout, only: [:show, :create] do
    post :calculate_shipping, on: :collection
    get  :confirmation
  end

  # Stripe webhooks
  post "webhooks/stripe", to: "webhooks#stripe"

  # === Customer account area ===
  namespace :account do
    resource  :profile,   only: [:show, :edit, :update]
    resources :orders,    only: [:index, :show]
    resources :addresses, only: [:index, :new, :create, :edit, :update, :destroy]
  end

  # === Admin panel ===
  namespace :admin do
    root "dashboard#index", as: :dashboard

    resources :products do
      member do
        patch :update_stock
        patch :toggle_featured
        patch :publish
        patch :archive
      end
      resources :stock_adjustments, only: [:create]
    end

    resources :categories
    resources :delivery_zones
    resources :orders do
      member do
        patch :update_status
      end
    end

    resource :settings, only: [:show, :update]
  end
end
