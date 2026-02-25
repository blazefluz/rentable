Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # API Routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post 'auth/register', to: 'auth#register'
      post 'auth/login', to: 'auth#login'
      get 'auth/me', to: 'auth#me'
      post 'auth/refresh', to: 'auth#refresh'

      # Products
      resources :products do
        member do
          get :availability
          post :attach_images
          delete 'remove_image/:image_id', to: 'products#remove_image', as: :remove_image
          post :transfer
          patch :archive
          patch :unarchive
        end
        collection do
          get 'search_by_barcode/:barcode', to: 'products#search_by_barcode', as: :search_by_barcode
        end
      end

      # Kits
      resources :kits do
        member do
          get :availability
          post :attach_images
          delete 'remove_image/:image_id', to: 'kits#remove_image', as: :remove_image
        end
      end

      # Bookings
      resources :bookings do
        member do
          patch :confirm
          patch :cancel
          patch :complete
          patch :archive
          patch :unarchive
          patch :extend
        end
        collection do
          get :check_availability
        end
        # Nested payments resource
        resources :payments, only: [:index, :create, :destroy]

        # Nested line items resource for workflow management
        resources :line_items, controller: 'booking_line_items', only: [:update, :destroy] do
          member do
            post :advance_workflow
            patch :set_workflow
          end
        end

        # Nested comments resource
        resources :comments, controller: 'booking_comments', only: [:index, :create, :destroy]

        # Nested attachments resource
        resources :attachments, controller: 'booking_attachments', only: [:index, :create, :destroy]

        # Invoice endpoints
        resource :invoice, only: [:show], controller: 'invoices' do
          get :download
          get :preview
          post :email
          post :generate
        end
      end

      # Clients/Customers
      resources :clients do
        member do
          patch :archive
          patch :unarchive
        end
        # Nested attachments resource
        resources :attachments, controller: 'client_attachments', only: [:index, :create, :destroy]
      end

      # Locations (storage & venues)
      resources :locations do
        collection do
          get 'search_by_barcode/:barcode', to: 'locations#search_by_barcode', as: :search_by_barcode
        end
        member do
          patch :archive
          patch :unarchive
        end
      end

      # Manufacturers
      resources :manufacturers

      # Product Types (templates/SKUs)
      resources :product_types

      # Payments (standalone access)
      resources :payments, only: [:index, :show, :update]

      # Payments (Stripe)
      namespace :payments do
        post 'stripe/create_intent', to: 'stripe#create_intent'
        post 'stripe/confirm_payment', to: 'stripe#confirm_payment'
        get 'stripe/payment_status/:payment_intent_id', to: 'stripe#payment_status', as: :stripe_payment_status
        post 'stripe/refund', to: 'stripe#refund'
        post 'stripe/webhook', to: 'stripe#webhook'
      end

      # Analytics & Reports
      get 'analytics/dashboard', to: 'analytics#dashboard'
      get 'analytics/revenue', to: 'analytics#revenue'
      get 'analytics/top_products', to: 'analytics#top_products'
      get 'analytics/utilization', to: 'analytics#utilization'
      get 'analytics/low_stock', to: 'analytics#low_stock'
      get 'analytics/clients', to: 'analytics#clients'
      get 'analytics/booking_trends', to: 'analytics#booking_trends'

      # Audit Trail
      get 'audit_trail', to: 'audit_trail#index'
      get 'audit_trail/stats', to: 'audit_trail#stats'
      get 'audit_trail/:model/:id', to: 'audit_trail#show'
      post 'audit_trail/:model/:id/revert/:version_id', to: 'audit_trail#revert'

      # Calendar & Availability
      get 'calendar/month', to: 'calendar#month'
      get 'calendar/week', to: 'calendar#week'
      get 'calendar/product_availability', to: 'calendar#product_availability'
      get 'calendar/timeline', to: 'calendar#timeline'

      # Waitlist
      resources :waitlist_entries do
        member do
          patch :notify
          patch :fulfill
        end
        collection do
          get :check_fulfillable
        end
      end

      # Maintenance Jobs
      resources :maintenance_jobs

      # Asset Assignments
      resources :asset_assignments do
        member do
          patch :return_asset
        end
      end

      # Asset Flags
      resources :asset_flags

      # Asset Groups
      resources :asset_groups do
        member do
          post 'add_product/:product_id', to: 'asset_groups#add_product', as: :add_product
          delete 'remove_product/:product_id', to: 'asset_groups#remove_product', as: :remove_product
        end
      end

      # Asset Logs
      resources :asset_logs, only: [:index, :show, :create]

      # Project Types
      resources :project_types

      # Staffing
      resources :staff_roles
      resources :staff_applications do
        member do
          patch :approve
          patch :reject
        end
      end
      resources :staff_assignments

      # Notes
      resources :notes do
        member do
          patch :pin
          patch :unpin
        end
      end

      # Business Entities
      resources :business_entities

      # Addresses
      resources :addresses

      # Sales Tasks
      resources :sales_tasks do
        member do
          patch :complete
        end
        collection do
          get :overdue
        end
      end
    end
  end

  # Root - API documentation
  root to: proc { [200, {}, ["Rentable API - Visit /api/v1/products, /api/v1/kits, /api/v1/bookings"]] }
end
