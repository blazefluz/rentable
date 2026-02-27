Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # API Routes
  namespace :api do
    namespace :v1 do
      # Company Management (Public)
      post 'companies/signup', to: 'companies#signup'
      post 'companies', to: 'companies#create'
      get 'companies/check_subdomain', to: 'companies#check_subdomain'

      # Company Management (Authenticated)
      get 'companies/current', to: 'companies#show'
      patch 'companies/current', to: 'companies#update'
      get 'companies/settings', to: 'companies#settings'
      patch 'companies/branding', to: 'companies#branding'

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
          # Stock management for sale items
          post :increment_stock
          post :decrement_stock
          post :restock
        end
        collection do
          get 'search_by_barcode/:barcode', to: 'products#search_by_barcode', as: :search_by_barcode
        end
        # Nested insurance certificates
        resources :insurance_certificates, only: [:index, :show, :create, :update, :destroy]
        # Nested product instances
        resources :instances, controller: 'product_instances', only: [:index, :create]
        # Nested product variants
        resources :variants, controller: 'product_variants', only: [:index, :create] do
          collection do
            post :bulk_create
            post :preview
          end
        end
      end

      # Product Instances (standalone access)
      resources :product_instances, only: [:index, :show, :update, :destroy]

      # Product Variants (standalone access)
      resources :variants, controller: 'product_variants', only: [:show, :update, :destroy] do
        member do
          post :adjust_stock
          post :reserve
          post :release
          post :restock
          post :damage
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
            # Delivery tracking endpoints
            post :schedule_delivery
            patch :advance_delivery
            patch :mark_ready
            patch :mark_out_for_delivery
            post :complete_delivery
            post :fail_delivery
            delete :cancel_delivery
            post :capture_signature
            get :delivery_cost
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
        # Nested CRM resources
        resources :contacts, only: [:index, :create]
        resources :communications, controller: 'client_communications', only: [:index, :create]
      end

      # CRM Resources (standalone)
      resources :contacts, only: [:show, :update, :destroy]
      resources :client_communications, only: [:show, :update, :destroy]
      resources :leads do
        member do
          post :convert
          post :mark_lost
        end
      end
      resources :client_tags

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

      # Deliveries (standalone access for reports and filtering)
      resources :deliveries, only: [:index] do
        collection do
          get :scheduled
          get :late
        end
      end

      # Contracts & Digital Signatures
      resources :contracts do
        member do
          post :sign
          post :request_signature
          get :generate_pdf
          post :void
          post :send_reminders
        end
        collection do
          get :templates
        end
      end

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

      # Pricing Rules
      resources :pricing_rules

      # Product Bundles
      resources :product_bundles do
        collection do
          get :check_requirements
          get :suggestions
        end
      end

      # Product Collections/Categorization
      resources :product_collections do
        member do
          post :add_product
          delete :remove_product
          patch :reorder
          get :analytics
          post :refresh
        end
        collection do
          get :featured
        end
      end

      # Tax Rates
      resources :tax_rates do
        collection do
          get :for_location
        end
        member do
          post :calculate
        end
      end

      # QR Code Generation
      get 'qr_codes/generate', to: 'qr_codes#generate', as: :qr_code_generate
      get 'qr_codes/product/:id', to: 'qr_codes#product', as: :qr_code_product
      get 'qr_codes/product_instance/:id', to: 'qr_codes#product_instance', as: :qr_code_product_instance
      get 'qr_codes/location/:id', to: 'qr_codes#location', as: :qr_code_location
      get 'qr_codes/booking/:id', to: 'qr_codes#booking', as: :qr_code_booking

      # AR Reports
      namespace :ar_reports do
        get 'aging', to: 'ar_reports#aging'
        get 'summary', to: 'ar_reports#summary'
        get 'by_client', to: 'ar_reports#by_client'
        get 'overdue_list', to: 'ar_reports#overdue_list'
      end

      # Public Catalog (no authentication required)
      get 'catalog', to: 'catalog#index'
      get 'catalog/featured', to: 'catalog#featured'
      get 'catalog/popular', to: 'catalog#popular'
      get 'catalog/search', to: 'catalog#search'
      get 'catalog/recommendations/:product_id', to: 'catalog#recommendations', as: :catalog_recommendations
    end
  end

  # Root - API documentation
  root to: proc { [200, {}, ["Rentable API - Visit /api/v1/products, /api/v1/kits, /api/v1/bookings"]] }
end
