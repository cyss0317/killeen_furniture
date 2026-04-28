Rails.application.routes.draw do
  # === Public storefront ===
  root "pages#home"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # SEO
  get "/sitemap.xml",              to: "sitemap#index",                 format: :xml
  get "/killeen-furniture-store",             to: "pages#killeen_furniture_store",      as: :killeen_furniture_store
  get "/ashley-furniture-killeen",            to: "pages#ashley_furniture_killeen",     as: :ashley_furniture_killeen
  get "/furniture-store-harker-heights-tx",   to: "pages#harker_heights_furniture",     as: :harker_heights_furniture
  get "/furniture-store-copperas-cove-tx",    to: "pages#copperas_cove_furniture",      as: :copperas_cove_furniture
  get "/affordable-furniture-killeen-tx",     to: "pages#affordable_furniture",         as: :affordable_furniture
  get "/contact",                             to: "pages#contact",                      as: :contact
  get "/financing",                           to: "pages#financing",                    as: :financing
  get "/privacy",                             to: "pages#privacy",                      as: :privacy
  get "/terms",                               to: "pages#terms",                        as: :terms

  # Authentication
  devise_for :users, controllers: {
    registrations:       "users/registrations",
    sessions:            "users/sessions",
    confirmations:       "users/confirmations",
    omniauth_callbacks:  "users/omniauth_callbacks"
  }

  # Address autocomplete (Nominatim proxy — accessible to all visitors)
  get "address_suggestions", to: "address_suggestions#index", as: :address_suggestions

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

  # === Super Admin panel ===
  namespace :super_admin do
    resources :ashley_syncs, only: [:new, :create]
    resources :employees,    only: [:index, :update]
  end

  # === Admin panel ===
  namespace :admin do
    root "dashboard#index", as: :dashboard

    get "analytics",          to: "analytics#index",          as: :analytics
    get "address_suggestions", to: "address_suggestions#index", as: :address_suggestions

    resources :products do
      member do
        patch :update_stock
        patch :toggle_featured
        patch :publish
        patch :archive
        patch :update_price
        patch :move
      end
      collection do
        post :import_screenshot
        post :scrape_vendor
        post :ashley_lookup
      end
      resources :stock_adjustments, only: [:create]
    end

    resources :categories
    resources :delivery_zones
    resources :orders do
      member do
        patch :update_status
        patch :update_customer
        patch :update_address
        patch :assign_delivery
        post  :resend_confirmation
        get   :print_receipt
      end
      collection do
        post :calculate_shipping
      end
    end

    resources :customers,    only: [ :index, :edit, :update, :destroy ] do
      collection do
        delete :purge_unconfirmed
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
