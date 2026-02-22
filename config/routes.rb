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
  get "/brands/:name", to: "brands#show", as: :brand

  # Shopping cart
  resource :cart, only: [:show] do
    post   :add_item
    patch  :update_item
    delete :remove_item
  end

  # Checkout flow
  resource :checkout, only: [:show, :create] do
    post :calculate_shipping, on: :collection
    post :external_payment,   on: :collection
    get  :confirmation
  end

  # Stripe webhooks
  post "webhooks/stripe", to: "webhooks#stripe"

  # QR code product scans (public, but access-controlled in controller)
  get "qr/products/:token", to: "qr/products#show", as: :qr_product

  # === Customer account area ===
  namespace :account do
    resource  :profile,   only: [:show, :edit, :update]
    resources :orders,    only: [:index, :show]
    resources :addresses, only: [:index, :new, :create, :edit, :update, :destroy]
  end

  # === Delivery portal (admin + delivery admins) ===
  namespace :delivery do
    root "orders#index"
    resources :orders, only: [:index, :show] do
      member do
        patch :mark_delivered
        patch :update_status
      end
    end
  end

  # === Admin panel ===
  namespace :admin do
    root "dashboard#index", as: :dashboard

    get "analytics", to: "analytics#index", as: :analytics

    resources :products do
      member do
        patch :update_stock
        patch :toggle_featured
        patch :publish
        patch :archive
      end
      collection do
        post :import_screenshot
      end
      resources :stock_adjustments, only: [:create]
    end

    resources :categories
    resources :delivery_zones
    resources :orders do
      member do
        patch :update_status
        patch :assign_delivery
      end
      collection do
        post :calculate_shipping
      end
    end

    resource  :settings,     only: [:show, :update]
    resources :employee_pay, only: [:index, :create, :destroy]

    resources :purchase_orders, only: [:index, :show, :new, :create] do
      member { patch :receive }
      collection do
        get  :import_csv
        post :import_csv
        get  :import_screenshot
        post :import_screenshot
      end
    end
  end
end
